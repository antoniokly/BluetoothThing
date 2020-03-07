//
//  CoreDataStoreTests.swift
//  BluetoothThingTests
//
//  Created by Antonio Yip on 3/03/20.
//  Copyright © 2020 Antonio Yip. All rights reserved.
//

import XCTest
import CoreData
@testable import BluetoothThing

class CoreDataStoreTests: XCTestCase {

    var sut: CoreDataStore!

    override func setUp() {
        sut = CoreDataStore(centralId: UUID())
        sut.reset()
    }

    override func tearDown() {
        sut.reset()
    }

    func testFetch() {
        var things = sut.fetch() as? [BluetoothThing]
        XCTAssertEqual(things?.count, 0)
        
        let thing = BluetoothThing(id: UUID(), serialNumber: Data())
        
        sut.addObject(context: nil, object: thing)
        
        things = sut.fetch() as? [BluetoothThing]
        XCTAssertEqual(things?.count, 1)
        
        // When centralId changed
        sut.centralId = UUID()
        things = sut.fetch() as? [BluetoothThing]
        XCTAssertEqual(things?.count, 0)
    }
    
    func testAdd() {
        let serialNumber = Data()
        let thing = BluetoothThing(id: UUID(), serialNumber: serialNumber)
        
        sut.addObject(context: nil, object: nil)
        var things = sut.fetch() as? [BluetoothThing]
        XCTAssertEqual(things?.count, 0, "adding nothing")

        sut.addObject(context: nil, object: thing)
        things = sut.fetch() as? [BluetoothThing]
        XCTAssertEqual(things?.count, 1)
        
        let thing1 = BluetoothThing(id: UUID(), serialNumber: serialNumber)
        sut.addObject(context: nil, object: thing1)
        things = sut.fetch() as? [BluetoothThing]
        XCTAssertEqual(things?.count, 1, "adding thing with same hardware ID has no effect")
    }

    func testRemove() {
        let thing = BluetoothThing(id: UUID(), serialNumber: Data())

        sut.removeObject(context: nil, object: thing)
        XCTAssertEqual(sut.persistentContainer.viewContext.deletedObjects.count, 0)
        
        sut.addObject(context: nil, object: thing)
        
        sut.removeObject(context: nil, object: nil)
        XCTAssertEqual(sut.persistentContainer.viewContext.deletedObjects.count, 0)
        
        sut.removeObject(context: nil, object: thing)
        XCTAssertEqual(sut.persistentContainer.viewContext.deletedObjects.count, 1)
        
        sut.save(context: nil)
        XCTAssertEqual(sut.persistentContainer.viewContext.deletedObjects.count, 0)
    }
    
    func testUpdateErrors() {
        let thing = BluetoothThing(id: UUID(), serialNumber: Data())

        sut.update(context: nil, object: thing, keyValues: nil)
        sut.update(context: nil, object: thing, keyValues: [String.name: "test"])

        let things = sut.fetch() as? [BluetoothThing]
        XCTAssertEqual(things?.count, 0, "object need to be add explicitly")
    }
    
    func testUpdateNoHardwareId() {
        let thing = BluetoothThing(id: UUID())
        
        sut.addObject(context: nil, object: thing)
        sut.update(context: nil, object: thing, keyValues: [String.name: "test"])
        let things = sut.fetch() as? [BluetoothThing]
        XCTAssertEqual(things?.count, 0)
        XCTAssertNil(things?.first?.name)
    }
    
    func testUpdateName() {
        let thing = BluetoothThing(id: UUID(), serialNumber: Data())
        
        sut.addObject(context: nil, object: thing)
        sut.update(context: nil, object: thing, keyValues: [String.name: "test"])
        let things = sut.fetch() as? [BluetoothThing]
        XCTAssertEqual(things?.first?.name, "test")
    }
    
    func testUpdateCustomData() {
        let thing = BluetoothThing(id: UUID(), serialNumber: Data())

        let customData = [String.displayName: Data()]
        
        sut.addObject(context: nil, object: thing)
        sut.update(context: nil, object: thing, keyValues: [String.customData: customData])
        let things = sut.fetch() as? [BluetoothThing]
        XCTAssertEqual(things?.first?.customData, customData)
   }
    
    func testUpdateCharacteristics() {
        let thing = BluetoothThing(id: UUID(), serialNumber: Data())

        var hex = Int("fff01234", radix: 16)
        let characteristics = [
            BTCharacteristic(service: "FFF0", characteristic: "FFE0"): Data(),
            .serialNumber: Data(bytes: &hex, count: MemoryLayout.size(ofValue: hex))
        ]
             
        sut.addObject(context: nil, object: thing)
        sut.update(context: nil, object: thing, keyValues: [String.characteristics: characteristics])
        let things = sut.fetch() as? [BluetoothThing]
        XCTAssertEqual(things?.first?.characteristics, characteristics)
        XCTAssertEqual(things?.first?.hardwareSerialNumber, "3412f0ff0000000000")
    }
    
    func testUpdateLocation() {
        let thing = BluetoothThing(id: UUID(), serialNumber: Data())

        let location = Location(coordinate: .init())

        sut.addObject(context: nil, object: thing)
        sut.update(context: nil, object: thing, keyValues: [String.location: location])
        let things = sut.fetch() as? [BluetoothThing]
        XCTAssertEqual(things?.first?.location, location)
    }
    
}
