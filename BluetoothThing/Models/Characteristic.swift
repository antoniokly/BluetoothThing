//
//  Characteristic.swift
//  BluetoothThing
//
//  Created by Antonio Yip on 22/01/20.
//  Copyright © 2020 Antonio Yip. All rights reserved.
//

import Foundation
import CoreBluetooth

public struct BTCharacteristic: Hashable, Codable {
    private var service: String
    private var characteristic: String
    
    public var serviceUUID: CBUUID { CBUUID(string: service) }
    public var uuid: CBUUID { CBUUID(string: characteristic) }
    
    public init(service: String, characteristic: String) {
        self.service = service
        self.characteristic = characteristic
    }
    
    init(characteristic: CBCharacteristic) {
        self.init(service: characteristic.service.uuid.uuidString, characteristic: characteristic.uuid.uuidString)
    }
}
