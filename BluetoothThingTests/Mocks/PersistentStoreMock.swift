//
//  UserDefaultsMock.swift
//  BluetoothThingTests
//
//  Created by Antonio Yip on 18/01/20.
//  Copyright © 2020 Antonio Yip. All rights reserved.
//

import Foundation
@testable import BluetoothThing

class PersistentStoreMock: PersistentStoreProtocol {
    func fetch() -> Any? {
        return nil
    }
    
    
    
    
//    func object(forKey defaultName: String) -> Any? {
//        return nil
//    }
    
//    var setValueCalled = 0
//    func set(_ value: Any?, forKey defaultName: String) {
//        setValueCalled += 1
//    }
    
//    func removeObject(forKey defaultName: String) {
//        
//    }
    
    func reset() {
        
    }
    
    var synchronizeCalled = 0
    func save(_ object: Any?) -> Bool {
        synchronizeCalled += 1
        return true
    }
}
