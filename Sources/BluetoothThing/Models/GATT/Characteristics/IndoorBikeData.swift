//
//  IndoorBikeData.swift
//  
//
//  Created by Antonio Yip on 7/9/2023.
//

import Foundation

/*
 IndoorBikeData
 https://github.com/oesmith/gatt-xml/blob/master/org.bluetooth.characteristic.indoor_bike_data.xml
 */
public struct IndoorBikeData: GATTCharacteristic, GATTFeatureFlags {
    public let characteristic: BTCharacteristic = .fitnessMachineIndoorBikeData
    
    let flags = GATTData(bytes: 2)
    public var moreData: Bool { featureFlag(0) }
    public var instantaneousCadencePresent: Bool { featureFlag(1) }
    public var averageSpeedPresent: Bool { featureFlag(2) }
    public var averageCandencePresent: Bool { featureFlag(3) }
    public var totalDistancePresent: Bool { featureFlag(4) }
    public var resistanceLevelPresent: Bool { featureFlag(5) }
    public var instantaneousPowerPresent: Bool { featureFlag(6) }
    public var averagePowerPresent: Bool { featureFlag(7) }
    public var expendedEnergyPresent: Bool { featureFlag(8) }
    public var heartRatePresent: Bool { featureFlag(9) }
    public var metabolicEquivalentPresent: Bool { featureFlag(10) }
    public var elapsedTimePresent: Bool { featureFlag(11) }
    public var remainingTimePresent: Bool { featureFlag(12) }
    
    public let instantaneousSpeed = GATTData(bytes: 2, decimalExponent: -2, resolution: 0.01, unit: UnitSpeed.kilometersPerHour)
    public let averageSpeed = GATTData(bytes: 2, decimalExponent: -2, resolution: 0.01, unit: UnitSpeed.kilometersPerHour, flagIndex: 2)
    public let instantaneousCadence = GATTData(bytes: 2, decimalExponent: -1, resolution: 0.5, unit: UnitFrequency.rpm, flagIndex: 1)
    public let averageCadence = GATTData(bytes: 2, decimalExponent: -1, resolution: 0.5, unit: UnitFrequency.rpm, flagIndex: 3)
    public let totalDistance = GATTData(bytes: 3, unit: UnitLength.meters, flagIndex: 4)
    public let resistanceLevel = GATTData(bytes: 2, flagIndex: 5)
    public let instantaneousPower = GATTData(bytes: 2, unit: UnitPower.watts, flagIndex: 6)
    public let averagePower = GATTData(bytes: 2, unit: UnitPower.watts, flagIndex: 7)
    public let totalEnergy = GATTData(bytes: 2, unit: UnitEnergy.kilocalories, flagIndex: 8)
    public let energyPerHour = GATTData(bytes: 2, unit: UnitEnergy.kilocalories, flagIndex: 8)
    public let energyPerMinute = GATTData(bytes: 1, unit: UnitEnergy.kilocalories, flagIndex: 8)
    public let heartRate = GATTData(bytes: 1, unit: UnitHeartBeat.bpm, flagIndex: 9)
    public let metabolicEquivalent = GATTData(bytes: 2, decimalExponent: -1, resolution: 0.1, flagIndex: 10)
    public let elapsedTime = GATTData(bytes: 2, flagIndex: 11)
    public let remainingTime = GATTData(bytes: 2, flagIndex: 12)
}
