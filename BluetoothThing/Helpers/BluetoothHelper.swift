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
            if !characteristic.isNotifying {
                self.setNotifyValue(true, for: characteristic)
            }
        }
    }
    
    func unsubscribe(subscriptions: [Subscription]) {
        let characteristics = getSubscribedCharateristics(for: self,
                                                          subscriptions: subscriptions)
        for characteristic in characteristics {
            if characteristic.isNotifying {
                self.setNotifyValue(false, for: characteristic)
            }
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
    return subscriptions.contains { subscription in
        if subscription.serviceUUID != characteristic.service.uuid {
            return false
        }
        
        if subscription.characteristicUUID != nil &&
            subscription.characteristicUUID != characteristic.uuid {
            return false
        }
            
        return true
    }
}
