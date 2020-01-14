//
//  ConnectionStateTests.swift
//  BluetoothThingTests
//
//  Created by Antonio Yip on 13/01/20.
//  Copyright © 2020 Antonio Yip. All rights reserved.
//

import XCTest
@testable import BluetoothThing

class ConnectionStateTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

     func testConnectionStateString() {
           var state: ConnectionState
           
           state = .connected
           XCTAssertEqual(state.string, "connected")
           
           state = .disconnected
           XCTAssertEqual(state.string, "disconnected")
           
           state = .connecting
           XCTAssertEqual(state.string, "connecting")
           
           state = .disconnecting
           XCTAssertEqual(state.string, "disconnecting")
       }

}