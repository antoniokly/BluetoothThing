//
//  FitnessMachineFeature.swift
//  
//
//  Created by Antonio Yip on 7/9/2023.
//

import Foundation

/**
 https://www.bluetooth.com/specifications/specs/fitness-machine-service-1-0/
 */
public struct FitnessMachineFeature: GATTCharacteristic {
    public let characteristic: BTCharacteristic = .fitnessMachineFeature
    
    public let fitnessMachineFeatures = GATTData(bytes: 4)
    public let targetSettingFeatures = GATTData(bytes: 4)
    
    func fitnessMachineFeaturesFlag(_ bitIndex: UInt) -> Bool {
        fitnessMachineFeatures.rawValue.bit(bitIndex)
    }
    
    func targetSettingFeaturesFlag(_ bitIndex: UInt) -> Bool {
        targetSettingFeatures.rawValue.bit(bitIndex)
    }
    
    public var averageSpeedSupported: Bool { fitnessMachineFeaturesFlag(0) }
    public var cadenceSupported: Bool { fitnessMachineFeaturesFlag(1) }
    public var totalDistanceSupported: Bool { fitnessMachineFeaturesFlag(2) }
    public var inclinationSupported: Bool { fitnessMachineFeaturesFlag(3) }
    public var elevationGainSupported: Bool { fitnessMachineFeaturesFlag(4) }
    public var paceSupported: Bool { fitnessMachineFeaturesFlag(5) }
    public var stepCountSupported: Bool { fitnessMachineFeaturesFlag(6) }
    public var resistanceLevelSupported: Bool { fitnessMachineFeaturesFlag(7) }
    public var strideCountSupported: Bool { fitnessMachineFeaturesFlag(8) }
    public var expendedEnergySupported: Bool { fitnessMachineFeaturesFlag(9) }
    public var heartRateMeasurementSupported: Bool { fitnessMachineFeaturesFlag(10) }
    public var metabolicEquivalentSupported: Bool { fitnessMachineFeaturesFlag(11) }
    public var elapsedTimeSupported: Bool { fitnessMachineFeaturesFlag(12) }
    public var remainingTimeSupported: Bool { fitnessMachineFeaturesFlag(13) }
    public var powerMeasurementSupported: Bool { fitnessMachineFeaturesFlag(14) }
    public var forceOnBeltAndPowerOutputSupported: Bool { fitnessMachineFeaturesFlag(15) }
    public var userDataRetentionSupported: Bool { fitnessMachineFeaturesFlag(16) }
    
    public var speedTargetSettingSupported: Bool { targetSettingFeaturesFlag(0) }
    public var inclinationTargetSettingSupported: Bool { targetSettingFeaturesFlag(1) }
    public var resistanceTargetSettingSupported: Bool { targetSettingFeaturesFlag(2) }
    public var powerTargetSettingSupported: Bool { targetSettingFeaturesFlag(3) }
    public var heartRateTargetSettingSupported: Bool { targetSettingFeaturesFlag(4) }
    public var targetedExpendedEnergyConfigurationSupported: Bool { targetSettingFeaturesFlag(5) }
    public var targetedStepNumberConfigurationSupported: Bool { targetSettingFeaturesFlag(6) }
    public var targetedStrideNumberConfigurationSupported: Bool { targetSettingFeaturesFlag(7) }
    public var targetedDistanceConfigurationSupported: Bool { targetSettingFeaturesFlag(8) }
    public var targetedTrainingTimeConfigurationSupported: Bool { targetSettingFeaturesFlag(9) }
    public var targetedTimeInTwoHeartRateZonesConfigurationSupported: Bool { targetSettingFeaturesFlag(10) }
    public var targetedTimeInThreeHeartRateZonesConfigurationSupported: Bool { targetSettingFeaturesFlag(11) }
    public var targetedTimeInFiveHeartRateZonesConfigurationSupported: Bool { targetSettingFeaturesFlag(12) }
    public var indoorBikeSimulationParametersSupported: Bool { targetSettingFeaturesFlag(13) }
    public var wheelCircumferenceConfigurationSupported: Bool { targetSettingFeaturesFlag(14) }
    public var spinDownControlSupported: Bool { targetSettingFeaturesFlag(15) }
    public var targetedCadenceConfigurationSupported: Bool { targetSettingFeaturesFlag(16) }
    
}
