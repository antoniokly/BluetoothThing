//
//  Numeric+.swift
//  BluetoothThing
//
//  Created by Antonio Yip on 8/05/20.
//  Copyright © 2020 Antonio Yip. All rights reserved.
//

import Foundation

extension FixedWidthInteger {
    func subtract(_ other: Self) -> Self {
        let dist = other.distance(to: self)
        if !Self.isSigned, dist < 0 {
            return Self.max.advanced(by: dist)
        }
        return Self(dist)
    }
    
    func bit(_ bitIndex: Int) -> Bool {
        guard bitIndex < self.bitWidth else { return false }
        return self & (1 << bitIndex) > 0
    }
}

public extension Numeric {
    var bytes: [UInt8] {
        return self.convertToBytes(withCapacity: MemoryLayout<Self>.size)
    }
    
    init?(_ bytes: [UInt8]) {
        guard bytes.count >= MemoryLayout<Self>.size else {
            return nil
        }
        
        self = bytes.withUnsafeBytes {
            return $0.load(as: Self.self)
        }
    }
    
    init?(_ bytes: ArraySlice<UInt8>) {
        self.init(Array(bytes))
    }
    
    func convertToBytes(withCapacity capacity: Int) -> [UInt8] {
        var mutableValue = self
        return withUnsafePointer(to: &mutableValue) {
            
            return $0.withMemoryRebound(to: UInt8.self, capacity: capacity) {
                
                return Array(UnsafeBufferPointer(start: $0, count: capacity))
            }
        }
    }
}
