//
//  UInt8+.swift
//  BluetoothThing
//
//  Created by Antonio Yip on 8/05/20.
//  Copyright © 2020 Antonio Yip. All rights reserved.
//

import Foundation

public extension UInt8 {
    static let bit0: UInt8 = 0b01
    static let bit1: UInt8 = 0b10
    static let bit2: UInt8 = 0b100
    static let bit3: UInt8 = 0b1000
}

public extension FixedWidthInteger {
    func subtract(_ other: Self) -> Self {
        let dist = other.distance(to: self)
        if dist < 0 {
            return Self.max.advanced(by: dist)
        }
        return Self(dist)
    }
}
