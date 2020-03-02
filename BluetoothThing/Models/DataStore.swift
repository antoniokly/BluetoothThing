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
    
    public init(persistentStore: PersistentStoreProtocol = UserDefaults.standard) {
        self.persistentStore = persistentStore
        self.things = persistentStore.fetch() as? [BluetoothThing] ?? []
        
        NotificationCenter.default.addObserver(forName: BluetoothThing.didChange, object: nil, queue: nil) { (notification) in
            
            if let thing = notification.object as? BluetoothThing {
                self.persistentStore.update(context: self.things,
                                            object: thing,
                                            keyValues: notification.userInfo)
                self.persistentStore.save()
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
    
    @discardableResult
    func removeThing(id: UUID) -> BluetoothThing? {
        if let index = things.firstIndex(where: {$0.id == id}) {
            let thing = things.remove(at: index)
            return thing
        } else {
            return nil
        }
    }
}
