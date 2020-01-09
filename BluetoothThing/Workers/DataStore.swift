//
//  DataStore.swift
//  BluetoothThing
//
//  Created by Antonio Yip on 9/01/20.
//  Copyright © 2020 Antonio Yip. All rights reserved.
//

import Foundation

protocol DataStoreInterface {
    var things: [BluetoothThing] { get }
    func save()
    func getThing(id: UUID) -> BluetoothThing
    func removeThing(id: UUID) -> Bool
}

class DataStore: DataStoreInterface {
//    static let shared = DataStore(storeKey: Bundle.main.bundleIdentifier!)
    
    var storeKey: String
    var things: [BluetoothThing] = []
    
    init(storeKey: String) {
        self.storeKey = storeKey
        self.things = loadThings()
    }
    
    func save() {
        saveThings(things: things)
    }
    
    func getThing(id: UUID) -> BluetoothThing {
        if let thing = things.first(where: {$0.id == id}) {
            return thing
        }
        
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
    
    func saveThings(things: [BluetoothThing]) {
        let data = NSKeyedArchiver.archivedData(withRootObject: things)
        UserDefaults.standard.set(data, forKey: storeKey)
    }
    
    func loadThings() -> [BluetoothThing] {
        guard
            let data = UserDefaults.standard.object(forKey: storeKey) as? Data,
            let things = NSKeyedUnarchiver.unarchiveObject(with: data) as? [BluetoothThing] else {
            return []
        }
        
        return things
    }
}
