//
//  Data+.swift
//  BluetoothThing
//
//  Created by Antonio Yip on 28/01/20.
//  Copyright © 2020 Antonio Yip. All rights reserved.
//

import Foundation

public extension Data {
    
    var uint8: UInt8 {
        var number: UInt8 = 0
        if self.count >= 8 {
            self.copyBytes(to:&number, count: MemoryLayout<UInt8>.size)
        }
        return number
    }
    
    var uuid: NSUUID? {
        var bytes = [UInt8](repeating: 0, count: self.count)
        self.copyBytes(to:&bytes, count: self.count * MemoryLayout<UInt32>.size)
        return NSUUID(uuidBytes: bytes)
    }
    
    var hexEncodedString: String {
        map { String(format: "%02hhx", $0) }.joined()
    }
    
//    var int: Int? {
//        Int(hexEncodedString, radix: 16)
//    }
    
//    var stringASCII: String? {
//        get {
//            return String(data: self, encoding: String.Encoding.ascii.rawValue) as String?
//        }
//    }
//
//    var stringUTF8: String? {
//        String(data: self, encoding: .utf8)
//    }
    
//    var utf16LittleEndian: String {
//        String(data: self, encoding: .utf16LittleEndian) ?? ""
//    }
//    
//    var utf32LittleEndian: String {
//        String(data: self, encoding: .utf32LittleEndian) ?? ""
//    }
}
