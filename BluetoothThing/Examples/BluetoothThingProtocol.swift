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
    var id: UUID { get }

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
            // TODO:  write to Peripheral
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
