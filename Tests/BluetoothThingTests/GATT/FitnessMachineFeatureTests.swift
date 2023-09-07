//
//  FitnessMachineFeatureTests.swift
//  
//
//  Created by Antonio Yip on 7/9/2023.
//

import XCTest
@testable import BluetoothThing

final class FitnessMachineFeatureTests: XCTestCase {
    
    var sut: FitnessMachineFeature!

    override func setUpWithError() throws {
        sut = FitnessMachineFeature()
    }

    override func tearDownWithError() throws {
    }

    func testUpdate() throws {
        // MINOURA DD 847D
        // 0b0000010001000000000000000000000000001100111000000000000000000000

        let data = Data(hexString: "044000000CE00000")
        
        sut.update(data)
        
        XCTAssertFalse(sut.averageSpeedSupported)
        XCTAssertFalse(sut.cadenceSupported)
        XCTAssertTrue(sut.totalDistanceSupported)
        XCTAssertFalse(sut.inclinationSupported)
        XCTAssertFalse(sut.elevationGainSupported)
        XCTAssertFalse(sut.paceSupported)
        XCTAssertFalse(sut.stepCountSupported)
        XCTAssertFalse(sut.resistanceLevelSupported)
        XCTAssertFalse(sut.strideCountSupported)
        XCTAssertFalse(sut.expendedEnergySupported)
        XCTAssertFalse(sut.heartRateMeasurementSupported)
        XCTAssertFalse(sut.metabolicEquivalentSupported)
        XCTAssertFalse(sut.elapsedTimeSupported)
        XCTAssertFalse(sut.remainingTimeSupported)
        XCTAssertTrue(sut.powerMeasurementSupported)
        XCTAssertFalse(sut.forceOnBeltAndPowerOutputSupported)
        XCTAssertFalse(sut.userDataRetentionSupported)
        
        XCTAssertFalse(sut.speedTargetSettingSupported)
        XCTAssertFalse(sut.inclinationTargetSettingSupported)
        XCTAssertTrue(sut.resistanceTargetSettingSupported)
        XCTAssertTrue(sut.powerTargetSettingSupported)
        XCTAssertFalse(sut.heartRateTargetSettingSupported)
        XCTAssertFalse(sut.targetedExpendedEnergyConfigurationSupported)
        XCTAssertFalse(sut.targetedStepNumberConfigurationSupported)
        XCTAssertFalse(sut.targetedStrideNumberConfigurationSupported)
        XCTAssertFalse(sut.targetedDistanceConfigurationSupported)
        XCTAssertFalse(sut.targetedTrainingTimeConfigurationSupported)
        XCTAssertFalse(sut.targetedTimeInTwoHeartRateZonesConfigurationSupported)
        XCTAssertFalse(sut.targetedTimeInThreeHeartRateZonesConfigurationSupported)
        XCTAssertFalse(sut.targetedTimeInFiveHeartRateZonesConfigurationSupported)
        XCTAssertTrue(sut.indoorBikeSimulationParametersSupported)
        XCTAssertTrue(sut.wheelCircumferenceConfigurationSupported)
        XCTAssertTrue(sut.spinDownControlSupported)
        XCTAssertFalse(sut.targetedCadenceConfigurationSupported)
    }
}
