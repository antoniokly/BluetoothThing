//
//  WheelRevolutionsData.swift
//
//
//  Created by Antonio Yip on 23/9/2023.
//

import Foundation

public protocol WheelRevolutionsData {
    var cumulativeWheelRevolutions: GATTData<UInt32, Dimension> { get }
    var lastWheelEventTime: GATTData<UInt16, UnitDuration>  { get }
}

public extension WheelRevolutionsData {
    func speed(wheelCircumfrence: Double) -> Measurement<UnitSpeed> {
        let rph = Double(cumulativeWheelRevolutions.delta) * 3600 / Double(lastWheelEventTime.delta) / pow(Double(2), Double(lastWheelEventTime.binaryExponent))
        
        return Measurement(value: rph * wheelCircumfrence, unit: UnitSpeed.metersPerSecond)
    }
}
