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
    public internal (set) var peripheral: CBPeripheral?

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
    
    public internal (set) var register: (() -> Bool)?
    public internal (set) var deregister: (() -> Bool)?
    public internal (set) var request: ((BTRequest) -> Bool)?
    
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
