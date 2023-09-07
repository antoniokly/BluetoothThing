//
//  CSCMeasurementTests.swift
//  
//
//  Created by Antonio Yip on 7/9/2023.
//

import XCTest
@testable import BluetoothThing

final class CSCMeasurementTests: XCTestCase {

    var sut: CSCMeasurement!

    override func setUpWithError() throws {
        sut = CSCMeasurement()
    }

    override func tearDownWithError() throws {
    }

    func testCadence() throws {
        
        sut.update(Data(hexString: "03424D0000238A3D9542AC"))
        
        XCTAssertTrue(sut.wheelRevolutionDataPresent)
        XCTAssertTrue(sut.crankRevolutionDataPresent)
        
        XCTAssertEqual(sut.cumulativeWheelRevolutions.rawValue, 19778)
        XCTAssertEqual(sut.lastWheelEventTime.rawValue, 35363)

        XCTAssertEqual(sut.cumulativeCrankRevolutions.rawValue, 38205)
        XCTAssertEqual(sut.lastCrankEventTime.rawValue, 44098)
        
                
        sut.update(Data(hexString: "03424D0000238A3E95D5B1"))
        
        XCTAssertTrue(sut.wheelRevolutionDataPresent)
        XCTAssertTrue(sut.crankRevolutionDataPresent)
        
        XCTAssertEqual(sut.cumulativeWheelRevolutions.rawValue, 19778)
        XCTAssertEqual(sut.lastWheelEventTime.rawValue, 35363)
        XCTAssertEqual(sut.lastWheelEventTime.measurement.value, 35363 / 1024)

        XCTAssertEqual(sut.cumulativeCrankRevolutions.rawValue, 38206)
        XCTAssertEqual(sut.lastCrankEventTime.rawValue, 45525)
        XCTAssertEqual(sut.lastCrankEventTime.measurement.value, 45525 / 1024)
        
        XCTAssertEqual(sut.cadence.value, 43.055360896986684)
        
        
        sut.update(Data(hexString: "03424D0000238A3F956EB6"))
        
        XCTAssertTrue(sut.wheelRevolutionDataPresent)
        XCTAssertTrue(sut.crankRevolutionDataPresent)
        
        XCTAssertEqual(sut.cumulativeWheelRevolutions.rawValue, 19778)
        XCTAssertEqual(sut.lastWheelEventTime.rawValue, 35363)
        XCTAssertEqual(sut.lastWheelEventTime.measurement.value, 35363 / 1024)

        XCTAssertEqual(sut.cumulativeCrankRevolutions.rawValue, 38207)
        XCTAssertEqual(sut.lastCrankEventTime.rawValue, 46702)
        XCTAssertEqual(sut.lastCrankEventTime.measurement.value, 46702 / 1024)
        
        XCTAssertEqual(sut.cadence.value, 52.200509770603226)
        
        
        sut.update(Data(hexString: "03424D0000238A409560BB"))
        
        XCTAssertTrue(sut.wheelRevolutionDataPresent)
        XCTAssertTrue(sut.crankRevolutionDataPresent)
        
        XCTAssertEqual(sut.cumulativeWheelRevolutions.rawValue, 19778)
        XCTAssertEqual(sut.lastWheelEventTime.rawValue, 35363)
        XCTAssertEqual(sut.lastWheelEventTime.measurement.value, 35363 / 1024)

        XCTAssertEqual(sut.cumulativeCrankRevolutions.rawValue, 38208)
        XCTAssertEqual(sut.lastCrankEventTime.rawValue, 47968)
        XCTAssertEqual(sut.lastCrankEventTime.measurement.value, 47968 / 1024)

        XCTAssertEqual(sut.cadence.value, 48.53080568720379)

    }

}
