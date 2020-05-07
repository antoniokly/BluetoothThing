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
}
