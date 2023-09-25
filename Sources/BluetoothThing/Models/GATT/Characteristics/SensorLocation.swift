//
//  SensorLocation.swift
//
//
//  Created by Antonio Yip on 25/9/2023.
//

import Foundation

/*
 SensorLocation
 https://github.com/oesmith/gatt-xml/blob/master/org.bluetooth.characteristic.sensor_location.xml
 */
public struct SensorLocation: GATTCharacteristic, GATTFeatureFlags {
    public let characteristic: BTCharacteristic = .fitnessMachineSensorLocation
    
    let flags = GATTData(bytes: 1)
    public var other: Bool { featureFlag(0) }
    public var topOfShoe: Bool { featureFlag(1) }
    public var inShoe: Bool { featureFlag(2) }
    public var hip: Bool { featureFlag(3) }
    public var frontWheel: Bool { featureFlag(4) }
    public var leftCrank: Bool { featureFlag(5) }
    public var rightCrank: Bool { featureFlag(6) }
    public var leftPedal: Bool { featureFlag(7) }
    public var rightPedal: Bool { featureFlag(8) }
    public var frontHub: Bool { featureFlag(9) }
    public var rearDropout: Bool { featureFlag(10) }
    public var chainstay: Bool { featureFlag(11) }
    public var rearWheel: Bool { featureFlag(12) }
    public var rearHub: Bool { featureFlag(13) }
    public var chest: Bool { featureFlag(14) }
    public var spider: Bool { featureFlag(15) }
    public var chainRing: Bool { featureFlag(16) }
}
