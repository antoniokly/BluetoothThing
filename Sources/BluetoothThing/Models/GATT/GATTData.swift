//
//  GATTData.swift
//
//
//  Created by Antonio Yip on 6/9/2023.
//

import Foundation

public extension Dimension {
    static let unitless = Dimension(symbol: "")
}

protocol GATTDataMeasureable {
    associatedtype UnitType: Dimension
    var unit: UnitType { get }
}

protocol GATTDataUpdatable {
    var byteWidth: Int { get }
    func update(_ buffer: [UInt8])
    func update(_ buffer: ArraySlice<UInt8>)
    func flag(_ bitIndex: Int) -> Bool
}

public class GATTData<UnitType: Dimension>: GATTDataUpdatable, GATTDataMeasureable {
    public let byteWidth: Int
    public let signed: Bool
    public let decimalExponent: Int
    public let resolution: Double
    public let unit: UnitType
    
    public private(set) var bytes: [UInt8] = []
    public private(set) var rawValue: any FixedWidthInteger = 0
    
//    public init(bits: Int, signed: Bool = false, decimalExponent: Int = 0, resolution: Double = 1, unit: UnitType = .unitless) {
//        self.bitWidth = bits
//        self.byteWidth = ((bits - 1) / UInt8.bitWidth) + 1
//        self.signed = signed
//        self.decimalExponent = decimalExponent
//        self.resolution = resolution
//        self.unit = unit
//    }
    
    public init(bytes: Int, signed: Bool = false, decimalExponent: Int = 0, resolution: Double = 1, unit: UnitType = .unitless) {
        self.byteWidth = bytes
        self.signed = signed
        self.decimalExponent = decimalExponent
        self.resolution = resolution
        self.unit = unit
    }
    
    public func update(_ buffer: [UInt8]) {
        bytes = buffer
        
        guard byteWidth > 0, bytes.count == byteWidth else {
            rawValue = 0
            return
        }
        /*
         bit size to byte index
         1 -> 0
         8 -> 0
         9 -> 1
         16 -> 1
         */
        //Array(buffer[0...Int((bitSize - 1) / UInt8.bitWidth)])
        
        let integerType: any FixedWidthInteger.Type
        
        switch byteWidth {
        case ...1:
            if signed {
                integerType = Int8.self
            } else {
                integerType = UInt8.self
            }
        case ...2:
            if signed {
                integerType = Int16.self
            } else {
                integerType = UInt16.self
            }
        case ...4:
            if signed {
                integerType = Int32.self
            } else {
                integerType = UInt32.self
            }
        case ...8:
            if signed {
                integerType = Int64.self
            } else {
                integerType = UInt64.self
            }
        default:
            fatalError("Not implemented")
        }
        
        let diff = Int(integerType.bitWidth / UInt8.bitWidth) - byteWidth
        rawValue = integerType.init(bytes + .init(repeating: 0, count: diff)) ?? 0
    }
    
    public func update(_ buffer: ArraySlice<UInt8>) {
        update(Array(buffer))
    }
    
    public var measurement: Measurement<UnitType> {
        Measurement(value: Double(rawValue) * pow(10, Double(decimalExponent)), unit: unit)
    }
    
    public func flag(_ bitIndex: Int) -> Bool {
        rawValue.bit(bitIndex)
    }
}
