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
    
    var resetCalled = 0
    func reset() {
        resetCalled += 1
    }
    
    var saveCalled = 0
    func save(context: Any?)  {
        saveCalled += 1
    }
    
    var addObjectCalled = 0
    func addObject(context: Any?, object: Any?) {
        addObjectCalled += 1
    }
    
    var removeObjectCalled = 0
    func removeObject(context: Any?, object: Any?) {
        removeObjectCalled += 1
    }
    
    var updateCalled = 0
    func update(context: Any?, object: Any?, keyValues: [AnyHashable : Any]?) {
        updateCalled += 1
    }
}
