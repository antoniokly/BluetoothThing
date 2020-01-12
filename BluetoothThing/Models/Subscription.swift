//
//  Subscription.swift
//  BluetoothThing
//
//  Created by Antonio Yip on 11/01/20.
//  Copyright © 2020 Antonio Yip. All rights reserved.
//

import Foundation
import CoreBluetooth

public struct Subscription {
    public var serviceUUID: CBUUID
    public var characteristicUUID: CBUUID
    
    public init(service: CBUUID, characteristic: CBUUID) {
        self.serviceUUID = service
        self.characteristicUUID = characteristic
    }
}
