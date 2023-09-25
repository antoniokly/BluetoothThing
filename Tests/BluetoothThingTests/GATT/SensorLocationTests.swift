//
//  FitnessMachineFeatureTests.swift
//  
//
//  Created by Antonio Yip on 7/9/2023.
//

import XCTest
@testable import BluetoothThing

final class SensorLocationTests: XCTestCase {
    
    var sut: SensorLocation!

    override func setUpWithError() throws {
        sut = SensorLocation()
    }

    override func tearDownWithError() throws {
    }

    func testUpdate() throws {
        let data = Data(hexString: "00")
        
        sut.update(data)
        
        XCTAssertFalse(sut.other)
        XCTAssertFalse(sut.topOfShoe)
        XCTAssertFalse(sut.inShoe)
        XCTAssertFalse(sut.hip)
        XCTAssertFalse(sut.frontWheel)
        XCTAssertFalse(sut.leftCrank)
        XCTAssertFalse(sut.rightCrank)
        XCTAssertFalse(sut.leftPedal)
        XCTAssertFalse(sut.rightPedal)
        XCTAssertFalse(sut.frontHub)
        XCTAssertFalse(sut.rearDropout)
        XCTAssertFalse(sut.chainstay)
        XCTAssertFalse(sut.rearWheel)
        XCTAssertFalse(sut.rearHub)
        XCTAssertFalse(sut.chest)
        XCTAssertFalse(sut.spider)
        XCTAssertFalse(sut.chainRing)
    }
}
