//
//  BluetoothThingManagerDelegate.swift
//  BluetoothThing
//
//  Created by Antonio Yip on 9/01/20.
//  Copyright © 2020 Antonio Yip. All rights reserved.
//

import Foundation
import os.log

public protocol BluetoothThingManagerDelegate {
    func bluetoothThingManager(_ manager: BluetoothThingManager, didChangeState state: BluetoothState)
    @available(*, deprecated, renamed: "bluetoothThingManager(_:didFindThing:advertisementData:rssi:)")
    func bluetoothThingManager(_ manager: BluetoothThingManager, didFindThing thing: BluetoothThing, manufacturerData: Data?, rssi: NSNumber)
    func bluetoothThingManager(_ manager: BluetoothThingManager, didFindThing thing: BluetoothThing, advertisementData: [String : Any], rssi: NSNumber)
    func bluetoothThingManager(_ manager: BluetoothThingManager, didLoseThing thing: BluetoothThing)
    func bluetoothThingManager(_ manager: BluetoothThingManager, didFailToConnect thing: BluetoothThing, error: Error?)
    func bluetoothThing(_ thing: BluetoothThing, didChangeState state: ConnectionState)
    func bluetoothThing(_ thing: BluetoothThing, didChangeRSSI rssi: NSNumber)
    func bluetoothThing(_ thing: BluetoothThing, didUpdateValue value: Data?, for characteristic: BTCharacteristic, subscription: BTSubscription?)
}

public extension BluetoothThingManagerDelegate {
    func bluetoothThingManager(_ manager: BluetoothThingManager, didFindThing thing: BluetoothThing, manufacturerData: Data?, rssi: NSNumber) {
        
    }
}
