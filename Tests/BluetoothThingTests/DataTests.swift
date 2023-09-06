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
        
        XCTAssertEqual(Data([3, 189, 1, 0, 0, 125, 158, 50, 0, 65, 66]).hexEncodedString, "03bd0100007d9e32004142")
        
        XCTAssertEqual(UInt32(buffer[1...4]), 445)
        XCTAssertEqual(UInt16(buffer[5...6]), 40573)
        XCTAssertEqual(UInt16(buffer[7...8]), 50)
        XCTAssertEqual(UInt16(buffer[9...10]), 16961)
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
        
//        print(Int32.bitWidth)
//        print(Int32.max)
//        print(Int32.min)
//        
//        print(UInt32.bitWidth)
//        print(UInt32.max)
//        print(UInt32.min)
//        
//        print(UInt16.bitWidth)
//        print(UInt16.max)
//        print(UInt16.min)
//        
//        print(Int16.bitWidth)
//        print(Int16.max)
//        print(Int16.min)
//        
//        print(String(UInt16(bitPattern: -32767), radix: 2))
//        print(String(UInt16(bitPattern: -32767), radix: 16))
//        print(String(UInt16(bitPattern: 32767), radix: 2))
//        print(String(UInt16(bitPattern: 32767), radix: 16))
//        
//        print(Int16(bitPattern: 0x8001))
//        print(Int16(bitPattern: 0x7fff))
//        
//        print(Int16([0x01, 0x80]))
//        print(UInt16([0xff, 0]))
//        print(UInt16([0xff, 0, 0xab, 0xef]))
//        print(UInt16([0xff]))
//
//        
//        print(String(UInt16(bitPattern: 32767).bigEndian, radix: 16))
        
        XCTAssertEqual(UInt16([0xff, 0]), 255)
        XCTAssertEqual(UInt16(255).bytes, [0xff, 0])
        
        XCTAssertEqual(UInt16([0, 0xff, 0]), 0xFF00)
        XCTAssertEqual(UInt16([0xFF, 0xff, 0]), 65535)
        XCTAssertEqual(UInt16.max.bytes, [0xff, 0xff])

        XCTAssertEqual(String(UInt16(bitPattern: -32767), radix: 16), String(UInt16(0x8001), radix: 16))
        XCTAssertEqual(Int16([0x01, 0x80]), -32767)
    }
}
