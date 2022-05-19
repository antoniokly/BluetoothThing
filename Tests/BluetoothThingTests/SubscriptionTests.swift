//
//  SubscriptionTests.swift
//  BluetoothThingTests
//
//  Created by Antonio Yip on 14/01/20.
//  Copyright © 2020 Antonio Yip. All rights reserved.
//

import XCTest
import CoreBluetooth
import Mockingbird
@testable import BluetoothThing

class SubscriptionTests: XCTestCase {

    let serviceUUID1 = CBUUID(string: "FF10")
    let serviceUUID2 = CBUUID(string: "FF20")
    let characteristicUUID1 = CBUUID(string: "FFF1")
    let characteristicUUID2 = CBUUID(string: "FFF2")
    
    var peripheral: CBPeripheral!

    override func setUp() {
        let services = [
            CBService.mock(uuid: serviceUUID1),
            CBService.mock(uuid: serviceUUID2)
        ]
        
        peripheral = CBPeripheral.mock(identifier: UUID())
        
        given(peripheral.services).willReturn(services)
        
        peripheral.services?.forEach {
            given($0.characteristics).willReturn([
                .mock(uuid: characteristicUUID1, service: $0),
                .mock(uuid: characteristicUUID2, service: $0),
            ])
        }
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
        XCTAssertEqual(subscribed.compactMap({$0.service?.uuid}),
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
        
        given(peripheral.services).willReturn(nil)
        
        let subscribed = getSubscribedCharateristics(for: peripheral,
                                                     subscriptions: subscriptions)
        
        XCTAssertEqual(subscribed.count, 0)
    }
    
    func testEmptyCharateristic() {
        let subscriptions = [
            BTSubscription(serviceUUID: serviceUUID1, characteristicUUID: characteristicUUID1)
        ]
                
        given(peripheral.services).willReturn([.mock(uuid: serviceUUID1)])
        
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
        
        given(peripheral.delegate).willReturn(nil)

        // When
        peripheral.subscribe(subscriptions: subsriptions)
        
        //Then
        verify(peripheral.setNotifyValue(true, for: any())).wasCalled(4)
        
        for service in peripheral.services ?? [] {
            for characteristic in service.characteristics ?? [] {
                XCTAssertTrue(characteristic.isNotifying)
            }
        }
        
        // When
        peripheral.unsubscribe(subscriptions: subsriptions)
        
        //Then
        verify(peripheral.setNotifyValue(false, for: any())).wasCalled(4)
        for service in peripheral.services ?? [] {
            for characteristic in service.characteristics ?? [] {
                XCTAssertFalse(characteristic.isNotifying)
            }
        }
    }
}
