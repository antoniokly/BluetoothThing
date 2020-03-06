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
    var peripherals: [CBPeripheralMock]!
    
    override func setUp() {
        let serviceUUID = CBUUID(string: "FFF0")
        let characteristicUUID = CBUUID(string: "FFF1")
        
        let subsriptions = [
            Subscription(serviceUUID: serviceUUID, characteristicUUID: characteristicUUID)
        ]
        
        peripherals = initPeripherals(subscriptions: subsriptions, numberOfPeripherals: 3)
        
        sut = DataStore(persistentStore: persistentStore, queue: DispatchQueue.main)
    }

    override func tearDown() {
        sut.reset()
    }

    func testSave() {
        for peripheral in peripherals {
            let thing = BluetoothThing(id: peripheral.identifier)
            thing.characteristics[.serialNumber] = Data()
            sut.addThing(thing)
            sut.saveThing(thing)
        }
        
        XCTAssertEqual(sut.things.count, 3)
        XCTAssertEqual(persistentStore.addObjectCalled, 3)
        XCTAssertEqual(persistentStore.updateCalled, 3)
        XCTAssertEqual(persistentStore.saveCalled, 3)
    }
    
    func testUpdate() {
          for peripheral in peripherals {
              let thing = BluetoothThing(id: peripheral.identifier)
              sut.addThing(thing)
          }
          let thing = sut.things.first!

          let expectation = XCTestExpectation(description: "save")
          NotificationCenter.default.addObserver(forName: BluetoothThing.didChange, object: nil, queue: nil) { (notification) in
              DispatchQueue.main.async {
                  expectation.fulfill()
              }
          }

          thing.name = "new name"
          wait(for: [expectation], timeout: 3)
          XCTAssertEqual(persistentStore.updateCalled, 1)
      }
    
    func testAddRemoveThing() {
        let uuid = UUID()
        let thing = BluetoothThing(id: uuid)
        thing.characteristics[.serialNumber] = Data()
        sut.addThing(thing)
        sut.saveThing(thing)
        
        XCTAssertEqual(sut.things.count, 1)
        XCTAssertEqual(sut.things.last?.id, uuid)
        
        sut.addThing(thing)
        XCTAssertEqual(sut.things.count, 1, "should not replace duplicate")
        XCTAssertEqual(persistentStore.removeObjectCalled, 0)
        XCTAssertEqual(persistentStore.addObjectCalled, 1)
        XCTAssertEqual(persistentStore.saveCalled, 1)

        XCTAssertNotNil(sut.removeThing(id: uuid))
        XCTAssertEqual(sut.things.count, 0)
        XCTAssertFalse(sut.things.contains(where: {$0.id == uuid}))
        XCTAssertEqual(persistentStore.removeObjectCalled, 1)
        XCTAssertEqual(persistentStore.saveCalled, 2)
        
        XCTAssertNil(sut.removeThing(id: uuid), "remove nothing")
        XCTAssertEqual(sut.things.count, 0)
        XCTAssertEqual(persistentStore.saveCalled, 2)
    }
    
    func testReset() {
        let uuid = UUID()
        let thing = BluetoothThing(id: uuid)
        sut.addThing(thing)
        sut.reset()
     
        XCTAssertEqual(sut.things.count, 0)
        XCTAssertEqual(persistentStore.resetCalled, 1)
    }
}
