//
//  BluetoothThingManagerDelegate.swift
//  BluetoothThing
//
//  Created by Antonio Yip on 9/01/20.
//  Copyright © 2020 Antonio Yip. All rights reserved.
//

import Foundation

public protocol BluetoothThingManagerDelegate {
    func bluetoothThingManager(_ manager: BluetoothThingManager, didFoundThings: [BluetoothThing])
    func bluetoothThing(_ thing: BluetoothThing, didChangeCharacteristic characteristic: CharacteristicProtocol)
    func bluetoothThing(_ thing: BluetoothThing, didChangeState state: ConnectionState)
    func bluetoothThing(_ thing: BluetoothThing, didChangeRSSI rssi: NSNumber?)
}
