//
//  IndoorBikeDataTests.swift
//  
//
//  Created by Antonio Yip on 7/9/2023.
//

import XCTest
@testable import BluetoothThing

final class IndoorBikeDataTests: XCTestCase {
    
    var sut: IndoorBikeData!

    override func setUpWithError() throws {
        sut = IndoorBikeData()
    }

    override func tearDownWithError() throws {
    }

    func testUpdate() throws {
        //0xD000000000000000000000
        //D0005F0836000037001200
        //D0008708F8010020001400
        let data = Data(hexString: "D0008708F8010020001400")
        
        sut.update(data)
        
        XCTAssertFalse(sut.moreData)
        XCTAssertFalse(sut.instantaneousCadencePresent)
        XCTAssertFalse(sut.averageSpeedPresent)
        XCTAssertFalse(sut.averageCandencePresent)
        XCTAssertTrue(sut.totalDistancePresent)
        XCTAssertFalse(sut.resistanceLevelPresent)
        XCTAssertTrue(sut.instantaneousPowerPresent)
        XCTAssertTrue(sut.averagePowerPresent)
        XCTAssertFalse(sut.expendedEnergyPresent)
        XCTAssertFalse(sut.heartRatePresent)
        XCTAssertFalse(sut.metabolicEquivalentPresent)
        XCTAssertFalse(sut.elapsedTimePresent)
        XCTAssertFalse(sut.remainingTimePresent)
        
        XCTAssertEqual(sut.instantaneousSpeed.measurement.value, 21.83, accuracy: 0.01)
        XCTAssertEqual(sut.instantaneousCadence.rawValue, 0)
        XCTAssertEqual(sut.averageSpeed.rawValue, 0)
        XCTAssertEqual(sut.averageCadence.rawValue, 0)
        XCTAssertEqual(sut.totalDistance.measurement.value, 504)
        XCTAssertEqual(sut.resistanceLevel.rawValue, 0)
        XCTAssertEqual(sut.instantaneousPower.measurement.value, 32)
        XCTAssertEqual(sut.averagePower.measurement.value, 20)
        XCTAssertEqual(sut.energyPerHour.rawValue, 0)
        XCTAssertEqual(sut.energyPerMinute.rawValue, 0)
        XCTAssertEqual(sut.heartRate.rawValue, 0)
        XCTAssertEqual(sut.metabolicEquivalent.rawValue, 0)
        XCTAssertEqual(sut.elapsedTime.rawValue, 0)
        XCTAssertEqual(sut.remainingTime.rawValue, 0)
    }

}
