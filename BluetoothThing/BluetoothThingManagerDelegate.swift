//
//  BluetoothThingManagerDelegate.swift
//  BluetoothThing
//
//  Created by Antonio Yip on 9/01/20.
//  Copyright © 2020 Antonio Yip. All rights reserved.
//

import Foundation
import CoreBluetooth
import CoreLocation

public typealias Characteristic = CBCharacteristic

public protocol BluetoothThingManagerDelegate {
    func bluetoothThingManager(_ manager: BluetoothThingManager, didFoundThing thing: BluetoothThing, rssi: NSNumber)
    func bluetoothThingManager(_ manager: BluetoothThingManager, didFailToConnect thing: BluetoothThing, error: Error?)
    
    func bluetoothThing(_ thing: BluetoothThing, didChangeCharacteristic characteristic: Characteristic)
    func bluetoothThing(_ thing: BluetoothThing, didChangeState state: ConnectionState)
    func bluetoothThing(_ thing: BluetoothThing, didChangeRSSI rssi: NSNumber)
    func bluetoothThing(_ thing: BluetoothThing, didUpdateLocation location: Location)
}
