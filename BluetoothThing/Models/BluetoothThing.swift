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
    public internal (set) var state: ConnectionState = .disconnected
    public internal (set) var services: Set<BTService> = []
    public internal (set) var subscriptions: Set<Subscription> = []
    
    public var name: String? = nil {
        didSet {
            if name != oldValue {
                NotificationCenter.default.post(name: Self.didChange, object: self, userInfo: [String.name: name as Any])
            }
        }
    }
    
    public var characteristics: [BTCharacteristic: Data] = [:] {
        didSet {
            if characteristics != oldValue {
                NotificationCenter.default.post(name: Self.didChange, object: self, userInfo: [String.characteristics: characteristics])
            }
        }
    }
    
    public var customData: [String: Data] = [:] {
        didSet {
            if customData != oldValue {
                NotificationCenter.default.post(name: Self.didChange, object: self, userInfo: [String.customData: customData])
            }
        }
    }
    
    public var hardwareSerialNumber: String? {
        return characteristics[.serialNumber]?.hexEncodedString
    }
    
    var autoReconnect = false
    var disconnecting = false
    
    var timer: Timer?
    
    var _connect: ((Bool) -> Void)?
    var _disconnect: ((Bool) -> Void)?
    var _request: ((BTRequest) -> Bool)?
    var _notify: ((Bool) -> Void)?
    var _subscribe: ((Subscription) -> Void)?
    var _unsubscribe: ((Subscription) -> Void)?
    
    public func connect() {
        _connect?(false)
    }
    
    var _register: (() -> Bool)?
    /// Registered device will connect automatically whenever available
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
    
    /// Listen to changes of all subscriptions defined in BluethoothThingManager
    public func subscribe() {
        _notify?(true)
    }
    
    public func unsubscribe() {
        _notify?(false)
    }
    
    /// Listen to changes of subscriptions, but will not re-subscribe after disconnect
    public func subscribe(_ subscription: Subscription) {
        subscriptions.insert(subscription)
        _subscribe?(subscription)
    }
    
    public func unsubscribe(_ subscription: Subscription) {
        _unsubscribe?(subscription)
        subscriptions.remove(subscription)
    }
    
    // Read & write
    @discardableResult
    public func request(_ request: BTRequest) -> Bool {
        _request?(request) == true
    }
    
    @discardableResult
    public func read(_ characteristic: BTCharacteristic) -> Bool {
        request(BTRequest(method: .read, characteristic: characteristic))
    }
    
    @discardableResult
    public func write(_ characteristic: BTCharacteristic, value: Data?) -> Bool {
        request(BTRequest(method: .write, characteristic: characteristic, value: value))
    }
    
    public func hasService(_ service: BTService) -> Bool {
        return services.contains(service)
    }
            
    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case characteristics
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
