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
    
    let services = Dictionary(grouping: subscriptions) {
        $0.serviceUUID
    }.mapValues { subscription -> [CBUUID]? in
        let characteristics = subscription.compactMap {
            $0.characteristicUUID
        }
        if characteristics.isEmpty {
            return nil
        } else {
            return characteristics
        }
    }.map { serviceUUID, characteristicsUUIDs -> CBService in
        let service = CBService.mock(uuid: serviceUUID)
        let characteristics = characteristicsUUIDs?.map {
            CBCharacteristic.mock(uuid: $0, service: service)
        }
        given(service.characteristics).willReturn(characteristics)
        return service
    }
    
    return stride(from: 0, to: numberOfPeripherals, by: 1).map { _ in
        CBPeripheral.mock(identifier: UUID(), services: services)
    }
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
