//
//  CoreBluetoothMockTests.swift
//  
//
//  Created by Antonio Yip on 18/5/2022.
//

import XCTest
import CoreBluetooth
import Mockingbird

class CoreBluetoothMockTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testPeripheralMock() {
        let id = UUID()
        let peripheral = CBPeripheral.mock(identifier: id, name: "mock")
        XCTAssertEqual(peripheral.identifier, id)
        XCTAssertEqual(peripheral.name, "mock")
        XCTAssertNil(peripheral.services)
        XCTAssertEqual(peripheral.state, .disconnected)

        given(peripheral.name).willReturn("changed")
        XCTAssertEqual(peripheral.name, "changed")
        
        let service = CBService.mock(uuid: CBUUID(string: "0000"))
        given(peripheral.services).willReturn([service])
        XCTAssertEqual(peripheral.services, [service])
        XCTAssertEqual(peripheral.services?.first?.uuid.uuidString,"0000")

        peripheral.setState(.connected)
        XCTAssertEqual(peripheral.state, .connected)
    }

    func testServiceMock() {
        let id = CBUUID(string: UUID().uuidString)
        let service = CBService.mock(uuid: id)
        XCTAssertEqual(service.uuid, id)
        XCTAssertNil(service.characteristics)
        
        let characteristic = CBCharacteristic.mock(uuid: .fff0)
        given(service.characteristics).willReturn([characteristic])
        XCTAssertEqual(service.characteristics, [characteristic])
        XCTAssertEqual(service.characteristics?.first?.uuid, .fff0)
    }
    
    func testCharacteristicMock() {
        let characteristic = CBCharacteristic.mock(uuid: .fff1)
        XCTAssertEqual(characteristic.uuid, .fff1)
        XCTAssertFalse(characteristic.isNotifying)
        XCTAssertNil(characteristic.service)
        XCTAssertNil(characteristic.value)
        
        given(characteristic.isNotifying).willReturn(true)
        XCTAssertTrue(characteristic.isNotifying)

        given(characteristic.service).willReturn(CBService.mock(uuid: .fff0))
        XCTAssertEqual(characteristic.service?.uuid, .fff0)
        
        given(characteristic.value).willReturn("test".data(using: .utf8))
        XCTAssertEqual(String(data: characteristic.value ?? Data(), encoding: .utf8), "test")
    }
}
