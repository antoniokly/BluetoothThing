//
//  BluetoothThingProtocol.swift
//  BluetoothThing
//
//  Created by Antonio Yip on 9/01/20.
//  Copyright © 2020 Antonio Yip. All rights reserved.
//

import Foundation
import CoreBluetooth
import CoreLocation

let batteryServiceUUID = CBUUID(string: "180F")
let batteryLevel = CBUUID(string: "2A19")

public protocol BluetoothThingProtocol {
    var events: [AnyHashable: (Characteristic) -> Bool] { get }
    var actions: [AnyHashable: Characteristic] { get }
//    associatedtype Event
//    associatedtype Action
    
//    func didUpdateCharacteristic(_ characteristic: Characteristic) -> Event
//    func perform(action: Action) -> Characteristic?
}

extension BluetoothThingProtocol {
    func didUpdateCharacteristic(_ characteristic: Characteristic) {
        for (event, validate) in events {
            if validate(characteristic) {
                // emit event
            }
        }
    }
    
    func perform(action: AnyHashable) -> Bool {
        if let action = actions[action] {
            // write to peripharel
        }
        
        return true
    }
}

//enum BeanLockEvent {
//    case unknown(Characteristic)
//    case locked
//    case unlocked
//    case motion
//    case temperature(Int)
//    case battery(Int)
//}
//
//enum BeanLockAction {
//    case lock
//    case unlock
//    case saveGPS(CLLocationCoordinate2D, Date)
//}

class Bean: BluetoothThingProtocol {
    static let serialServiceUUID = CBUUID(string: "A495FF10-C5B1-4B44-B512-1370F02D74DE")
    static let scratchServiceUUID = CBUUID(string: "A495FF20-C5B1-4B44-B512-1370F02D74DE")
    
    static let serial = CBUUID(string: "A495FF11-C5B1-4B44-B512-1370F02D74DE")
    static let scratch1 = CBUUID(string: "A495FF21-C5B1-4B44-B512-1370F02D74DE")
    static let scratch2 = CBUUID(string: "A495FF22-C5B1-4B44-B512-1370F02D74DE")
    static let scratch3 = CBUUID(string: "A495FF23-C5B1-4B44-B512-1370F02D74DE")
    static let scratch4 = CBUUID(string: "A495FF24-C5B1-4B44-B512-1370F02D74DE")
    static let scratch5 = CBUUID(string: "A495FF25-C5B1-4B44-B512-1370F02D74DE")
    
    static let events: [AnyHashable: (Characteristic) -> Bool] = [
        Bean.serial: { return $0.uuid == Bean.serial },
        Bean.scratch1: { return $0.uuid == Bean.scratch1 },
        Bean.scratch2: { return $0.uuid == Bean.scratch2 },
        Bean.scratch3: { return $0.uuid == Bean.scratch3 },
        Bean.scratch4: { return $0.uuid == Bean.scratch4 },
        Bean.scratch5: { return $0.uuid == Bean.scratch5 },
        batteryLevel: { return $0.uuid == batteryLevel }
    ]
    
    static let actions: [AnyHashable: Characteristic] = [:]
    
    var events: [AnyHashable: (Characteristic) -> Bool] {
        return Bean.events
    }
    
    var actions: [AnyHashable: Characteristic] {
        return Bean.actions
    }
}

class BeanLock: Bean {
    override var events: [AnyHashable: (Characteristic) -> Bool] {
        return [
            "locked": { return $0.uuid == Bean.scratch1 }
        ]
    }
    
//    let events: [AnyHashable : (Characteristic) -> Bool] = [
//        "locked": { characteristic in
//
//            return true
//        }
//    ]
    
//    typealias Event = BeanLockEvent
//    typealias Action = BeanLockAction
    
//    func didUpdateCharacteristic(_ characteristic: Characteristic) -> Event {
//        switch characteristic.serviceID {
//        case batteryServiceUUID:
//            if characteristic.uuid == batteryLevel, let uint8 = characteristic.value?.uint8 {
//                return .battery(Int(uint8))
//            }
//        default:
//            break
//        }
//
//        return .unknown(characteristic)
//    }
//
//    func perform(action: Action) -> Characteristic? {
//        switch action {
//        case .lock:
//            return nil
//        case .unlock:
//            return nil
//        default:
//            break
//        }
//
//        return nil
//    }
}
