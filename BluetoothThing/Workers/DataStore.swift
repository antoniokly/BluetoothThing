//
//  DataStore.swift
//  BluetoothThing
//
//  Created by Antonio Yip on 9/01/20.
//  Copyright © 2020 Antonio Yip. All rights reserved.
//

import Foundation

public protocol DataStoreProtocol {
    var things: [BluetoothThing] { get }
    
    func save()
    func getStoredThings() -> [BluetoothThing]
    func getThing(id: UUID) -> BluetoothThing?
    @discardableResult func addThing(id: UUID) -> BluetoothThing
    @discardableResult func removeThing(id: UUID) -> Bool
    func reset()
}

class DataStore: DataStoreProtocol {
    
    var storeKey: String
    
    public internal (set) var things: [BluetoothThing] = []
    
    public init(storeKey: String = Bundle.main.bundleIdentifier!) {
        self.storeKey = storeKey
        self.things = getStoredThings()
    }
    
    func save() {
        if let data = try? JSONEncoder().encode(things) {
            UserDefaults.standard.set(data, forKey: storeKey)
            UserDefaults.standard.synchronize()
        }
    }
    
    func reset() {
        UserDefaults.standard.removeObject(forKey: storeKey)
        UserDefaults.standard.synchronize()
    }
    
//    func getThing(id: UUID) -> BluetoothThing? {
//        if let thing = things.first(where: {$0.id == id}) {
//            return thing
//        }
//
//        let thing = BluetoothThing(id: id)
//        things.append(thing)
//
//        return thing
//    }
    func getThing(id: UUID) -> BluetoothThing? {
        return things.first(where: {$0.id == id})
    }
    
    @discardableResult
    func addThing(id: UUID) -> BluetoothThing {
        if let thing = things.first(where: {$0.id == id}) {
            return thing
        }
            
        let newThing = BluetoothThing(id: id)
        things.append(newThing)
        return newThing
    }
    
    @discardableResult
    func removeThing(id: UUID) -> Bool {
        if let index = things.firstIndex(where: {$0.id == id}) {
            things.remove(at: index)
            return true
        }

        return false
    }
    
    func getStoredThings() -> [BluetoothThing] {
        guard
            let data = UserDefaults.standard.object(forKey: storeKey) as? Data,
            let things = try? JSONDecoder().decode([BluetoothThing].self, from: data) else {
            return []
        }
        
        return things
    }
}
