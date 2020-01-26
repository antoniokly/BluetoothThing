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
    var _state: CBManagerState = .unknown {
        didSet {
            if _state != .poweredOn {
                for peripheral in peripherals {
                    peripheral._state = .disconnected
                }
            }
        }
    }
    
    private var peripherals: [CBPeripheralMock] = []
    
    override var state: CBManagerState {
        return _state
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
        
//        delegate?.centralManager?(self, didConnect: peripheral)
    }
    
    var scanForPeripheralsCalled = 0
    var scanForPeripheralsServiceUUIDs: [CBUUID]?
    override func scanForPeripherals(withServices serviceUUIDs: [CBUUID]?, options: [String : Any]? = nil) {
        scanForPeripheralsCalled += 1
        scanForPeripheralsServiceUUIDs = serviceUUIDs
        
        for peripheral in peripherals {
            delegate?.centralManager?(self,
                                      didDiscover: peripheral,
                                      advertisementData: [CBAdvertisementDataServiceUUIDsKey: serviceUUIDs ?? []],
                                      rssi: 100)
        }
    }
    
    var cancelConnectionCalled = 0
    var cancelConnectionPeripheral: CBPeripheral?
    override func cancelPeripheralConnection(_ peripheral: CBPeripheral) {
        cancelConnectionCalled = 1
        cancelConnectionPeripheral = peripheral

        if let peripheral = peripheral as? CBPeripheralMock {
            peripheral._state = .disconnected
        }
//        delegate?.centralManager?(self, didDisconnectPeripheral: peripheral, error: nil)
    }
    
    init(peripherals: [CBPeripheralMock]) {
        super.init(delegate: nil, queue: nil, options: nil)
        self.peripherals = peripherals
    }
}
