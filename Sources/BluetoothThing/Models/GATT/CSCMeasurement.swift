//
//  CSCMeasurement.swift
//
//
//  Created by Antonio Yip on 7/9/2023.
//

import Foundation

/*
 CSC Measurement
 https://github.com/oesmith/gatt-xml/blob/master/org.bluetooth.characteristic.csc_measurement.xml
 */
public class CSCMeasurement: GATTCharacteristic {
    public let characteristic: BTCharacteristic = .cscMeasurement
    
    let flags = GATTData(bytes: 1)
    public var wheelRevolutionDataPresent: Bool { flags.flag(0) }
    public var crankRevolutionDataPresent: Bool { flags.flag(1) }
    public let cumulativeWheelRevolutions = GATTData(bytes: 4)
    public let lastWheelEventTime = GATTData(bytes: 2, binaryExponent: -10)
    public let cumulativeCrankRevolutions = GATTData(bytes: 2)
    public let lastCrankEventTime = GATTData(bytes: 2, binaryExponent: -10)
    
    public var cadence: Measurement<UnitFrequency> {        
        let rpm = Double(cumulativeCrankRevolutions.delta) * 60 / Double(lastCrankEventTime.delta) / pow(Double(2), Double(lastCrankEventTime.binaryExponent))
        
        return Measurement(value: rpm, unit: UnitFrequency.rpm)
    }
    
    public func speed(wheelCircumfrence: Double) -> Measurement<UnitSpeed> {
        let rph = Double(cumulativeWheelRevolutions.delta) * 3600 / Double(lastWheelEventTime.delta) / pow(Double(2), Double(lastWheelEventTime.binaryExponent))
        
        return Measurement(value: rph * wheelCircumfrence, unit: UnitSpeed.metersPerSecond)
    }
}
