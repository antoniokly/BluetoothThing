//
//  FitnessMachineFeature.swift
//  
//
//  Created by Antonio Yip on 7/9/2023.
//

import Foundation

public struct FitnessMachineFeature: GATTCharacteristic {
    public let characteristic: BTCharacteristic = .fitnessMachineFeature
    
    public let fitnessMachineFeatures = GATTData(bytes: 4)
    public let targetSettingFeatures = GATTData(bytes: 4)
    
    public var averageSpeedSupported: Bool { fitnessMachineFeatures.flag(0) }
    public var cadenceSupported: Bool { fitnessMachineFeatures.flag(1) }
    public var totalDistanceSupported: Bool { fitnessMachineFeatures.flag(2) }
    public var inclinationSupported: Bool { fitnessMachineFeatures.flag(3) }
    public var elevationGainSupported: Bool { fitnessMachineFeatures.flag(4) }
    public var paceSupported: Bool { fitnessMachineFeatures.flag(5) }
    public var stepCountSupported: Bool { fitnessMachineFeatures.flag(6) }
    public var resistanceLevelSupported: Bool { fitnessMachineFeatures.flag(7) }
    public var strideCountSupported: Bool { fitnessMachineFeatures.flag(8) }
    public var expendedEnergySupported: Bool { fitnessMachineFeatures.flag(9) }
    public var heartRateMeasurementSupported: Bool { fitnessMachineFeatures.flag(10) }
    public var metabolicEquivalentSupported: Bool { fitnessMachineFeatures.flag(11) }
    public var elapsedTimeSupported: Bool { fitnessMachineFeatures.flag(12) }
    public var remainingTimeSupported: Bool { fitnessMachineFeatures.flag(13) }
    public var powerMeasurementSupported: Bool { fitnessMachineFeatures.flag(14) }
    public var forceOnBeltAndPowerOutputSupported: Bool { fitnessMachineFeatures.flag(15) }
    public var userDataRetentionSupported: Bool { fitnessMachineFeatures.flag(16) }
    
    public var speedTargetSettingSupported: Bool { targetSettingFeatures.flag(0) }
    public var inclinationTargetSettingSupported: Bool { targetSettingFeatures.flag(1) }
    public var resistanceTargetSettingSupported: Bool { targetSettingFeatures.flag(2) }
    public var powerTargetSettingSupported: Bool { targetSettingFeatures.flag(3) }
    public var heartRateTargetSettingSupported: Bool { targetSettingFeatures.flag(4) }
    public var targetedExpendedEnergyConfigurationSupported: Bool { targetSettingFeatures.flag(5) }
    public var targetedStepNumberConfigurationSupported: Bool { targetSettingFeatures.flag(6) }
    public var targetedStrideNumberConfigurationSupported: Bool { targetSettingFeatures.flag(7) }
    public var targetedDistanceConfigurationSupported: Bool { targetSettingFeatures.flag(8) }
    public var targetedTrainingTimeConfigurationSupported: Bool { targetSettingFeatures.flag(9) }
    public var targetedTimeInTwoHeartRateZonesConfigurationSupported: Bool { targetSettingFeatures.flag(10) }
    public var targetedTimeInThreeHeartRateZonesConfigurationSupported: Bool { targetSettingFeatures.flag(11) }
    public var targetedTimeInFiveHeartRateZonesConfigurationSupported: Bool { targetSettingFeatures.flag(12) }
    public var indoorBikeSimulationParametersSupported: Bool { targetSettingFeatures.flag(13) }
    public var wheelCircumferenceConfigurationSupported: Bool { targetSettingFeatures.flag(14) }
    public var spinDownControlSupported: Bool { targetSettingFeatures.flag(15) }
    public var targetedCadenceConfigurationSupported: Bool { targetSettingFeatures.flag(16) }
    
}
