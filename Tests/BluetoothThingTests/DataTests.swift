//
//  DataTests.swift
//  BluetoothThingTests
//
//  Created by Antonio Yip on 10/05/20.
//  Copyright © 2020 Antonio Yip. All rights reserved.
//

import XCTest
@testable import BluetoothThing

class DataTests: XCTestCase {

  

    func testData() throws {
        let data = Data(hexString: "03bd0100007d9e32004142")
        let buffer = [UInt8](data)
        
        XCTAssertEqual(data.hexEncodedString, "03bd0100007d9e32004142")
        XCTAssertEqual(buffer, [3, 189, 1, 0, 0, 125, 158, 50, 0, 65, 66])
        
        XCTAssertEqual(Data(hexString: "ff").int, 255)
        XCTAssertEqual(Data(hexString: "ffff").int, 65535)
        
        XCTAssertEqual([3, 189, 1, 0, 0, 125, 158, 50, 0, 65, 66].data.hexEncodedString, "03bd0100007d9e32004142")
        
        XCTAssertEqual(buffer[1...4].reversed().uint32, 445)
        XCTAssertEqual(Array(buffer[5...6]).uint16, 40573)
        XCTAssertEqual(Array(buffer[7...8]).uint16, 50)
        XCTAssertEqual(Array(buffer[9...10]).uint16, 16961)
    }
    
    func testInteger() throws {
        let a: UInt8 = 2
        let b: UInt8 = 10
        
        XCTAssertEqual(b.subtract(a), 8)
        XCTAssertEqual(a.subtract(b), UInt8.max - 8)
        
        let c: UInt16 = 0
        let d: UInt16 = 3
        
        XCTAssertEqual(d.subtract(c), 3)
        XCTAssertEqual(c.subtract(d), UInt16.max - 3)
    }
   
}
