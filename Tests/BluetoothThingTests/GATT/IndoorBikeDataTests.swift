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
        let data = Data(hexString: "D000000000000000000000")
        
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
    }

}
