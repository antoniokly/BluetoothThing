//
//  GATTData.swift
//
//
//  Created by Antonio Yip on 6/9/2023.
//

import Foundation

protocol GATTDataMeasureable {
    associatedtype UnitType: Dimension
    var unit: UnitType { get }
}

protocol GATTDataUpdatable {
    var byteWidth: Int { get }
    var flagIndex: Int? { get }
    func update(_ buffer: [UInt8])
    func update(_ buffer: ArraySlice<UInt8>)
}

public class GATTData<RawValue: FixedWidthInteger, UnitType: Dimension>: GATTDataUpdatable, GATTDataMeasureable {
    public let byteWidth: Int
    public let decimalExponent: Int
    public let binaryExponent: Int
    public let resolution: Double
    public let unit: UnitType
    
    let flagIndex: Int?
    
    public private(set) var bytes: [UInt8] = []
    public private(set) var rawValue: RawValue = 0
    
    private var previousRawValue: RawValue?
    
    public init(_ storageType: RawValue.Type = UInt32.self, bytes: Int, decimalExponent: Int = 0, binaryExponent: Int = 0, resolution: Double = 1, unit: UnitType = .unitless, flagIndex: Int? = nil) {
        assert(bytes * UInt8.bitWidth <= RawValue.bitWidth, "Not enough storage bitWidth")

        self.byteWidth = bytes
        self.decimalExponent = decimalExponent
        self.binaryExponent = binaryExponent
        self.resolution = resolution
        self.unit = unit
        self.flagIndex = flagIndex
    }
    
    public func update(_ buffer: [UInt8]) {
        bytes = buffer
        
        guard byteWidth > 0, bytes.count == byteWidth else {
            previousRawValue = rawValue
            rawValue = 0
            return
        }
        
        previousRawValue = rawValue
        
        let diff = Int(RawValue.bitWidth / UInt8.bitWidth) - byteWidth
        rawValue = RawValue.init(bytes + .init(repeating: 0, count: diff)) ?? 0
    }
    
    public func update(_ buffer: ArraySlice<UInt8>) {
        update(Array(buffer))
    }
    
    public var measurement: Measurement<UnitType> {
        Measurement(value: Double(rawValue) * pow(10, Double(decimalExponent)) * pow(2, Double(binaryExponent)), unit: unit)
    }
    
    public var delta: RawValue {
        guard let previousRawValue else { return 0 }
        return rawValue.subtract(previousRawValue)
    }
}
