//
//  CyclingPowerMeasurementTests.swift
//  
//
//  Created by Antonio Yip on 22/9/2023.
//

import XCTest
@testable import BluetoothThing

final class CyclingPowerMeasurementTests: XCTestCase {
    
    var sut: CyclingPowerMeasurement!
    
    override func setUpWithError() throws {
        sut = CyclingPowerMeasurement()
    }
    
    override func tearDownWithError() throws {
    }
    
    func testUpdate() throws {
        //0x14004F009E345F060000198D
        //0x14004C000B335A060000F484
        //0x140049007731550600008F7C
        //0x14002F007F30510600009A75
        //0x14002700A32F4C0600009D6C
        let data = Data(hexString: "140049007731550600008F7C")
        
        sut.update(data)
        
        XCTAssertFalse(sut.pedalPowerBalancePresent)
        XCTAssertEqual(sut.pedalPowerBalanceReference, .unknown)
        XCTAssertTrue(sut.accumulatedTorquePresent)
        XCTAssertEqual(sut.accumulatedTorqueSource, .wheelBased)
        XCTAssertTrue(sut.wheelRevolutionDataPresent)
        XCTAssertFalse(sut.crankRevolutionDataPresent)
        XCTAssertFalse(sut.extremeForceMagnitudesPresent)
        XCTAssertFalse(sut.extremeTorqueMagnitudesPresent)
        XCTAssertFalse(sut.extremeAnglesPresent)
        XCTAssertFalse(sut.topDeadSpotAnglePresent)
        XCTAssertFalse(sut.bottomDeadSpotAnglePresent)
        XCTAssertFalse(sut.accumulatedEnergyPresent)
        XCTAssertFalse(sut.offsetCompensationIndicator)
        
        XCTAssertEqual(sut.instantaneousPower.measurement.value, 73)
        XCTAssertEqual(sut.pedalPowerBalance.rawValue, 0)
        XCTAssertEqual(sut.accumulatedTorque.measurement.value, 395.71875)
        XCTAssertEqual(sut.cumulativeWheelRevolutions.rawValue, 1621)
        XCTAssertEqual(sut.lastWheelEventTime.rawValue, 31887)
        
//        XCTAssertEqual(sut.speed(wheelCircumfrence: 2110).converted(to: .kilometersPerHour).value, 0)
        
        XCTAssertEqual(sut.cumulativeCrankRevolutions.rawValue, 0)
        XCTAssertEqual(sut.lastCrankEventTime.rawValue, 0)
        XCTAssertEqual(sut.maximumForceMagnitude.rawValue, 0)
        XCTAssertEqual(sut.minimumForceMagnitude.rawValue, 0)
        XCTAssertEqual(sut.maximumTorqueMagnitude.rawValue, 0)
        XCTAssertEqual(sut.minimumTorqueMagnitude.rawValue, 0)
        XCTAssertEqual(sut.extremeAngles.rawValue, 0)
        XCTAssertEqual(sut.topDeadSpotAngle.rawValue, 0)
        XCTAssertEqual(sut.bottomDeadSpotAngle.rawValue, 0)
        XCTAssertEqual(sut.accumulatedEnergy.rawValue, 0)
    }
}
