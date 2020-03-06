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
    
    private var persistentStore: PersistentStoreProtocol
    private var persistentStoreQueue: DispatchQueue
    
    public init(persistentStore: PersistentStoreProtocol,
                queue: DispatchQueue = DispatchQueue(label: "persistentStoreQueue.serial.queue")) {
        self.persistentStore = persistentStore
        self.persistentStoreQueue = queue
        self.things = persistentStore.fetch() as? [BluetoothThing] ?? []
        
        NotificationCenter.default.addObserver(forName: BluetoothThing.didChange, object: nil, queue: nil) { (notification) in
            
            if let thing = notification.object as? BluetoothThing {
                self.persistentStoreQueue.async {
                    self.persistentStore.update(context: self.things,
                                                object: thing,
                                                keyValues: notification.userInfo)
                    self.persistentStore.save(context: self.things)
                }
            }
        }
    }
    
    func reset() {
        things.removeAll()
        persistentStore.reset()
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
            self.persistentStore.addObject(context: things, object: thing)
            self.persistentStore.save(context: things)
        }
    }
    
    func getThing(id: UUID) -> BluetoothThing? {
        return things.first(where: {$0.id == id})
    }
    
    @discardableResult
    func removeThing(id: UUID) -> BluetoothThing? {
        if let index = things.firstIndex(where: {$0.id == id}) {
            let thing = things.remove(at: index)
            self.persistentStore.removeObject(context: things, object: thing)
            self.persistentStore.save(context: things)
            return thing
        } else {
            return nil
        }
    }
}
