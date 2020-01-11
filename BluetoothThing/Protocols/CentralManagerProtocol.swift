//
//  CentralManagerProtocol.swift
//  BluetoothThing
//
//  Created by Antonio Yip on 11/01/20.
//  Copyright © 2020 Antonio Yip. All rights reserved.
//

import Foundation
import CoreBluetooth

public protocol CentralManagerProtocol {
    var state: CBManagerState { get }
    func scanForPeripherals(withServices serviceUUIDs: [CBUUID]?, options: [String : Any]?)
    func stopScan()
    func connect(_ peripheral: CBPeripheral, options: [String : Any]?)
}

extension CBCentralManager: CentralManagerProtocol {
    
}
