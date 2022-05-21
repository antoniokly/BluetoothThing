//
//  Data+.swift
//  BluetoothThing
//
//  Created by Antonio Yip on 28/01/20.
//  Copyright © 2020 Antonio Yip. All rights reserved.
//

import Foundation

public extension Data {
    var hexEncodedString: String {
        map { String(format: "%02hhx", $0) }.joined()
    }
    
    var int: Int? {
        Int(hexEncodedString, radix: 16)
    }

    func string(encoding: String.Encoding) -> String? {
        String(data: self, encoding: encoding)
    }
    
    init(hexString string: String) {
        self.init()
        var hex = string
        while(hex.count > 0) {
            let subIndex = hex.index(hex.startIndex, offsetBy: 2)
            let c = String(hex[..<subIndex])
            hex = String(hex[subIndex...])
            var ch: UInt32 = 0
            Scanner(string: c).scanHexInt32(&ch)
            var char = UInt8(ch)
            self.append(&char, count: 1)
        }
    }
}

public extension Array where Element == UInt8 {
    var data: Data {
        return Data(self)
    }
    
    var uint16: UInt16 {
        return self.withUnsafeBytes { $0.load(as: UInt16.self) }
    }
    
    var uint32: UInt32 {
        return UInt32(bigEndian: self.withUnsafeBufferPointer {
            ($0.baseAddress!.withMemoryRebound(to: UInt32.self, capacity: 1) { $0 })
        }.pointee)
    }
}
