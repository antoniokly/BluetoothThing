//
//  GATTData.swift
//
//
//  Created by Antonio Yip on 6/9/2023.
//

import Foundation

public struct GATTData<UnitType: Unit> {
    let bitWidth: Int
    public let signed: Bool
    public let decimalExponent: Int
    public let resolution: Double
    public let unit: UnitType
    
    public private(set) var bytes: [UInt8] = []
    public private(set) var rawValue: any FixedWidthInteger = 0
    
    public var byteWidth: Int {
        bitWidth * UInt8.bitWidth
    }
    
    public init(bitSize: Int, signed: Bool = false, decimalExponent: Int = 0, resolution: Double = 1, unit: UnitType) {
        self.bitWidth = bitSize
        self.signed = signed
        self.decimalExponent = decimalExponent
        self.resolution = resolution
        self.unit = unit
    }
    
    public mutating func update(_ buffer: [UInt8]) {
        bytes = buffer
        
        guard bitWidth > 0, bytes.count * UInt8.bitWidth == bitWidth else {
            rawValue = 0
            return
        }
        
        let integerType: any FixedWidthInteger.Type
        
        switch bitWidth {
        case ...8:
            if signed {
                integerType = Int8.self
            } else {
                integerType = UInt8.self
            }
        case ...16:
            if signed {
                integerType = Int16.self
            } else {
                integerType = UInt16.self
            }
        case ...32:
            if signed {
                integerType = Int32.self
            } else {
                integerType = UInt32.self
            }
        case ...64:
            if signed {
                integerType = Int64.self
            } else {
                integerType = UInt64.self
            }
        default:
            fatalError("Not implemented")
        }
        
        let diff = Int(ceil(Double((integerType.bitWidth - bytes.count) / UInt8.bitWidth)))
        rawValue = integerType.init(bytes + .init(repeating: 0, count: diff)) ?? 0
    }
    
    public var measurement: Measurement<UnitType> {
        Measurement(value: Double(rawValue) * pow(10, Double(decimalExponent)), unit: unit)
    }
    
    public func flag(_ bitIndex: Int) -> Bool {
        rawValue.flag(bitIndex)
    }
}
