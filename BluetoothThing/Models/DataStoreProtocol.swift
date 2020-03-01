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
    
    func reset()
    func getThing(id: UUID) -> BluetoothThing?
    func addThing(_ thing: BluetoothThing)
//    @discardableResult func addThing(id: UUID) -> BluetoothThing
    @discardableResult func removeThing(id: UUID) -> BluetoothThing?
}

public protocol PersistentStoreProtocol {
//    func object(forKey defaultName: String) -> Any?
//    func set(_ value: Any?, forKey defaultName: String)
//    func removeObject(forKey defaultName: String)
    func fetch() -> Any?
    func reset()
    
    @discardableResult func save(_ object: Any?) -> Bool
}
