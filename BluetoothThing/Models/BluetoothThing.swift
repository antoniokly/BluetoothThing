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

    public var name: String? = nil {
        didSet {
            if name != oldValue {
                NotificationCenter.default.post(name: Self.didChange, object: self)
            }
        }
    }
    
    public var location: Location? = nil {
        didSet {
            if location != oldValue {
                NotificationCenter.default.post(name: Self.didChange, object: self)
            }
        }
    }
    
    public var data: [BTCharacteristic: Data] = [:] {
        didSet {
            if data != oldValue {
                self.dataLastChanged = Date()
                NotificationCenter.default.post(name: Self.didChange, object: self)
            }
        }
    }
    
    public var customData: [String: Data] = [:] {
        didSet {
            if customData != oldValue {
                self.customDataLastChanged = Date()
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
    
    public private (set) var dataLastChanged: Date = Date()
    public private (set) var customDataLastChanged: Date = Date()

    public var hardwareSerialNumber: String? {
        return data[.serialNumber]?.hexEncodedString
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

    @discardableResult
    public func request(_ request: BTRequest) -> Bool {
        return _request?(request) == true
    }
        
    var timer: Timer?
    
    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case location
        case data
        case isRegistered
        case customData
    }
    
    public init(id: UUID, name: String? = nil) {
        self.id = id
        self.name = name
    }
    
    convenience init(peripheral: CBPeripheral) {
        self.init(id: peripheral.identifier, name: peripheral.name)
    }
}
