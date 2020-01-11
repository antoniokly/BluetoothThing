//
//  BluetoothHelper.swift
//  BluetoothThing
//
//  Created by Antonio Yip on 11/01/20.
//  Copyright © 2020 Antonio Yip. All rights reserved.
//

import Foundation
import CoreBluetooth

extension CBPeripheral {
    func subscribe(subscriptions: [Subscription]) {
        let characteristics = getSubscribedCharateristics(for: self,
                                                          subscriptions: subscriptions)
        for characteristic in characteristics {
            self.setNotifyValue(true, for: characteristic)
        }
    }
    
    func unsubscribe(subscriptions: [Subscription]) {
        let characteristics = getSubscribedCharateristics(for: self,
                                                          subscriptions: subscriptions)
        for characteristic in characteristics {
            self.setNotifyValue(false, for: characteristic)
        }
    }
}

func getSubscribedCharateristics(for peripheral: CBPeripheral,
                                 subscriptions: [Subscription]) -> [CBCharacteristic] {
    guard let services = peripheral.services else {
        return []
    }
    
    return services.flatMap {
        $0.characteristics ?? []
    }.filter {
        shouldSubscribe(characteristic: $0, subscriptions: subscriptions)
    }
}

func shouldSubscribe(characteristic: CBCharacteristic,
                     subscriptions: [Subscription]) -> Bool {
    return subscriptions.contains {
        $0.serviceUUID == characteristic.service.uuid &&
        $0.characteristicUUID == characteristic.uuid
    }
}
