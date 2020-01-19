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
    
    var setValueCalled = 0
    func set(_ value: Any?, forKey defaultName: String) {
        setValueCalled += 1
    }
    
    func removeObject(forKey defaultName: String) {
        
    }
    
    var synchronizeCalled = false
    func synchronize() -> Bool {
        synchronizeCalled = true
        return true
    }
}
