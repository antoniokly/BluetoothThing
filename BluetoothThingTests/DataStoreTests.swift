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
        
        sut = DataStoreMock(peripherals: peripherals)
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        sut.reset()
    }

    func testSave() {
        XCTAssertEqual(sut.things.count, 3)
        XCTAssertEqual(sut.getStoredThings().count, 0)
        
//        sut.save()
//        XCTAssertEqual(sut.getStoredThings().count, 3)
    }



}
