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

func initPeripherals(subscriptions: Set<BTSubscription>, numberOfPeripherals: Int) -> [CBPeripheralMock] {
    
    let uuids = subscriptions.map { (subscription) -> (CBUUID, [CBUUID]?) in
        if let characteristicUUID = subscription.characteristicUUID {
            return (subscription.serviceUUID, [characteristicUUID])
        } else {
            return (subscription.serviceUUID, nil)
        }
    }
    
    let services = uuids.map { serviceUUID, characteristicsUUIDs -> CBService in
        let service = CBServiceMock(uuid: serviceUUID)
        let characteristics = characteristicsUUIDs?.map {
            CBCharacteristicMock(uuid: $0, service: service)
        }
        service._characteristics = characteristics
        return service
    }
    
    var peripherals: [CBPeripheralMock] = []
    
    for _ in 0 ..< numberOfPeripherals {
        peripherals.append(CBPeripheralMock(identifier: UUID(),
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

extension Set where Element == BTSubscription {
    static let test1: Set<BTSubscription> = .init([.fff1])
    static let test2: Set<BTSubscription> = .init([.fff1, .fff2])
}

