//
//  Subscription.swift
//  BluetoothThing
//
//  Created by Antonio Yip on 11/01/20.
//  Copyright © 2020 Antonio Yip. All rights reserved.
//

import Foundation
import CoreBluetooth

//public typealias ServiceUUID = CBUUID
//public typealias CharateristicUUID = CBUUID

public struct Subscription: Hashable, Codable {
    public private (set) var service: String
    public private (set) var characteristic: String
    
    public var serviceUUID: CBUUID { CBUUID(string: service) }
    public var characteristicUUID: CBUUID { CBUUID(string: characteristic) }
    
    public init(service: String, characteristic: String) {
        self.service = service
        self.characteristic = characteristic
    }
    
    public init(serviceUUID: CBUUID, characteristicUUID: CBUUID) {
        self.service = serviceUUID.uuidString
        self.characteristic = characteristicUUID.uuidString
    }
    
    init(characteristic: CBCharacteristic) {
        self.init(serviceUUID: characteristic.service.uuid,
                  characteristicUUID: characteristic.uuid)
    }
}
