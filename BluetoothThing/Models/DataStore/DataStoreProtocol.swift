//
//  DataStoreProtocol.swift
//  BluetoothThing
//
//  Created by Antonio Yip on 24/01/20.
//  Copyright © 2020 Antonio Yip. All rights reserved.
//

import Foundation

public protocol DataStoreProtocol {
    var things: [BluetoothThing] { get }
    var persistentStore: PersistentStoreProtocol { get }
    
    func reset()
    func getThing(id: UUID) -> BluetoothThing?
    func addThing(_ thing: BluetoothThing)
    func saveThing(_ thing: BluetoothThing)
    func updateThing(_ thing: BluetoothThing)
    @discardableResult func removeThing(id: UUID) -> BluetoothThing?
}

public protocol PersistentStoreProtocol {
    func fetch() -> Any?
    func reset()
    func save(context: Any?)
    func addObject(context: Any?, object: Any?)
    func removeObject(context: Any?, object: Any?)
    func update(context: Any?, object: Any?, keyValues: [AnyHashable: Any]?)
}
