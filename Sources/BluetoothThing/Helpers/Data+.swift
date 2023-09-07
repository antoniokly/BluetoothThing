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
