//
//  FitnessMachineStatus.swift
//
//
//  Created by Antonio Yip on 24/9/2023.
//

import Foundation

public struct FitnessMachineStatus: GATTCharacteristic, GATTOpCodes {
    public let characteristic: BTCharacteristic = .fitnessMachineStatus
    
    let opCodeData = GATTData(UInt8.self, bytes: 1)
    public let targetResistanceLevel = GATTData(UInt8.self, bytes: 1, decimalExponent: -1, resolution: 0.1, opCode: 0x07)
    public let targetPower = GATTData(Int16.self, bytes: 2, unit: UnitPower.watts, opCode: 0x08)
    public let indoorBikeSimulation = IndoorBikeSimulation()
    public let wheelCircumference = GATTData(UInt16.self, bytes: 2, decimalExponent: -1, resolution: 0.1, unit: UnitLength.millimeters, opCode: 0x13)
    public let spinDownStatusData = GATTData(UInt8.self, bytes: 1, opCode: 0x14)
    
    var spinDownStatus: SpinDownStatus? {
        SpinDownStatus(rawValue: spinDownStatusData.rawValue)
    }
}

public extension FitnessMachineStatus {
    enum SpinDownStatus: UInt8 {
        case spinDownRequested = 0x01
        case success = 0x02
        case error = 0x03
        case stopPedaling = 0x04
    }
    
    struct IndoorBikeSimulation: GATTCharacteristicUpdatable, GATTOpCodeUpdatable {
        let opCode: UInt? = 0x12
        
        public let windSpeed = GATTData(Int16.self, bytes: 2, decimalExponent: -3, resolution: 0.001, unit: UnitSpeed.metersPerSecond)
        public let grade = GATTData(Int16.self, bytes: 2, decimalExponent: -2, resolution: 0.01)
        public let rollingResistanceCoefficient = GATTData(UInt8.self, bytes: 1, decimalExponent: -4, resolution: 0.0001)
        public let windResistanceCoefficient = GATTData(UInt8.self, bytes: 1, decimalExponent: -2, resolution: 0.01) // TODO: unit kg/m
    }
}
