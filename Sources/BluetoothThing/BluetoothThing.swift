//
//  BluetoothThingPeripheral.swift
//  BluetoothThing
//
//  Created by Antonio Yip on 9/01/20.
//  Copyright © 2020 Antonio Yip. All rights reserved.
//

import Foundation
import CoreBluetooth
import os.log

public class BluetoothThing: NSObject, Codable, Identifiable {
    
    static let didChange = Notification.Name("\(String(describing: self)).didChange")
    
    public private (set) var id: UUID
    public internal (set) var state: ConnectionState = .disconnected
    public internal (set) var services: Set<BTService> = []
    public internal (set) var subscriptions: Set<BTSubscription> = []
    
    public var name: String? = nil {
        didSet {
            if name != oldValue {
                NotificationCenter.default.post(name: Self.didChange, object: self.id)
            }
        }
    }
    
    public var characteristics: [BTCharacteristic: Data] = [:] {
        didSet {
            if characteristics != oldValue {
                NotificationCenter.default.post(name: Self.didChange, object: self.id)
            }
        }
    }
    
    public var customData: [String: Data] = [:] {
        didSet {
            if customData != oldValue {
                NotificationCenter.default.post(name: Self.didChange, object: self.id)
            }
        }
    }
    
    public var hardwareSerialNumber: String? {
        characteristics[.serialNumber]?.hexEncodedString
    }
    
    var pendingConnect = false
    var disconnecting = false

    var pendingRequests: [BTRequest] = []

    var timer: Timer?
    
    var _connect: (() -> Void)?
    var _disconnect: ((Bool) -> Void)?
    var _request: ((BTRequest) -> Bool)?
    var _notify: ((Bool) -> Void)?
    var _subscribe: ((BTSubscription) -> Void)?
    var _unsubscribe: ((BTSubscription) -> Void)?
    var _onConnected: (() -> Void)?
    
    @available(*, deprecated, message: "Use connect()")
    public func connect(register: Bool) {
        connect()
    }
    
    public func connect(completion: @escaping () -> Void = {}) {
        disconnecting = false
        _onConnected = completion
        guard let _connect = _connect else {
            pendingConnect = true
            os_log("pending to connect %@", self.name ?? self.id.uuidString)
            return
        }
        _connect()
    }
    
    @available(*, deprecated, message: "Connection will be restored if disconnected y the peripheral, other connection logic should be implemented by the app.")
    public func register() {
        connect()
    }
    
    @available(*, deprecated, message: "Use forget() or disconnect()")
    public func disconnect(deregister: Bool) {
        if deregister {
            forget()
        } else {
            disconnect()
        }
    }
    
    public func disconnect() {
        pendingConnect = false
        disconnecting = true
        _disconnect?(false)
    }
    
    @available(*, deprecated, renamed: "forget")
    public func deregister() {
        forget()
    }
    
    public func forget() {
        pendingConnect = false
        disconnecting = true
        _disconnect?(true)
    }
    
    /// Listen to changes of all subscriptions defined in BluethoothThingManager
    public func subscribe(_ notify: Bool = true) {
        _notify?(notify)
    }
    
    public func unsubscribe() {
        subscribe(false)
    }
    
    /// Listen to changes of subscriptions, but will not re-subscribe after disconnect
    public func subscribe(_ subscription: BTSubscription) {
        subscriptions.insert(subscription)
        _subscribe?(subscription)
    }
    
    public func unsubscribe(_ subscription: BTSubscription) {
        subscriptions.remove(subscription)
        _unsubscribe?(subscription)
    }
    
    public func subscribe(_ service: BTService) {
        subscribe(BTSubscription(service))
    }
    
    public func unsubscribe(_ service: BTService) {
        unsubscribe(BTSubscription(service))
    }

    public func subscribe(_ characteristic: BTCharacteristic) {
        subscribe(BTSubscription(characteristic))
    }
    
    public func unsubscribe(_ characteristic: BTCharacteristic) {
        unsubscribe(BTSubscription(characteristic))
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
        services.contains(service)
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
