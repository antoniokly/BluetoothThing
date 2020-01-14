//
//  LocationTests.swift
//  BluetoothThingTests
//
//  Created by Antonio Yip on 13/01/20.
//  Copyright © 2020 Antonio Yip. All rights reserved.
//

import XCTest
import CoreLocation
@testable import BluetoothThing

class LocationTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testLocation() {
        let clLocation = CLLocation(latitude: 1, longitude: 2)
        let location = Location(location: clLocation)
        
        XCTAssertEqual(location.cooridinate.latitude, clLocation.coordinate.latitude)
        XCTAssertEqual(location.cooridinate.longitude, clLocation.coordinate.longitude)
    }

}
