//
//  BluetoothThingRequest.swift
//  BluetoothThing
//
//  Created by Antonio Yip on 20/01/20.
//  Copyright © 2020 Antonio Yip. All rights reserved.
//

import Foundation
import CoreBluetooth

public struct BTCharacteristic {
    public var serviceUUID: CBUUID
    public var uuid: CBUUID
    
    public init(service: String, characteristic: String) {
        self.init(serviceUUID: CBUUID(string: service), characteristicUUID: CBUUID(string: characteristic))
    }
    
    public init(serviceUUID: CBUUID, characteristicUUID: CBUUID) {
        self.serviceUUID = serviceUUID
        self.uuid = characteristicUUID
    }
}

public struct BTRequest {
    public enum Method: String {
        case read
        case write
    }
    
    public var method: Method
    public var characteristic: BTCharacteristic
    public var value: Data?
    
    public init(method: Method, characteristic: BTCharacteristic, value: Data? = nil) {
        self.method = method
        self.characteristic = characteristic
        self.value = value
    }
}
