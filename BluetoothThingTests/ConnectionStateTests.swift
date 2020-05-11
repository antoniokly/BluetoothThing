//
//  ConnectionStateTests.swift
//  BluetoothThingTests
//
//  Created by Antonio Yip on 13/01/20.
//  Copyright © 2020 Antonio Yip. All rights reserved.
//

import XCTest
import CoreBluetooth
@testable import BluetoothThing

class ConnectionStateTests: XCTestCase {

    override func setUp() {
    }

    override func tearDown() {
    }

    func testConnectionStateString() {
        XCTAssertEqual(ConnectionState.connected.description, "connected")
        XCTAssertEqual(ConnectionState.disconnected.description, "disconnected")
        XCTAssertEqual(ConnectionState.connecting.description, "connecting")
        XCTAssertEqual(ConnectionState.disconnecting.description, "disconnecting")
    }

    func testCentralStateString() {
        XCTAssertEqual(CBManagerState.poweredOff.description, "poweredOff")
        XCTAssertEqual(CBManagerState.poweredOn.description, "poweredOn")
        XCTAssertEqual(CBManagerState.unsupported.description, "unsupported")
        XCTAssertEqual(CBManagerState.unauthorized.description, "unauthorized")
        XCTAssertEqual(CBManagerState.unknown.description, "unknown")
        XCTAssertEqual(CBManagerState.resetting.description, "resetting")
    }
}
