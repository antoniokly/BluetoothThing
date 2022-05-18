//
//  CoreBluetooth.swift
//  BluetoothThingTests
//
//  Created by Antonio Yip on 11/01/20.
//  Copyright © 2020 Antonio Yip. All rights reserved.
//

import Foundation
import CoreBluetooth
import Mockingbird

extension CBCharacteristic {
    static func mock(uuid: CBUUID, service: CBService? = nil, value: Data? = nil, isNotifying: Bool = false) -> Self {
        let mock = Mockingbird.mock(Self.self)
        given(mock.uuid).willReturn(uuid)
        given(mock.service).willReturn(service)
        given(mock.value).willReturn(value)
        given(mock.isNotifying).willReturn(isNotifying)
        return mock
    }
}

extension CBService {
    static func mock(uuid: CBUUID, characteristics: [CBCharacteristic]? = nil) -> Self {
        let mock = Mockingbird.mock(Self.self)
        given(mock.uuid).willReturn(uuid)
        given(mock.characteristics).willReturn(characteristics)
        characteristics?.forEach {
            given($0.service).willReturn(mock)
        }
        return mock
    }
}

extension CBPeripheral {
    static func mock(identifier: UUID, name: String? = nil, services: [CBService]? = nil, state: CBPeripheralState = .disconnected) -> Self {
        let mock = Mockingbird.mock(Self.self)
        given(mock.identifier).willReturn(identifier)
        given(mock.name).willReturn(name)
        given(mock.services).willReturn(services)
        mock.setState(state)
                
        given(mock.setNotifyValue(firstArg(any()), for: secondArg(any()))).will { (enabled: Bool, characteristic: CBCharacteristic) in
            given(characteristic.isNotifying).willReturn(enabled)
            mock.delegate?.peripheral?(mock, didUpdateNotificationStateFor: characteristic, error: nil)
        }
        
        given(mock.discoverServices(any())).will { (serviceUUIDs: [CBUUID]?) in
            mock.delegate?.peripheral?(mock, didDiscoverServices: nil)
        }
        
        given(mock.discoverCharacteristics(firstArg(any()), for: secondArg(any()))).will { (characteristicUUIDs: [CBUUID]?, service: CBService) in
            mock.delegate?.peripheral?(mock, didDiscoverCharacteristicsFor: service, error: nil)
        }

        return mock
    }
    
    func setState(_ state: CBPeripheralState) {
        given(self.state.rawValue).willReturn(state.rawValue)
    }
}
