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
@testable import BluetoothThing

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
    static func mock<T: Sequence>(subscriptions: T) -> Self where T.Element == BTSubscription {
        let services = Dictionary(grouping: subscriptions) {
            $0.serviceUUID
        }.mapValues { subscription -> [CBUUID]? in
            let characteristics = subscription.compactMap {
                $0.characteristicUUID
            }
            if characteristics.isEmpty {
                return nil
            } else {
                return characteristics
            }
        }.map { serviceUUID, characteristicsUUIDs -> CBService in
            let service = CBService.mock(uuid: serviceUUID)
            let characteristics = characteristicsUUIDs?.map {
                CBCharacteristic.mock(uuid: $0, service: service)
            }
            given(service.characteristics).willReturn(characteristics)
            return service
        }
        
        return Self.mock(identifier: UUID(), services: services)
    }
    
    static func mock(identifier: UUID, name: String? = nil, services: [CBService]? = nil, state: CBPeripheralState = .disconnected) -> Self {
        let mock = Mockingbird.mock(Self.self)
        given(mock.identifier).willReturn(identifier)
        given(mock.name).willReturn(name)
        given(mock.services).willReturn(nil)
        mock.setState(state)
                
        given(mock.setNotifyValue(firstArg(any()), for: any())).will { (enabled: Bool, characteristic: CBCharacteristic) in
            given(characteristic.isNotifying).willReturn(enabled)
            mock.delegate?.peripheral?(mock, didUpdateNotificationStateFor: characteristic, error: nil)
        }
        
        given(mock.discoverServices(any())).will { (lookFor: [CBUUID]?) in
            if let uuids = lookFor {
                given(mock.services).willReturn(uuids.map {.mock(uuid: $0)})
            } else {
                given(mock.services).willReturn((services ?? []) + [
                    .mock(uuid: .batteryService),
                    .mock(uuid: .deviceInformation),
                    .mock(uuid: .cyclingSpeedAndCadenceService),
                    .mock(uuid: .heartRateService)
                ])
            }
            
            mock.delegate?.peripheral?(mock, didDiscoverServices: nil)
        }
        
        given(mock.discoverCharacteristics(firstArg(any()), for: any())).will { (characteristicUUIDs: [CBUUID]?, service: CBService) in
            
            if let uuids = characteristicUUIDs {
                given(service.characteristics).willReturn(uuids.map {
                    .mock(uuid: $0, service: service)
                })
            } else {
                if service.uuid == .cyclingSpeedAndCadenceService {
                    given(service.characteristics).willReturn([
                        .mock(uuid: .cscFeature, service: service),
                        .mock(uuid: .cscMeasurement, service: service)
                    ])
                } else if service.uuid == .heartRateService {
                    given(service.characteristics).willReturn([
                        .mock(uuid: .heartRateMeasurement, service: service)
                    ])
                } else if service.uuid == .fff0 {
                    given(service.characteristics).willReturn([
                        .mock(uuid: .fff1, service: service),
                        .mock(uuid: .fff2, service: service)
                    ])
                }
            }
            
            mock.delegate?.peripheral?(mock, didDiscoverCharacteristicsFor: service, error: nil)
        }
        
        return mock
    }
    
    func setState(_ state: CBPeripheralState) {
        given(self.state.rawValue).willReturn(state.rawValue)
    }
    
    func getService(_ uuid: CBUUID) -> CBService? {
        services?.first { $0.uuid == uuid }
    }
    
    func getCharacteristic(_ uuid: CBUUID) -> CBCharacteristic? {
        services?.flatMap { $0.characteristics ?? [] }.first { $0.uuid == uuid }
    }
}
