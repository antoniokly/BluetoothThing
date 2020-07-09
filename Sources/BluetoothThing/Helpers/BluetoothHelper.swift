//
//  BluetoothHelper.swift
//  BluetoothThing
//
//  Created by Antonio Yip on 11/01/20.
//  Copyright © 2020 Antonio Yip. All rights reserved.
//

import Foundation
import CoreBluetooth

public typealias BluetoothState = CBManagerState
public extension CBManagerState {
    var description: String {
        switch self {
        case .poweredOn:
            return "poweredOn"
        case .poweredOff:
            return "poweredOff"
        case .resetting:
            return "resetting"
        case .unauthorized:
            return "unauthorized"
        case .unsupported:
            return "unsupported"
        default:
            return "unknown"
        }
    }
}

extension CBPeripheral {
    func subscribe(subscriptions: Set<BTSubscription>) {
        let characteristics = getSubscribedCharateristics(for: self,
                                                          subscriptions: subscriptions)
        for characteristic in characteristics {
            if !characteristic.isNotifying {
                self.setNotifyValue(true, for: characteristic)
            }
        }
    }
    
    func unsubscribe(subscriptions: Set<BTSubscription>) {
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
                                 subscriptions: Set<BTSubscription>) -> [CBCharacteristic] {
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
                     subscriptions: Set<BTSubscription>) -> Bool {
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
