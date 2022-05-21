//
//  TestHelper.swift
//  BluetoothThingTests
//
//  Created by Antonio Yip on 13/01/20.
//  Copyright © 2020 Antonio Yip. All rights reserved.
//

import Foundation
import CoreBluetooth
@testable import BluetoothThing
import Mockingbird

extension CBUUID {
    static let fff0 = CBUUID(string: "FFF0")
    static let fff1 = CBUUID(string: "FFF1")
    static let fff2 = CBUUID(string: "FFF2")
}

extension BTSubscription {
    static let fff1: BTSubscription = {
        return BTSubscription(serviceUUID: .fff0, characteristicUUID: .fff1)
    }()
    
    static let fff2: BTSubscription = {        
        return BTSubscription(serviceUUID: .fff0, characteristicUUID: .fff2)
    }()
}
