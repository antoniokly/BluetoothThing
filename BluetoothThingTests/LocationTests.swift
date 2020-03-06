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
    }

    override func tearDown() {
    }

    func testLocation() {
        let clLocation = CLLocation(latitude: 1, longitude: 2)
        let location = Location(location: clLocation)
        
        XCTAssertEqual(location.cooridinate.latitude, clLocation.coordinate.latitude)
        XCTAssertEqual(location.cooridinate.longitude, clLocation.coordinate.longitude)
    }

}
