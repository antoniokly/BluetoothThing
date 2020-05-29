//
//  SubscriptionTests.swift
//  BluetoothThingTests
//
//  Created by Antonio Yip on 14/01/20.
//  Copyright © 2020 Antonio Yip. All rights reserved.
//

import XCTest
import CoreBluetooth
@testable import BluetoothThing

class SubscriptionTests: XCTestCase {

    let serviceUUID1 = CBUUID(string: "FF10")
    let serviceUUID2 = CBUUID(string: "FF20")
    let characteristicUUID1 = CBUUID(string: "FFF1")
    let characteristicUUID2 = CBUUID(string: "FFF2")
    
    var peripheral: CBPeripheralMock!
    
    override func setUp() {
        let services = [
            CBServiceMock(uuid: serviceUUID1),
            CBServiceMock(uuid: serviceUUID2)
        ]
        
        for service in services {
            service._characteristics = [
                CBCharacteristicMock(uuid: characteristicUUID1, service: service),
                CBCharacteristicMock(uuid: characteristicUUID2, service: service)
            ]
        }
        
        peripheral = CBPeripheralMock(identifier: UUID(), services: services)
    }

    override func tearDown() {
    }
    
    func testInit() {
        let subscription = BTSubscription(service: "FF10", characteristic: "FFF1")
        
        XCTAssertEqual(subscription.serviceUUID, serviceUUID1)
        XCTAssertEqual(subscription.characteristicUUID, characteristicUUID1)
        XCTAssertEqual(subscription.name, "FFF1")
    }
    
    func testInitBatteryService() {
        let subscription = BTSubscription(service: "180F")
        
        XCTAssertEqual(subscription.serviceUUID, CBUUID(string: "180F"))
        XCTAssertNil(subscription.characteristicUUID)
        XCTAssertEqual(subscription.name, "Battery")
    }
    
    func testNoSubscription() {
        
        let subscribed = getSubscribedCharateristics(for: peripheral,
                                                     subscriptions: [])
        
        XCTAssertEqual(subscribed.count, 0)
    }

    func testSubscribedCharateristics() {
        // Given
        let subsriptions = [
            BTSubscription(serviceUUID: serviceUUID1, characteristicUUID: characteristicUUID1),
            BTSubscription(serviceUUID: serviceUUID2, characteristicUUID: characteristicUUID2),
        ]
        
        // When
        let subscribed = getSubscribedCharateristics(for: peripheral,
                                                     subscriptions: subsriptions)
        // Then
        XCTAssertEqual(subscribed.count, 2)
        XCTAssertEqual(subscribed.map({$0.uuid}),
                       [characteristicUUID1, characteristicUUID2])
        XCTAssertEqual(subscribed.map({$0.service.uuid}),
                       [serviceUUID1, serviceUUID2])
    }
    
    func testSubscribedAllCharateristics() {
        // Given
        let subsriptions = [
            BTSubscription(serviceUUID: serviceUUID1),
        ]
        
        // When
        let subscribed = getSubscribedCharateristics(for: peripheral,
                                                     subscriptions: subsriptions)
        
        // Then
        XCTAssertEqual(subscribed.count, 2)
        
    }
    
    func testSubscription1() {
        let subscriptions = [
            BTSubscription(serviceUUID: serviceUUID1, characteristicUUID: characteristicUUID1)
        ]
        
        let subscribed = getSubscribedCharateristics(for: peripheral,
                                                     subscriptions: subscriptions)
        
        XCTAssertEqual(subscribed.count, 1)
    }
    
    func testEmptyService() {
        let subscriptions = [
            BTSubscription(serviceUUID: serviceUUID1, characteristicUUID: characteristicUUID1)
        ]
        
        peripheral._services = nil
        
        let subscribed = getSubscribedCharateristics(for: peripheral,
                                                     subscriptions: subscriptions)
        
        XCTAssertEqual(subscribed.count, 0)
    }
    
    func testEmptyCharateristic() {
        let subscriptions = [
            BTSubscription(serviceUUID: serviceUUID1, characteristicUUID: characteristicUUID1)
        ]
                
        peripheral._services = [CBServiceMock(uuid: serviceUUID1)]
        
        let subscribed = getSubscribedCharateristics(for: peripheral,
                                                     subscriptions: subscriptions)
        
        XCTAssertEqual(subscribed.count, 0)
    }

    func testSubscribePeripheral() {
        // Given
        let subsriptions = [
            BTSubscription(serviceUUID: serviceUUID1, characteristicUUID: characteristicUUID1),
            BTSubscription(serviceUUID: serviceUUID1, characteristicUUID: characteristicUUID2),
            BTSubscription(serviceUUID: serviceUUID2, characteristicUUID: characteristicUUID1),
            BTSubscription(serviceUUID: serviceUUID2, characteristicUUID: characteristicUUID2),
        ]
        
        // When
        peripheral.subscribe(subscriptions: subsriptions)
        
        //Then
        XCTAssertEqual(peripheral.setNotifyValueCalled, 4)
        for service in peripheral.services ?? [] {
            for characteristic in service.characteristics ?? [] {
                XCTAssertTrue(characteristic.isNotifying)
            }
        }
        
        // When
        peripheral.unsubscribe(subscriptions: subsriptions)
        
        //Then
        XCTAssertEqual(peripheral.setNotifyValueCalled, 8)
        for service in peripheral.services ?? [] {
            for characteristic in service.characteristics ?? [] {
                XCTAssertFalse(characteristic.isNotifying)
            }
        }
    }
}
