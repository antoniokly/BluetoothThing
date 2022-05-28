//
//  DataStore.swift
//  BluetoothThing
//
//  Created by Antonio Yip on 9/01/20.
//  Copyright © 2020 Antonio Yip. All rights reserved.
//

import Foundation
import os.log

class DataStore: DataStoreProtocol {
    var things: [BluetoothThing]
    
    var lastUpdated: [UUID: Date] = [:]
    
    private(set) var persistentStore: PersistentStoreProtocol
    private var persistentStoreQueue: DispatchQueue
    
    public init(persistentStore: PersistentStoreProtocol,
                queue: DispatchQueue = DispatchQueue.main) {
        self.persistentStore = persistentStore
        self.persistentStoreQueue = queue
        self.things = persistentStore.fetch() as? [BluetoothThing] ?? []
        
        NotificationCenter.default.addObserver(forName: BluetoothThing.didChange, object: nil, queue: nil) { (notification) in
            guard let id = notification.object as? UUID,
                let thing = self.things.first(where: {$0.id == id}) else {
                return
            }
            
            self.updateThing(thing)
        }
    }
    
    func reset() {
        things.removeAll()
        self.persistentStoreQueue.async {
            self.persistentStore.reset()
            self.persistentStore.save(context: self.things)
        }
    }

    func addThing(_ thing: BluetoothThing) {
        if things.contains(where: {$0.id == thing.id}) {
            return
        } else {
            things.append(thing)
        }
    }
    
    func saveThing(_ thing: BluetoothThing) {
        addThing(thing)
        
        if thing.hardwareSerialNumber != nil  {
            self.persistentStoreQueue.async {
                self.persistentStore.addObject(context: self.things, object: thing)
                self.persistentStore.save(context: self.things)
            }
        }
    }
    
    func updateThing(_ thing: BluetoothThing) {
        self.persistentStoreQueue.async {
            if let date = self.lastUpdated[thing.id], date.timeIntervalSinceNow > -30 {
                return
            }
            
            self.lastUpdated[thing.id] = Date()
            os_log("saving bluetoothThing %@", log: .storage, type: .debug, thing.debugDescription)
            self.persistentStore.update(context: self.things,
                                        object: thing,
                                        keyValues: [
                                            String.name: thing.name as Any,
                                            String.characteristics: thing.characteristics,
                                            String.customData: thing.customData
                ])
            self.persistentStore.save(context: self.things)
        }
    }
    
    func getThing(id: UUID) -> BluetoothThing? {
        return things.first(where: {$0.id == id})
    }
    
    @discardableResult
    func removeThing(id: UUID) -> BluetoothThing? {
        guard let index = things.firstIndex(where: {$0.id == id}) else {
            return nil
        }
        let thing = things.remove(at: index)
        self.persistentStoreQueue.async {
            self.persistentStore.removeObject(context: self.things, object: thing)
            self.persistentStore.save(context: self.things)
        }
        return thing
    }
}
