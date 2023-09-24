//
//  FitnessMachineStatusTests.swift
//  
//
//  Created by Antonio Yip on 24/9/2023.
//

import XCTest
@testable import BluetoothThing

final class FitnessMachineStatusTests: XCTestCase {
    
    var sut: FitnessMachineStatus!
    
    override func setUpWithError() throws {
        sut = FitnessMachineStatus()
    }

    override func tearDownWithError() throws {
    }

    func testUpdate() throws {
        // MINOURA DD 847D
        // 0x120000C2012122
        // 0x1200005E012122
        // 0x12000058020000
        
        let data = Data(hexString: "1200005E012122")
        
        sut.update(data)
        
        XCTAssertEqual(sut.indoorBikeSimulation.windSpeed.measurement.value, 0.0)
        XCTAssertEqual(sut.indoorBikeSimulation.grade.measurement.value, 3.5)
        XCTAssertEqual(sut.indoorBikeSimulation.rollingResistanceCoefficient.measurement.value, 0.0033)
        XCTAssertEqual(sut.indoorBikeSimulation.windResistanceCoefficient.measurement.value, 0.34)
    }
}
