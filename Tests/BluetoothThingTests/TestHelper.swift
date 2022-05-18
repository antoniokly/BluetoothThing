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

func initPeripherals<T: Sequence>(subscriptions: T, numberOfPeripherals: Int) -> [CBPeripheral] where T.Element == BTSubscription {
    
    let uuids = subscriptions.map { (subscription) -> (CBUUID, [CBUUID]?) in
        if let characteristicUUID = subscription.characteristicUUID {
            return (subscription.serviceUUID, [characteristicUUID])
        } else {
            return (subscription.serviceUUID, nil)
        }
    }
    
    let services = uuids.map { serviceUUID, characteristicsUUIDs -> CBService in
        let service = CBService.mock(uuid: serviceUUID)
        let characteristics = characteristicsUUIDs?.map {
            CBCharacteristic.mock(uuid: $0, service: service)
        }
        given(service.characteristics).willReturn(characteristics)
        return service
    }
    
    var peripherals: [CBPeripheral] = []
    
    for _ in 0 ..< numberOfPeripherals {
        peripherals.append(CBPeripheral.mock(identifier: UUID(),
                                            services: services))
    }
    
    return peripherals
}

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
