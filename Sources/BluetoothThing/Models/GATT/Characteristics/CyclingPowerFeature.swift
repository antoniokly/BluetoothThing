//
//  CyclingPowerFeature.swift
//
//
//  Created by Antonio Yip on 25/9/2023.
//

import Foundation

/*
 SensorLocation
 https://github.com/oesmith/gatt-xml/blob/master/org.bluetooth.characteristic.cycling_power_feature.xml
 */
public struct CyclingPowerFeature: GATTCharacteristic, GATTFeatureFlags {
    public let characteristic: BTCharacteristic = .cyclingPowerFeature
    
    let flags = GATTData(UInt32.self, bytes: 4)
    public var pedalPowerBalanceSupported: Bool { featureFlag(0) }
    public var accumulatedTorqueSupported: Bool { featureFlag(1) }
    public var wheelRevolutionDataSupported: Bool { featureFlag(2) }
    public var crankRevolutionDataSupported: Bool { featureFlag(3) }
    public var extremeMagnitudesSupported: Bool { featureFlag(4) }
    public var extremeAnglesSupported: Bool { featureFlag(5) }
    public var topAndBottomDeadSpotAnglesSupported: Bool { featureFlag(6) }
    public var accumulatedEnergySupported: Bool { featureFlag(7) }
    public var offsetCompensationIndicatorSupported: Bool { featureFlag(8) }
    public var offsetCompensationSupported: Bool { featureFlag(9) }
    public var cyclingPowerMeasurementCharacteristicContentMaskingSupported: Bool { featureFlag(10) }
    public var multipleSensorLocationsSupported: Bool { featureFlag(11) }
    public var crankLengthAdjustmentSupported: Bool { featureFlag(12) }
    public var chainLengthAdjustmentSupported: Bool { featureFlag(13) }
    public var chainWeightAdjustmentSupported: Bool { featureFlag(14) }
    public var spanLengthAdjustmentSupported: Bool { featureFlag(15) }
    public var sensorMeasurementContext: Bool { featureFlag(16) }
    public var instantaneousMeasurementDirectionSupported: Bool { featureFlag(17) }
    public var factoryCalibrationDateSupported: Bool { featureFlag(18) }
    public var enhancedOffsetCompensationSupported: Bool { featureFlag(19) }
    public var distributeSystemSupport: UInt8 {
        UInt8(flags.rawValue.bits(20...21))
    }
}
