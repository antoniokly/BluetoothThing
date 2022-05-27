//
//  CodableTests.swift
//  
//
//  Created by Antonio Yip on 27/5/2022.
//

import XCTest
import CoreBluetooth
@testable import BluetoothThing

class CodableTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testBTCharacteristic() throws {
        let characteristic = BTCharacteristic(service: BTService.cyclingSpeedAndCadenceService, characteristic: .cscMeasurement)
        
        let data = try JSONEncoder().encode(characteristic)
        let json = String(data: data, encoding: .utf8)
        XCTAssertEqual(json, "{\"serviceUUID\":\"1816\",\"uuid\":\"2A5B\"}")
        
        let data1 = json!.data(using: .utf8)!
        let characteristic1 = try JSONDecoder().decode(BTCharacteristic.self, from: data1)
        
        XCTAssertEqual(characteristic1, characteristic)
    }

    func testBTService() throws {
        let service = BTService(uuid: CBUUID(string: "FFFF"))
        
        let data = try JSONEncoder().encode(service)
        let json = String(data: data, encoding: .utf8)
        XCTAssertEqual(json, "{\"uuid\":\"FFFF\"}")
        
        let data1 = json!.data(using: .utf8)!
        let service1 = try JSONDecoder().decode(BTService.self, from: data1)
        
        XCTAssertEqual(service1, service)
    }
}
