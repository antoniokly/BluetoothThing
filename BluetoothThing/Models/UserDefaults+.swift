//
//  UserDefaults+.swift
//  BluetoothThing
//
//  Created by Antonio Yip on 1/03/20.
//  Copyright © 2020 Antonio Yip. All rights reserved.
//

import Foundation

extension UserDefaults: PersistentStoreProtocol {
    static let storeKey = Bundle.main.bundleIdentifier!

    public func reset() {
        removeObject(forKey: Self.storeKey)
    }
        
    public func fetch() -> Any? {
         guard
            let data = object(forKey: Self.storeKey) as? Data,
            let things = try? JSONDecoder().decode([BluetoothThing].self, from: data) else {
                return nil
        }
        
        return things
    }
    
    public func save(_ object: Any?) -> Bool {
        if let things = object as? [BluetoothThing],
            let data = try? JSONEncoder().encode(things) {
            set(data, forKey: Self.storeKey)
            synchronize()
            return true
        }
        
        return false
    }
}
