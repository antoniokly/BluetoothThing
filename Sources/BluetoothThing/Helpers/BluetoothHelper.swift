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
    func subscribe<T: Sequence>(subscriptions: T) where T.Element == BTSubscription {
        let characteristics = getSubscribedCharateristics(for: self,
                                                          subscriptions: subscriptions)
        for characteristic in characteristics {
            if !characteristic.isNotifying {
                self.setNotifyValue(true, for: characteristic)
            }
        }
    }
    
    func unsubscribe<T: Sequence>(subscriptions: T) where T.Element == BTSubscription {
        let characteristics = getSubscribedCharateristics(for: self,
                                                          subscriptions: subscriptions)
        for characteristic in characteristics {
            if characteristic.isNotifying {
                self.setNotifyValue(false, for: characteristic)
            }
        }
    }
}

func getSubscribedCharateristics<T: Sequence>(for peripheral: CBPeripheral,
                                 subscriptions: T) -> [CBCharacteristic] where T.Element == BTSubscription {
    guard let services = peripheral.services else {
        return []
    }
    
    return services.flatMap {
        $0.characteristics ?? []
    }.filter {
        shouldSubscribe(characteristic: $0, subscriptions: subscriptions)
    }
}

func shouldSubscribe<T: Sequence>(characteristic: CBCharacteristic,
                     subscriptions: T) -> Bool where T.Element == BTSubscription {
    return subscriptions.contains { subscription in
        #if swift(<5.5)
        if subscription.serviceUUID != characteristic.service?.uuid {
            return false
        }
        #else
        if subscription.serviceUUID != characteristic.service.uuid {
            return false
        }
        #endif
        
        if subscription.characteristicUUID != nil &&
            subscription.characteristicUUID != characteristic.uuid {
            return false
        }
            
        return true
    }
}
