//
//  BTCharacteristic.swift
//  BluetoothThing
//
//  Created by Antonio Yip on 22/01/20.
//  Copyright © 2020 Antonio Yip. All rights reserved.
//

import Foundation
import CoreBluetooth

public struct BTCharacteristic: Hashable, Codable {
    enum CodingKeys: String, CodingKey {
        case uuid, serviceUUID
    }

    public let serviceUUID: CBUUID
    public let uuid: CBUUID
    
    public init(service: String, characteristic: String) {
        self.init(service: CBUUID(string: service), characteristic: CBUUID(string: characteristic))
    }
    
    public init(service: CBUUID, characteristic: CBUUID) {
        self.serviceUUID = service
        self.uuid = characteristic
    }
    
    public init(service: BTService, characteristic: CBUUID) {
        self.init(service: service.uuid, characteristic: characteristic)
    }
    
    public init(service: BTService, characteristic: String) {
        self.init(service: service.uuid, characteristic: CBUUID(string: characteristic))
    }
    
    init(characteristic: CBCharacteristic) {
        self.init(service: characteristic.service?.uuid.uuidString ?? "", characteristic: characteristic.uuid.uuidString)
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let uuidString = try container.decode(String.self, forKey: .uuid)
        let serviceUUIDString = try container.decode(String.self, forKey: .serviceUUID)
        self.init(service: serviceUUIDString, characteristic: uuidString)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(uuid.uuidString, forKey: .uuid)
        try container.encode(serviceUUID.uuidString, forKey: .serviceUUID)
    }
}

public extension BTCharacteristic {
    static let modelNumberString = BTCharacteristic(service: "180A", characteristic: "2A24")
    static let serialNumber = BTCharacteristic(service: "180A", characteristic: "2A25")
    static let firmwareRevisionString = BTCharacteristic(service: "180A", characteristic: "2A26")
    static let manufacturerNameString = BTCharacteristic(service: "180A", characteristic: "2A29")
    static let batteryLevel = BTCharacteristic(service: "180F", characteristic: "2A19")
    static let batteryPowerState = BTCharacteristic(service: "180F", characteristic: "2A1A")

    // Fitness
    static let heartRateMeasurement = BTCharacteristic(service: "180D", characteristic: "2A37")
    static let bodySensorLocation = BTCharacteristic(service: "180D", characteristic: "2A38")
    static let cscMeasurement = BTCharacteristic(service: "1816", characteristic: "2A5B")
    static let cscFeature = BTCharacteristic(service: "1816", characteristic: "2A5C")

    // Cycling Power
    static let cyclingPowerSensorLocation = BTSubscription(service: "1818", characteristic: "2A5D")
//    static let cyclingPowerMeasurement = BTSubscription(service: "1818", characteristic: "2A63")
    static let cyclingPowerVector = BTSubscription(service: "1818", characteristic: "2A64")
    static let cyclingPowerFeature = BTSubscription(service: "1818", characteristic: "2A65")
    static let cyclingPowerControlPoint = BTSubscription(service: "1818", characteristic: "2A66")
    
    // GPS
    static let longitude = BTSubscription(service: "1819", characteristic: "2AAE")
    static let latitude = BTSubscription(service: "1819", characteristic: "2AAF")
    static let locationName = BTSubscription(service: "1819", characteristic: "2AB5")
    static let locationTime = BTSubscription(service: "1819", characteristic: "2A0F")
    
    // FTMS
    static let fitnessMachineControlPoint = BTCharacteristic(service: "1826", characteristic: "2AD9")
    static let fitnessMachineFeature = BTCharacteristic(service: "1826", characteristic: "2ACC")
    static let fitnessMachineStatus = BTCharacteristic(service: "1826", characteristic: "2ADA")
    static let fitnessMachineIndoorBikeData = BTCharacteristic(service: "1826", characteristic: "2AD2")
    static let fitnessMachineSensorLocation = BTCharacteristic(service: "1826", characteristic: "2A5D")
    
    static let cyclingPowerMeasurement = BTCharacteristic(service: "1818", characteristic: "2A63")

}
