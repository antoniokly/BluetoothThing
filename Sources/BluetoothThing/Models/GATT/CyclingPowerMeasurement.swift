//
//  CyclingPowerMeasurement.swift
//  Cyclo
//
//  Created by Antonio Yip on 6/9/2023.
//  Copyright © 2023 Antonio Yip. All rights reserved.
//

import Foundation

/*
 Cycling Power Measurement
 https://github.com/oesmith/gatt-xml/blob/master/org.bluetooth.characteristic.cycling_power_measurement.xml
 */
public struct CyclingPowerMeasurement: GATTCharacteristic, CrankRevolutionsData, WheelRevolutionsData {
    public let characteristic: BTCharacteristic = .cyclingPowerMeasurement
    
    let flags = GATTData(bytes: 2)
    public let instantaneousPower = GATTData(Int16.self, bytes: 2, unit: UnitPower.watts)
    public let pedalPowerBalance = GATTData(UInt8.self, bytes: 1, binaryExponent: -1, resolution: 1/2, flagIndex: 0)
    public let accumulatedTorque = GATTData(UInt16.self, bytes: 2, binaryExponent: -5, resolution: 1/32, flagIndex: 2) // TODO: unit newtonMeter
    public let cumulativeWheelRevolutions = GATTData(UInt32.self, bytes: 4, flagIndex: 4)
    public let lastWheelEventTime = GATTData(UInt16.self, bytes: 2, binaryExponent: -11, resolution: 1/2048, unit: UnitDuration.seconds, flagIndex: 4)
    public let cumulativeCrankRevolutions = GATTData(UInt16.self, bytes: 2, flagIndex: 5)
    public let lastCrankEventTime = GATTData(UInt16.self, bytes: 2, binaryExponent: -10, resolution: 1/1024, unit: UnitDuration.seconds, flagIndex: 5)
    public let maximumForceMagnitude = GATTData(Int16.self, bytes: 2, flagIndex: 6) // TODO: unit newton
    public let minimumForceMagnitude = GATTData(Int16.self, bytes: 2, flagIndex: 6) // TODO: unit newton
    public let maximumTorqueMagnitude = GATTData(Int16.self, bytes: 2, binaryExponent: -5, resolution: 1/32, flagIndex: 7) // TODO: unit newton meters
    public let minimumTorqueMagnitude = GATTData(Int16.self, bytes: 2, binaryExponent: -5, resolution: 1/32, flagIndex: 7) // TODO: unit newton meters
    public let extremeAngles = GATTData(bytes: 3, flagIndex: 8) // TODO: 12bit for minimum and 12bit for maximum
    public let topDeadSpotAngle = GATTData(UInt16.self, bytes: 2, flagIndex: 9)
    public let bottomDeadSpotAngle = GATTData(UInt16.self, bytes: 2, flagIndex: 10)
    public let accumulatedEnergy = GATTData(UInt16.self, bytes: 2, decimalExponent: 3, unit: UnitEnergy.joules, flagIndex: 11)
    
    // Flags
    public var pedalPowerBalancePresent: Bool { flags.flag(0) }
    public var pedalPowerBalanceReference: PedalPowerBalanceReference { flags.flag(1) ? .left : .unknown }
    public var accumulatedTorquePresent: Bool { flags.flag(2) }
    public var accumulatedTorqueSource: AccumulatedTorqueSource { flags.flag(3) ? .crankBased : .wheelBased }
    public var wheelRevolutionDataPresent: Bool { flags.flag(4) }
    public var crankRevolutionDataPresent: Bool { flags.flag(5) }
    public var extremeForceMagnitudesPresent: Bool { flags.flag(6) }
    public var extremeTorqueMagnitudesPresent: Bool { flags.flag(7) }
    public var extremeAnglesPresent: Bool { flags.flag(8) }
    public var topDeadSpotAnglePresent: Bool { flags.flag(9) }
    public var bottomDeadSpotAnglePresent: Bool { flags.flag(10) }
    public var accumulatedEnergyPresent: Bool { flags.flag(11) }
    public var offsetCompensationIndicator: Bool { flags.flag(12) }
}

public extension CyclingPowerMeasurement {
    enum PedalPowerBalanceReference {
        case unknown, left
    }
    
    enum AccumulatedTorqueSource {
        case wheelBased, crankBased
    }
}
//struct cyclingPowerMeasurement {
//    let speed = GATTData(
//        UInt16.self,
//        unit: UnitSpeed.kilometersPerHour,
//        decimalExponent: -2,
//        resolution: 0.01
//    )
//}

//POwer 2a63

//0x14000700D80006000000DE45
//0x14000800AA0005000000273C
//0x140008007900040000003432
//0x14000800450003000000CE27
//0x14000000450002000000881C

//0x14004F009E345F060000198D
//0x14004C000B335A060000F484
//0x140049007731550600008F7C
//0x14002F007F30510600009A75
//0x14002700A32F4C0600009D6C
