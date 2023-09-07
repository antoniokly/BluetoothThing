//
//  Units.swift
//  
//
//  Created by Antonio Yip on 7/9/2023.
//

import Foundation

public extension UnitFrequency {
    static let rpm: UnitFrequency = UnitFrequency(symbol: "RPM")
}

public class UnitHeartBeat: Dimension {
    static let bpm: UnitHeartBeat = UnitHeartBeat(symbol: "♥︎ BPM")

    public override class func baseUnit() -> Self {
        Self.bpm as! Self
    }
}

public class UnitOxygen: Dimension {
    static let vo2Max: UnitOxygen = UnitOxygen(symbol: "ml/kg*min")

    public override class func baseUnit() -> Self {
        Self.vo2Max as! Self
    }
}
