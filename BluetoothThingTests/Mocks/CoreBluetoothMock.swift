//
//  CoreBluetooth.swift
//  BluetoothThingTests
//
//  Created by Antonio Yip on 11/01/20.
//  Copyright © 2020 Antonio Yip. All rights reserved.
//

import Foundation
import CoreBluetooth

class CBCharacteristicMock: CBCharacteristic {
    var _uuid: CBUUID
    var _service: CBService
    var _value: Data?
    var _isNotifying = false
    
    override var uuid: CBUUID {
        return _uuid
    }
    
    override var service: CBService {
        return _service
    }
    
    override var value: Data? {
        return _value
    }
    
    override var isNotifying: Bool {
        return _isNotifying
    }
    
    init(uuid: CBUUID, service: CBServiceMock) {
        _uuid = uuid
        _service = service
    }
}

class CBServiceMock: CBService {
    var _uuid: CBUUID
    var _characteristics: [CBCharacteristic]?
    
    override var uuid: CBUUID {
        return _uuid
    }
    
    override var characteristics: [CBCharacteristic]? {
        return _characteristics
    }
    
    init(uuid: CBUUID, characteristics: [CBCharacteristic]? = nil) {
        _uuid = uuid
        _characteristics = characteristics
    }
}

class CBPeripheralMock: CBPeripheral {
    var _identifier: UUID
    var _services: [CBService]?
    var _state: CBPeripheralState = .disconnected
    
    override var identifier: UUID {
        return _identifier
    }
    
    override var services: [CBService]? {
        return _services
    }
    
    override var state: CBPeripheralState {
        return _state
    }
    
    init(identifier: UUID, services: [CBService]? = nil) {
        _identifier = identifier
        _services = services
    }
    
    var setNotifyValueCalled = 0
    var setNotifyValueEnabled: Bool?
    var setNotifyValueCharacteristic: CBCharacteristic?
    override func setNotifyValue(_ enabled: Bool, for characteristic: CBCharacteristic) {
        setNotifyValueCalled += 1
        setNotifyValueEnabled = enabled
        setNotifyValueCharacteristic = characteristic
        
        if let characteristic = characteristic as? CBCharacteristicMock {
            characteristic._isNotifying = enabled
        }
        
        delegate?.peripheral?(self, didUpdateNotificationStateFor: characteristic, error: nil)
    }
    
    var readValueCalled = 0
    var readValueCharacteristic: CBCharacteristic?
    override func readValue(for characteristic: CBCharacteristic) {
        readValueCalled += 1
        readValueCharacteristic = characteristic
    }
    
    var discoverServicesCalled = 0
    var discoverServices: [CBUUID]?
    override func discoverServices(_ serviceUUIDs: [CBUUID]?) {
        discoverServicesCalled += 1
        discoverServices = serviceUUIDs
        
        delegate?.peripheral?(self, didDiscoverServices: nil)
    }
    
    var discoverCharacteristicsCalled = 0
    var discoverCharacteristics: [CBUUID]?
    var discoverCharacteristicsService: CBService?
    override func discoverCharacteristics(_ characteristicUUIDs: [CBUUID]?, for service: CBService) {
        discoverCharacteristicsCalled += 1
        discoverCharacteristics = characteristicUUIDs
        discoverCharacteristicsService = service
        
        delegate?.peripheral?(self, didDiscoverCharacteristicsFor: service, error: nil)
    }
    
    var didReadRSSICalled = 0
    override func readRSSI() {
        didReadRSSICalled += 1
    }
}
