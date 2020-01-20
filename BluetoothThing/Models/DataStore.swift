//
//  DataStore.swift
//  BluetoothThing
//
//  Created by Antonio Yip on 9/01/20.
//  Copyright © 2020 Antonio Yip. All rights reserved.
//

import Foundation
import os.log

public protocol DataStoreProtocol {
    var things: [BluetoothThing] { get }
    
    func reset()
    func getThing(id: UUID) -> BluetoothThing?
    func addThing(_ thing: BluetoothThing)
//    func saveThing(_ Thing: BluetoothThing)
    @discardableResult func addThing(id: UUID) -> BluetoothThing
    @discardableResult func removeThing(id: UUID) -> BluetoothThing?
}

public protocol PersistentStoreProtocol {
    func object(forKey defaultName: String) -> Any?
    func set(_ value: Any?, forKey defaultName: String)
    func removeObject(forKey defaultName: String)
    @discardableResult func synchronize() -> Bool
}

extension UserDefaults: PersistentStoreProtocol {
    
}

class DataStore: DataStoreProtocol {
    
    var things: [BluetoothThing] = [] {
        didSet {
            os_log("things did change %@", things.debugDescription)
            save()
        }
    }
    
    private var persistentStore: PersistentStoreProtocol
    private var storeKey: String
    
    public init(persistentStore: PersistentStoreProtocol = UserDefaults.standard,
                storeKey: String = Bundle.main.bundleIdentifier!) {
        self.persistentStore = persistentStore
        self.storeKey = storeKey
        self.things = getStoredThings()
        NotificationCenter.default.addObserver(forName: UIApplication.willResignActiveNotification, object: nil, queue: nil) { (notification) in
            self.persistentStore.synchronize()
        }
        NotificationCenter.default.addObserver(forName: UIApplication.willTerminateNotification, object: nil, queue: nil) { (notification) in
            self.persistentStore.synchronize()
        }
        NotificationCenter.default.addObserver(forName: BluetoothThing.didChange, object: nil, queue: nil) { (notification) in
            if let thing = notification.object as? BluetoothThing, self.things.contains(thing) {
                self.save()
            }
        }
    }
    
    func reset() {
        things.removeAll()
        persistentStore.removeObject(forKey: storeKey)
        persistentStore.synchronize()
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
    func addThing(id: UUID) -> BluetoothThing {
        if let thing = things.first(where: {$0.id == id}) {
            return thing
        } else {
            let newThing = BluetoothThing(id: id)
            things.append(newThing)
            return newThing
        }
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
    
    func getStoredThings() -> [BluetoothThing] {
        guard
            let data = persistentStore.object(forKey: storeKey) as? Data,
            let things = try? JSONDecoder().decode([BluetoothThing].self, from: data) else {
            return []
        }
        
        return things
    }
    
//    func saveThing(_ thing: BluetoothThing) {
//        if let index = things.firstIndex(where: {$0.id == thing.id}) {
//            things[index] = thing
//        } else {
//            things.append(thing)
//        }
//    }

    func save() {
        if let data = try? JSONEncoder().encode(things) {
            persistentStore.set(data, forKey: storeKey)
        }
    }
}
