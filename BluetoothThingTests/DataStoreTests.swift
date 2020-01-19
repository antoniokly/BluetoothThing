//
//  DataStoreTests.swift
//  BluetoothThingTests
//
//  Created by Antonio Yip on 13/01/20.
//  Copyright © 2020 Antonio Yip. All rights reserved.
//

import XCTest
import CoreBluetooth
@testable import BluetoothThing

class DataStoreTests: XCTestCase {

    var sut: DataStore!
    var userDefaults = UserDefaultsMock()
    var peripherals: [CBPeripheralMock]!
    
    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        let serviceUUID = CBUUID(string: "FFF0")
        let characteristicUUID = CBUUID(string: "FFF1")
        
        let subsriptions = [
            Subscription(service: serviceUUID,
                         characteristic: characteristicUUID)
        ]
        
        peripherals = initPeripherals(subscriptions: subsriptions, numberOfPeripherals: 3)
        
        sut = DataStore(persistentStore: userDefaults)
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        sut.reset()
    }

    func testSave() {
        for peripheral in peripherals {
            sut.addThing(id: peripheral.identifier)
        }
        
        XCTAssertEqual(sut.things.count, 3)
    }
    
    func testAddRemoveThing() {
        let uuid = UUID()
        sut.addThing(id: uuid)
        
        XCTAssertEqual(sut.things.count, 1)
        XCTAssertEqual(sut.things.last?.id, uuid)
        
        sut.addThing(id: uuid)
        XCTAssertEqual(sut.things.count, 1, "should not add duplicate")
        XCTAssertEqual(userDefaults.setValueCalled, 1)

        XCTAssertNotNil(sut.removeThing(id: uuid))
        XCTAssertEqual(sut.things.count, 0)
        XCTAssertFalse(sut.things.contains(where: {$0.id == uuid}))
        XCTAssertEqual(userDefaults.setValueCalled, 2)
        
        XCTAssertNil(sut.removeThing(id: uuid), "remove nothing")
        XCTAssertEqual(sut.things.count, 0)

        let thing = BluetoothThing(id: UUID())
        sut.addThing(thing)
        XCTAssertEqual(sut.things.count, 1)
        XCTAssertEqual(userDefaults.setValueCalled, 3)
        
        sut.addThing(BluetoothThing(id: thing.id))
        XCTAssertEqual(sut.things.count, 1, "should replace duplicate")
        XCTAssertEqual(userDefaults.setValueCalled, 4)
    }
    
    func testWillResignActiveNotification() {
        // When
        NotificationCenter.default.post(name: UIApplication.willResignActiveNotification, object: nil)
        
        // Then
        XCTAssertTrue(userDefaults.synchronizeCalled)
    }
    
    func testWillTerminateNotification() {
        // When
        NotificationCenter.default.post(name: UIApplication.willTerminateNotification, object: nil)
        
        // Then
        XCTAssertTrue(userDefaults.synchronizeCalled)
    }
}
