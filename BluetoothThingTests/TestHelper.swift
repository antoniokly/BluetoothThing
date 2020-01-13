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

func initPeripherals(subscriptions: [Subscription], numberOfPeripherals: Int) -> [CBPeripheralMock] {
    let uuids = [CBUUID: [CBUUID]].init(subscriptions.map({($0.serviceUUID, [$0.characteristicUUID])}),
                                        uniquingKeysWith: {$0 + $1})
    
    let services = uuids.map { sUUID, cUUID -> CBService in
        let service = CBServiceMock(uuid: sUUID)
        let characteristics = cUUID.map {
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
