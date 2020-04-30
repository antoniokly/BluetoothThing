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

func initBluetoothThingManager(delegate: BluetoothThingManagerDelegate,
                               subscriptions: [Subscription],
                               dataStore: DataStoreProtocol,
                               centralManager: CBCentralManagerMock) -> BluetoothThingManager {
    let manager = BluetoothThingManager(delegate: delegate,
                                        subscriptions: subscriptions,
                                        dataStore: dataStore,
                                        centralManager: centralManager)
    
    centralManager.delegate = manager
    
    return manager
}
