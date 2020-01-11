//
//  CBCentralManagerMock.swift
//  BluetoothThingTests
//
//  Created by Antonio Yip on 11/01/20.
//  Copyright © 2020 Antonio Yip. All rights reserved.
//

import Foundation
import CoreBluetooth

class CBCentralManagerMock: CBCentralManager {
    var _state: CBManagerState = .unknown
    var peripherals: [CBPeripheralMock] = []
    
    override var state: CBManagerState {
        get { return _state }
        set {
            _state = newValue
            if _state != .poweredOn {
                for p in peripherals {
                    p._state = .disconnected
                }
            }
        }
    }
    
    var stopScanCalled = false
    override func stopScan() {
        stopScanCalled = true
    }
    
    var connectCalled = 0
    var connectPeripheral: CBPeripheral?
    override func connect(_ peripheral: CBPeripheral, options: [String : Any]?) {
        connectCalled += 1
        connectPeripheral = peripheral
        if let p = peripheral as? CBPeripheralMock {
            p._state = .connected
        }
    }
    
    var scanForPeripheralsCalled = 0
    var scanForPeripheralsServiceUUIDs: [CBUUID]?
    override func scanForPeripherals(withServices serviceUUIDs: [CBUUID]?, options: [String : Any]? = nil) {
        scanForPeripheralsCalled += 1
        scanForPeripheralsServiceUUIDs = serviceUUIDs
        
        for peripheral in peripherals {
            delegate?.centralManager?(self,
                                      didDiscover: peripheral,
                                      advertisementData: [:],
                                      rssi: 100)
        }
    }
    
    init() {
        super.init(delegate: nil, queue: nil, options: nil)
    }
}
