//
//  CyclingPowerFeatureTests.swift
//
//
//  Created by Antonio Yip on 7/9/2023.
//

import XCTest
@testable import BluetoothThing

final class CyclingPowerFeatureTests: XCTestCase {
    
    var sut: CyclingPowerFeature!

    override func setUpWithError() throws {
        sut = CyclingPowerFeature()
    }

    override func tearDownWithError() throws {
    }

    func testUpdate() throws {
        let data = Data(hexString: "0612")
        
        sut.update(data)
        XCTAssertFalse(sut.pedalPowerBalanceSupported)
        XCTAssertTrue(sut.accumulatedTorqueSupported)
        XCTAssertTrue(sut.wheelRevolutionDataSupported)
        XCTAssertFalse(sut.crankRevolutionDataSupported)
        XCTAssertFalse(sut.extremeMagnitudesSupported)
        XCTAssertFalse(sut.extremeAnglesSupported)
        XCTAssertFalse(sut.topAndBottomDeadSpotAnglesSupported)
        XCTAssertFalse(sut.accumulatedEnergySupported)
        XCTAssertFalse(sut.offsetCompensationIndicatorSupported)
        XCTAssertTrue(sut.offsetCompensationSupported)
        XCTAssertFalse(sut.cyclingPowerMeasurementCharacteristicContentMaskingSupported)
        XCTAssertFalse(sut.multipleSensorLocationsSupported)
        XCTAssertTrue(sut.crankLengthAdjustmentSupported)
        XCTAssertFalse(sut.chainLengthAdjustmentSupported)
        XCTAssertFalse(sut.spanLengthAdjustmentSupported)
        XCTAssertFalse(sut.sensorMeasurementContext)
        XCTAssertFalse(sut.instantaneousMeasurementDirectionSupported)
        XCTAssertFalse(sut.factoryCalibrationDateSupported)
        XCTAssertFalse(sut.enhancedOffsetCompensationSupported)
        XCTAssertEqual(sut.distributeSystemSupport, 0)
    }
}
