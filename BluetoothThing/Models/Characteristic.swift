//
//  Characteristic.swift
//  BluetoothThing
//
//  Created by Antonio Yip on 9/01/20.
//  Copyright © 2020 Antonio Yip. All rights reserved.
//

import Foundation
import CoreBluetooth

public protocol CharacteristicProtocol {
    var uuid: CBUUID { get }
    var value: Data? { get }
    var serviceUUID: CBUUID { get }
}

extension CBCharacteristic: CharacteristicProtocol {
    public var serviceUUID: CBUUID {
        return service.uuid
    }
}

public class Characteristic: CharacteristicProtocol {
    public internal(set) var uuid: CBUUID
    
    public var value: Data?
    
    public internal(set) var serviceUUID: CBUUID
    
    public init(uuid: String, serviceUUID: String) {
        self.uuid = CBUUID(string: uuid)
        self.serviceUUID = CBUUID(string: serviceUUID)
    }
}
