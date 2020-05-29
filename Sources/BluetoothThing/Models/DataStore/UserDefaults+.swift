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
    
    public func save(context: Any?) {
        if let things = context as? [BluetoothThing], let data = try? JSONEncoder().encode(things) {
            set(data, forKey: Self.storeKey)
            synchronize()
        }
    }
    
    // UserDefaults can only update the whole context
    public func addObject(context: Any?, object: Any?) {
        save(context: context)
    }
    
    // UserDefaults can only update the whole context
    public func removeObject(context: Any?, object: Any?) {
        save(context: context)
    }
    
    public func update(context: Any?, object: Any?, keyValues: [AnyHashable : Any]?) {
        if let things = context as? [BluetoothThing],
            let thing = object as? BluetoothThing,
            things.contains(thing),
            let data = try? JSONEncoder().encode(things) {
            set(data, forKey: Self.storeKey)
        }
    }
}
