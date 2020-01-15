//
//  Subscription.swift
//  BluetoothThing
//
//  Created by Antonio Yip on 11/01/20.
//  Copyright © 2020 Antonio Yip. All rights reserved.
//

import Foundation
import CoreBluetooth

public typealias ServiceUUID = CBUUID
public typealias CharateristicUUID = CBUUID

public struct Subscription {
    public var serviceUUID: ServiceUUID
    public var characteristicUUID: CharateristicUUID
    
    public init(service: ServiceUUID, characteristic: CharateristicUUID) {
        self.serviceUUID = service
        self.characteristicUUID = characteristic
    }
}
