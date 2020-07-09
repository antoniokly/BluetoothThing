//
//  CoreBluetooth.swift
//  BluetoothThingTests
//
//  Created by Antonio Yip on 11/01/20.
//  Copyright © 2020 Antonio Yip. All rights reserved.
//

import Foundation
import CoreBluetooth
@testable import BluetoothThing

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
    
    init(_ characteristic: BTCharacteristic) {
        _uuid = characteristic.uuid
        _service = CBServiceMock(uuid: characteristic.serviceUUID)
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
    
    init(_ service: BTService) {
        _uuid = service.uuid
    }
}

class CBPeripheralMock: CBPeripheral {
    var _identifier: UUID
    var _name: String?
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
    
    override var name: String? {
        return _name
    }
    
    init(identifier: UUID, services: [CBService]? = nil) {
        _identifier = identifier
        _services = services
    }
    
    var setNotifyValueCalled = 0
    var setNotifyValueEnabled: Bool?
    var setNotifyValueCharacteristics: [CBCharacteristic] = []
    override func setNotifyValue(_ enabled: Bool, for characteristic: CBCharacteristic) {
        setNotifyValueCalled += 1
        setNotifyValueEnabled = enabled
        setNotifyValueCharacteristics.append(characteristic)
        
        if let characteristic = characteristic as? CBCharacteristicMock {
            characteristic._isNotifying = enabled
        }
        
        delegate?.peripheral?(self, didUpdateNotificationStateFor: characteristic, error: nil)
    }
    
    var readValueCalled = 0
    var readValueCharacteristics: [CBCharacteristic] = []
    override func readValue(for characteristic: CBCharacteristic) {
        readValueCalled += 1
        readValueCharacteristics.append(characteristic)
    }
    
    var writeValueCalled = 0
    var writeValueData: Data?
    var writeValueCharacteristic: CBCharacteristic?
    var writeValueType: CBCharacteristicWriteType?
    override func writeValue(_ data: Data, for characteristic: CBCharacteristic, type: CBCharacteristicWriteType) {
        writeValueCalled += 1
        writeValueData = data
        writeValueCharacteristic = characteristic
        writeValueType = type
    }
    
    var discoverServicesCalled = 0
    var discoverServices: [CBUUID]?
    override func discoverServices(_ serviceUUIDs: [CBUUID]?) {
        discoverServicesCalled += 1
        discoverServices = serviceUUIDs
        
        let uuids: [CBUUID]
        if let serviceUUIDs = serviceUUIDs {
            uuids = serviceUUIDs
        } else {
            uuids = [
                .fff0,
                BTService.batteryService.uuid,
                BTService.deviceInformation.uuid,
                BTService.cyclingSpeedAndCadenceService.uuid
            ]
        }
        
        self._services = uuids.map {
            CBServiceMock(uuid: $0)
        }
        
        delegate?.peripheral?(self, didDiscoverServices: nil)
    }
    
    var discoverCharacteristicsCalled = 0
    var discoverCharacteristics: Set<CBUUID> = []
    var discoverCharacteristicsService: CBService?
    override func discoverCharacteristics(_ characteristicUUIDs: [CBUUID]?, for service: CBService) {
        discoverCharacteristicsCalled += 1
        discoverCharacteristics.formUnion(characteristicUUIDs ?? [])
        discoverCharacteristicsService = service
        
        var uuids: [CBUUID] = []
        if let characteristicUUIDs = characteristicUUIDs {
            uuids = characteristicUUIDs
        } else if service.uuid == .fff0 {
            uuids = [.fff1]
        } else if service.uuid == BTService.batteryService.uuid {
            uuids = [BTCharacteristic.batteryLevel.uuid]
        } else if service.uuid == BTService.deviceInformation.uuid {
            uuids = [BTCharacteristic.serialNumber.uuid]
        } else if service.uuid == BTService.cyclingSpeedAndCadenceService.uuid {
            uuids = [
                BTCharacteristic.cscMeasurement.uuid,
                BTCharacteristic.cscFeature.uuid
            ]
        }
        
        if let service = service as? CBServiceMock {
            service._characteristics = uuids.map {
                CBCharacteristicMock(uuid: $0, service: service)
            }
        }
        
        delegate?.peripheral?(self, didDiscoverCharacteristicsFor: service, error: nil)
    }
    
    var didReadRSSICalled = 0
    override func readRSSI() {
        didReadRSSICalled += 1
    }
}
