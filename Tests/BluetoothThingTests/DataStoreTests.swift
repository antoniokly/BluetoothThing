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
    var persistentStore = PersistentStoreMock()
    var peripherals: [CBPeripheral]!
    var subscriptions: [BTSubscription] = []
    
    override func setUp() {        
        subscriptions = [.fff1]
        
        peripherals = initPeripherals(subscriptions: subscriptions, numberOfPeripherals: 3)
        
        sut = DataStore(persistentStore: persistentStore, queue: DispatchQueue.main)
    }

    override func tearDown() {
        sut.reset()
    }

    func testSave() {
        // Given
        var things: [BluetoothThing] = []
        for peripheral in peripherals {
            let thing = BluetoothThing(id: peripheral.identifier, serialNumber: Data())
            things.append(thing)
        }
        
        // When
        let expectation = XCTestExpectation(description: "save")
        NotificationCenter.default.addObserver(forName: PersistentStoreMock.didSave, object: nil, queue: nil) { (notification) in
            expectation.fulfill()
        }
        for thing in things {
            sut.addThing(thing)
            sut.saveThing(thing)
        }
        
        //Then
        wait(for: [expectation], timeout: 5)
        XCTAssertEqual(sut.things.count, 3)
        XCTAssertEqual(persistentStore.addObjectCalled, 3)
        XCTAssertEqual(persistentStore.saveCalled, 3)
    }
    
    func testUpdate() {
        // Given
        for peripheral in peripherals {
            let thing = BluetoothThing(id: peripheral.identifier, serialNumber: Data())
            sut.addThing(thing)
        }
        let thing = sut.things.first!
        
        // When
        let expectation = XCTestExpectation(description: "save")
        NotificationCenter.default.addObserver(forName: PersistentStoreMock.didSave, object: nil, queue: nil) { (notification) in
            expectation.fulfill()
        }
        thing.name = "new name"

        // Then
        wait(for: [expectation], timeout: 5)
        XCTAssertEqual(persistentStore.updateCalled, 1)
        XCTAssertEqual(persistentStore.saveCalled, 1)
    }
    
    func testAddThing() {
        // Given
        let uuid = UUID()
        let thing = BluetoothThing(id: uuid, serialNumber: Data())
        
        // When
        let expectation = XCTestExpectation(description: "save")
        NotificationCenter.default.addObserver(forName: PersistentStoreMock.didSave, object: nil, queue: nil) { (notification) in
            expectation.fulfill()
        }
        sut.addThing(thing)
        sut.saveThing(thing)
        
        // Then
        wait(for: [expectation], timeout: 5)
        XCTAssertEqual(sut.things.count, 1)
        XCTAssertEqual(sut.things.last?.id, uuid)
        XCTAssertEqual(sut.things.count, 1, "should not replace duplicate")
        XCTAssertEqual(persistentStore.addObjectCalled, 1)
        XCTAssertEqual(persistentStore.saveCalled, 1)
    }
    
    func testRemoveThing() {
        // Given
        let uuid = UUID()
        let thing = BluetoothThing(id: uuid, serialNumber: Data())
        sut.addThing(thing)
        
        // When
        sut.removeThing(id: UUID())
        // Then
        XCTAssertEqual(sut.things.count, 1, "should remove nothing")
        
        // When
        let expectation = XCTestExpectation(description: "save")
        NotificationCenter.default.addObserver(forName: PersistentStoreMock.didSave, object: nil, queue: nil) { (notification) in
            expectation.fulfill()
        }
        sut.removeThing(id: uuid)
        // Then
        wait(for: [expectation], timeout: 5)
        XCTAssertEqual(sut.things.count, 0)
        XCTAssertFalse(sut.things.contains(where: {$0.id == uuid}))
        XCTAssertEqual(persistentStore.removeObjectCalled, 1)
        XCTAssertEqual(persistentStore.saveCalled, 1)
        
        // When delete nonexsit id
        XCTAssertNil(sut.removeThing(id: UUID()))
    }
    
    func testReset() {
        // Given
        let uuid = UUID()
        let thing = BluetoothThing(id: uuid, serialNumber: Data())
        sut.addThing(thing)

        // When
        let expectation = XCTestExpectation(description: "save")
        NotificationCenter.default.addObserver(forName: PersistentStoreMock.didSave, object: nil, queue: nil) { (notification) in
            expectation.fulfill()
        }
        sut.reset()
     
        // Then
        wait(for: [expectation], timeout: 5)
        XCTAssertEqual(sut.things.count, 0)
        XCTAssertEqual(persistentStore.resetCalled, 1)
        XCTAssertEqual(persistentStore.saveCalled, 1)
    }
}
