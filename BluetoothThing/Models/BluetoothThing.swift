//
//  BluetoothThingPeripheral.swift
//  BluetoothThing
//
//  Created by Antonio Yip on 9/01/20.
//  Copyright © 2020 Antonio Yip. All rights reserved.
//

import Foundation
import CoreBluetooth


public class BluetoothThing: NSObject, Codable, Identifiable {
    
    static let didChange = Notification.Name("\(String(describing: self)).didChange")
    
    public private (set) var id: UUID
    public internal (set) var state: CBPeripheralState = .disconnected
//    public internal (set) weak var peripheral: CBPeripheral?

    public var name: String? = nil {
        didSet {
            if name != oldValue {
                NotificationCenter.default.post(name: Self.didChange, object: self)
            }
        }
    }
    
    public internal (set) var location: Location? = nil {
        didSet {
            if location != oldValue {
                NotificationCenter.default.post(name: Self.didChange, object: self)
            }
        }
    }
    
    public internal (set) var data: [BTCharacteristic: Data] = [:] {
        didSet {
            if data != oldValue {
                NotificationCenter.default.post(name: Self.didChange, object: self)
            }
        }
    }
    
    public internal (set) var isRegistered: Bool = false {
        didSet {
            if isRegistered != oldValue {
                NotificationCenter.default.post(name: Self.didChange, object: self)
            }
        }
    }
    
    var autoReconnect = false
    var disconnecting = false
    
    var _connect: ((Bool) -> Bool)?
    var _disconnect: ((Bool) -> Bool)?
    var _request: ((BTRequest) -> Bool)?
    
    public func connect() {
        _connect?(false)
    }
    
    var _register: (() -> Bool)?
    public func register() {
        _connect?(true)
    }
    
    public func disconnect() {
        _disconnect?(false)
    }
    
    var _deregister: (() -> Bool)?
    public func deregister() {
        _disconnect?(true)
    }
//    public internal (set) var disconnect: ((Bool) -> Bool)?

    @discardableResult
    public func request(_ request: BTRequest) -> Bool {
        return _request?(request) == true
    }
    
//    public internal (set) var register: (() -> Bool)?
//    public internal (set) var deregister: (() -> Bool)?
    
    var timer: Timer?
    
    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case location
        case data
        case isRegistered
    }
    
    public init(id: UUID, name: String? = nil) {
        self.id = id
        self.name = name
    }
    
    convenience init(peripheral: CBPeripheral) {
        self.init(id: peripheral.identifier, name: peripheral.name)
    }
}
