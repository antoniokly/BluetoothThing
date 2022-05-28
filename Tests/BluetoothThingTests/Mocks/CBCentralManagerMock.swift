//
//  CBCentralManagerMock.swift
//  BluetoothThingTests
//
//  Created by Antonio Yip on 11/01/20.
//  Copyright © 2020 Antonio Yip. All rights reserved.
//

import Foundation
import CoreBluetooth
import Mockingbird

class CBCentralManagerMock: CBCentralManager {
    
    private var peripherals: [CBPeripheral] = []
    
    override var state: CBManagerState {
        return _state
    }
    
    private var _state: CBManagerState = .unknown
    func setState(_ state: CBManagerState) {
        _state = state
        delegate?.centralManagerDidUpdateState(self)
        if _state != .poweredOn {
            for peripheral in peripherals {
                peripheral.setState(.disconnected)
            }
        }
    }
    
    var stopScanCalled = 0
    override func stopScan() {
        stopScanCalled += 1
    }
    
    var connectCalled = 0
    var connectPeripheral: CBPeripheral?
    override func connect(_ peripheral: CBPeripheral, options: [String : Any]?) {
        connectCalled += 1
        connectPeripheral = peripheral
        peripheral.setState(.connected)
        delegate?.centralManager?(self, didConnect: peripheral)
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
        cancelConnectionCalled += 1
        cancelConnectionPeripheral = peripheral
        peripheral.setState(.disconnected)
        delegate?.centralManager?(self, didDisconnectPeripheral: peripheral, error: nil)
    }
    
    init(peripherals: [CBPeripheral]) {
        super.init(delegate: nil, queue: nil, options: nil)
        self.peripherals = peripherals
    }
}
