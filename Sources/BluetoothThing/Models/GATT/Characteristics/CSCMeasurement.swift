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
public class CSCMeasurement: GATTCharacteristic, GATTFeatureFlags, CrankRevolutionData, WheelRevolutionData {
    public let characteristic: BTCharacteristic = .cscMeasurement
    
    let flags = GATTData(bytes: 1)
    public var wheelRevolutionDataPresent: Bool { featureFlag(0) }
    public var crankRevolutionDataPresent: Bool { featureFlag(1) }
    
    public let cumulativeWheelRevolutions = GATTData(UInt32.self, bytes: 4, flagIndex: 0)
    public let lastWheelEventTime = GATTData(UInt16.self, bytes: 2, binaryExponent: -10, unit: UnitDuration.seconds, flagIndex: 0)
    public let cumulativeCrankRevolutions = GATTData(UInt16.self, bytes: 2, flagIndex: 1)
    public let lastCrankEventTime = GATTData(UInt16.self, bytes: 2, binaryExponent: -10, unit: UnitDuration.seconds, flagIndex: 1)
}
