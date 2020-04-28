//
//  Subscription.swift
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

public struct Subscription {
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
}
