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
    public let serviceUUID: CBUUID
    public let characteristicUUID: CBUUID?
    
    public var name: String {
        characteristicUUID?.description ?? serviceUUID.description
    }
    
    public init(service: String, characteristic: String? = nil) {
        self.serviceUUID = CBUUID(string: service)
        if let characteristic = characteristic {
            self.characteristicUUID = CBUUID(string: characteristic)
        } else {
            self.characteristicUUID = nil
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
        self.characteristicUUID = nil
    }
}

public extension BTSubscription {
    static let batteryService = BTSubscription(.batteryService)
    static let deviceInfomation = BTSubscription(.deviceInformation)
    static let serialNumber = BTSubscription(.serialNumber)
}
