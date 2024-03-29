//
//  WheelRevolutionData.swift
//
//
//  Created by Antonio Yip on 23/9/2023.
//

import Foundation

public protocol WheelRevolutionData {
    var cumulativeWheelRevolutions: GATTData<UInt32, Dimension> { get }
    var lastWheelEventTime: GATTData<UInt16, UnitDuration>  { get }
}

public extension WheelRevolutionData {
    func speed(wheelCircumfrence: Double) -> Measurement<UnitSpeed> {
        let rph = Double(cumulativeWheelRevolutions.delta) / Double(lastWheelEventTime.delta) / pow(Double(2), Double(lastWheelEventTime.binaryExponent))
        
        return Measurement(value: rph * wheelCircumfrence, unit: UnitSpeed.metersPerSecond)
    }
}
