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
    
    var things: [BluetoothThing] = [] {
        didSet {
            os_log("things did change %@", things.debugDescription)
            save()
        }
    }
    
    private var persistentStore: PersistentStoreProtocol
    
    public init(persistentStore: PersistentStoreProtocol = UserDefaults.standard) {
        self.persistentStore = persistentStore
        self.things = getStoredThings()
        
        NotificationCenter.default.addObserver(forName: BluetoothThing.didChange, object: nil, queue: nil) { (notification) in
            if let thing = notification.object as? BluetoothThing, self.things.contains(thing) {
                self.save()
            }
        }
    }
    
    func reset() {
        things.removeAll()
        persistentStore.reset()
    }

    func addThing(_ thing: BluetoothThing) {
        if let index = things.firstIndex(where: {$0.id == thing.id}) {
            things[index] = thing
        } else {
            things.append(thing)
        }
    }
    
    func getThing(id: UUID) -> BluetoothThing? {
        return things.first(where: {$0.id == id})
    }
    
//    @discardableResult
//    func addThing(id: UUID) -> BluetoothThing {
//        if let thing = things.first(where: {$0.id == id}) {
//            return thing
//        } else {
//            let newThing = BluetoothThing(id: id)
//            things.append(newThing)
//            return newThing
//        }
//    }
    
    @discardableResult
    func removeThing(id: UUID) -> BluetoothThing? {
        if let index = things.firstIndex(where: {$0.id == id}) {
            let thing = things.remove(at: index)
            return thing
        } else {
            return nil
        }
    }
    
    func getStoredThings() -> [BluetoothThing] {
        return persistentStore.fetch() as? [BluetoothThing] ?? []
    }

    func save() {
        persistentStore.save(things)
    }
}
