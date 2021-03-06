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
    private var service: String
    private var characteristic: String
    
    public var serviceUUID: CBUUID { CBUUID(string: service) }
    public var uuid: CBUUID { CBUUID(string: characteristic) }
    
    public init(service: String, characteristic: String) {
        self.service = service
        self.characteristic = characteristic
    }
    
    public init(service: BTService, characteristic: String) {
        self.service = service.uuid.uuidString
        self.characteristic = characteristic
    }
    
    init(characteristic: CBCharacteristic) {
        self.init(service: characteristic.service.uuid.uuidString, characteristic: characteristic.uuid.uuidString)
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

    // GPS
    static let longitude = BTSubscription(service: "1819", characteristic: "2AAE")
    static let latitude = BTSubscription(service: "1819", characteristic: "2AAF")
    static let locationName = BTSubscription(service: "1819", characteristic: "2AB5")
    static let locationTime = BTSubscription(service: "1819", characteristic: "2A0F")
}
