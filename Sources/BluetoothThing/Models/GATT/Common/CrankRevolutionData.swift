//
//  CrankRevolutionData.swift
//
//
//  Created by Antonio Yip on 23/9/2023.
//

import Foundation

public protocol CrankRevolutionData {    
    var cumulativeCrankRevolutions: GATTData<UInt16, Dimension> { get }
    var lastCrankEventTime: GATTData<UInt16, UnitDuration>  { get }
}

public extension CrankRevolutionData {
    var cadence: Measurement<UnitFrequency> {
        let rpm = Double(cumulativeCrankRevolutions.delta) * 60 / Double(lastCrankEventTime.delta) / pow(Double(2), Double(lastCrankEventTime.binaryExponent))
        return Measurement(value: rpm, unit: UnitFrequency.rpm)
    }
}
