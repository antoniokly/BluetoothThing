//
//  BTSubscription.swift
//  BluetoothThing
//
//  Created by Antonio Yip on 11/01/20.
//  Copyright © 2020 Antonio Yip. All rights reserved.
//

import Foundation
import CoreBluetooth

/*
 Find GATT UUID here:
 https://www.bluetooth.com/specifications/gatt/services/
 */

public struct BTSubscription: Hashable {
    public private (set) var serviceUUID: CBUUID
    public private (set) var characteristicUUID: CBUUID?
    
    public var name: String {
        characteristicUUID?.description ?? serviceUUID.description
    }
    
    public init(service: String, characteristic: String? = nil, name: String? = nil) {
        self.serviceUUID = CBUUID(string: service)
        if let characteristic = characteristic {
            self.characteristicUUID = CBUUID(string: characteristic)
        }
    }
    
    public init(serviceUUID: CBUUID, characteristicUUID: CBUUID? = nil) {
        self.serviceUUID = serviceUUID
        self.characteristicUUID = characteristicUUID
    }
    
    public init(_ characteristic: BTCharacteristic) {
        self.serviceUUID = characteristic.serviceUUID
        self.characteristicUUID = characteristic.uuid
    }
    
    public init(_ service: BTService) {
        self.serviceUUID = service.uuid
    }
}

public extension BTSubscription {
    static let batteryService = BTSubscription(.batteryService)
    static let deviceInfomation = BTSubscription(.deviceInformation)
}
