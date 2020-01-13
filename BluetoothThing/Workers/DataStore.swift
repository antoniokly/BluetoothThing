//
//  DataStore.swift
//  BluetoothThing
//
//  Created by Antonio Yip on 9/01/20.
//  Copyright © 2020 Antonio Yip. All rights reserved.
//

import Foundation

public protocol DataStoreInterface {
    func save()
    func getStoredThings() -> [BluetoothThing]
    func getThing(id: UUID) -> BluetoothThing?
//    func saveThing(_ thing: BluetoothThing) -> Bool
    func removeThing(id: UUID) -> Bool

}


class DataStore: DataStoreInterface {
    
    var storeKey: String
    var things: [BluetoothThing] = []
    
    init(storeKey: String = Bundle.main.bundleIdentifier!) {
        self.storeKey = storeKey
        self.things = getStoredThings()
    }
    
    func save() {
        let data = NSKeyedArchiver.archivedData(withRootObject: things)
        UserDefaults.standard.set(data, forKey: storeKey)
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
    
    func saveThing(id: UUID) -> BluetoothThing {
        let thing = BluetoothThing(id: id)
        things.append(thing)
        return thing
    }
    
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
            let things = NSKeyedUnarchiver.unarchiveObject(with: data) as? [BluetoothThing] else {
            return []
        }
        
        return things
    }
}
