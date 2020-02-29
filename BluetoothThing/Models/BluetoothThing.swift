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
    
    var peripheral: BTPeripheral?
    var hardware: BTHardware?

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
                NotificationCenter.default.post(name: Self.didChange, object: self)
            }
        }
    }
    
    public var customData: [String: Data] = [:] {
        didSet {
            if customData != oldValue {
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
    
    public var hardwareSerialNumber: String? {
        return data[.serialNumber]?.hexEncodedString
    }
    
    var autoReconnect = false
    var disconnecting = false
    
    var timer: Timer?
    
    var _connect: ((Bool) -> Void)?
    var _disconnect: ((Bool) -> Void)?
    var _request: ((BTRequest) -> Bool)?
    var _notify: ((Bool) -> Void)?
    
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
    
    public func subscribe() {
        _notify?(true)
    }
    
    public func unsubscribe() {
        _notify?(false)
    }
            
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
        
        self.peripheral =
            BTPeripheral.fetch(id: id.uuidString) ??
            BTPeripheral.create(keyValues: [
                "id": id.uuidString,
                "name": name ?? "Unknown"
            ])
    }
    
    convenience init(peripheral: CBPeripheral) {
        self.init(id: peripheral.identifier, name: peripheral.name)
    }
}
