//
//  GATTDataTests.swift
//  
//
//  Created by Antonio Yip on 6/9/2023.
//

import XCTest
@testable import BluetoothThing

final class GATTDataTests: XCTestCase {

    override func setUpWithError() throws {
    }

    override func tearDownWithError() throws {
    }

    func test16Bit() throws {
        let sut = GATTData(
            bytes: 2,
            decimalExponent: -2,
            resolution: 0.01,
            unit: UnitSpeed.kilometersPerHour
        )
        
        sut.update([])
        XCTAssertEqual(Int(sut.rawValue), 0)
        
        sut.update([0xFF])
        XCTAssertEqual(Int(sut.rawValue), 0, "not enough bytes")
        
        sut.update([0xFF, 0])
        XCTAssertEqual(Int(sut.rawValue), 0xFF)
        
        sut.update([0, 0xFF])
        XCTAssertEqual(Int(sut.rawValue), 0xFF00)

        sut.update([0xFF, 0xFF])
        XCTAssertEqual(Int(sut.rawValue), 0xFFFF)
        
        // Measurement
        XCTAssertEqual(sut.measurement.value, 655.35)
        XCTAssertEqual(sut.measurement.description, "655.35 km/h")
        XCTAssertEqual(sut.measurement.converted(to: .milesPerHour).value, 407.2159366052256)
    }
    
    func testSigned16Bit() throws {
        let sut = GATTData(
            bytes: 2,
            signed: true,
            unit: UnitPower.watts
        )
        
        sut.update([])
        XCTAssertEqual(Int(sut.rawValue), 0)
        
        sut.update([0xFF])
        XCTAssertEqual(Int(sut.rawValue), 0, "not enough bytes")
        
        XCTAssertEqual(Int16(bitPattern: 0xFFFF), -1)
        sut.update([0xFF, 0xFF])
        XCTAssertEqual(Int(sut.rawValue), -1)
        
        XCTAssertEqual(Int16(bitPattern: 0x7FFF), 32767)
        sut.update([0xFF, 0x7F])
        XCTAssertEqual(Int(sut.rawValue), 32767)
        
        XCTAssertEqual(Int16(bitPattern: 0x8001), -32767)
        XCTAssertEqual(Int16([0x01, 0x80]), -32767)
        sut.update([0x01, 0x80])
        XCTAssertEqual(Int(sut.rawValue), -32767)
        
        // Measurement
        XCTAssertEqual(sut.measurement.value, -32767)
        XCTAssertEqual(sut.measurement.description, "-32767.0 W")
        XCTAssertEqual(sut.measurement.converted(to: .kilowatts).value, -32.767)
        XCTAssertEqual(sut.measurement.converted(to: .horsepower).value, -43.94126324259085)
    }
    
    func test24Bit() throws {
        let sut = GATTData(
            bytes: 3,
            decimalExponent: -2,
            resolution: 0.01,
            unit: UnitLength.meters
        )
        
        sut.update([])
        XCTAssertEqual(Int(sut.rawValue), 0)
        
        sut.update([0xFF, 0xFF])
        XCTAssertEqual(Int(sut.rawValue), 0, "not enough bytes")
        
        sut.update([0xFF, 0, 0])
        XCTAssertEqual(Int(sut.rawValue), 0xFF)
        
        sut.update([0xFF, 0xFF, 0])
        XCTAssertEqual(Int(sut.rawValue), 0xFFFF)
        
        sut.update([0xFF, 0xFF, 0xFF])
        XCTAssertEqual(Int(sut.rawValue), 0xFFFFFF)
        
        // Measurement
//        XCTAssertEqual(sut.measurement.value, 23039453.38)
    }
    
    func test32Bit() throws {
        let sut = GATTData(
            bytes: 4,
            decimalExponent: -2,
            resolution: 0.01,
            unit: UnitLength.meters
        )
        
        sut.update([])
        XCTAssertEqual(Int(sut.rawValue), 0)
        
        sut.update([0xFF, 0xFF, 0xFF])
        XCTAssertEqual(Int(sut.rawValue), 0, "not enough bytes")
        
        sut.update([0xFF, 0, 0, 0])
        XCTAssertEqual(Int(sut.rawValue), 0xFF)
        
        sut.update([0xFF, 0xFF, 0, 0])
        XCTAssertEqual(Int(sut.rawValue), 0xFFFF)
        
        sut.update([0xFF, 0xFF, 0xFF, 0])
        XCTAssertEqual(Int(sut.rawValue), 0xFFFFFF)
        
        sut.update([0xFF, 0xFF, 0xFF, 0xFF])
        XCTAssertEqual(Int(sut.rawValue), 0xFFFFFFFF)
        
        // Measurement
        sut.update([0x7A, 0x6A, 0x53, 0x89])
        
        XCTAssertEqual(UInt32([0x7A, 0x6A, 0x53, 0x89]), 2303945338)
        XCTAssertEqual(Int(sut.rawValue), 2303945338)
        XCTAssertEqual(sut.measurement.value, 23039453.38)
        XCTAssertEqual(sut.measurement.description, "23039453.38 m")
        XCTAssertEqual(sut.measurement.converted(to: .miles).value, 14316.052615227072)
    }
}
