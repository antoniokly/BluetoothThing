//
//  UserDefaultsMock.swift
//  BluetoothThingTests
//
//  Created by Antonio Yip on 18/01/20.
//  Copyright © 2020 Antonio Yip. All rights reserved.
//

import Foundation
@testable import BluetoothThing

class UserDefaultsMock: PersistentStoreProtocol {
    func object(forKey defaultName: String) -> Any? {
        return nil
    }
    
    func set(_ value: Any?, forKey defaultName: String) {
        
    }
    
    func removeObject(forKey defaultName: String) {
        
    }
    
    var synchronizeCalled = false
    func synchronize() -> Bool {
        synchronizeCalled = true
        return true
    }
}
