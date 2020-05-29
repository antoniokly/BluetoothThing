//
//  BTService.swift
//  BluetoothThing
//
//  Created by Antonio Yip on 29/04/20.
//  Copyright © 2020 Antonio Yip. All rights reserved.
//

import Foundation
import CoreBluetooth

public struct BTService: Hashable, Codable {
        
    private var service: String
    
    public var uuid: CBUUID { CBUUID(string: service) }
    
    public init(service: String) {
        self.service = service
    }
    
    init(service: CBService) {
        self.service = service.uuid.uuidString
    }
}

public extension BTService {
    static let deviceInformation = BTService(service: "180A")
    static let batteryService = BTService(service: "180F")
    
    // Fitness
    static let runningSpeedAndCadenceService = BTService(service: "1814")
    static let cyclingSpeedAndCadenceService = BTService(service: "1816")
    static let cyclingPowerService = BTService(service: "1818")
    static let heartRateService = BTService(service: "180D")
    
    // Bean
    static let beanSerialService = BTService(service: "A495FF10-C5B1-4B44-B512-1370F02D74DE")
    static let beanScratchService = BTService(service: "A495FF20-C5B1-4B44-B512-1370F02D74DE")
}
