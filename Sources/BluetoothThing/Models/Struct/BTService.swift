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
    enum CodingKeys: String, CodingKey {
        case uuid
    }
    
    public let uuid: CBUUID
    
    public init(service: String) {
        self.uuid = CBUUID(string: service)
    }
    
    public init(uuid: CBUUID) {
        self.uuid = uuid
    }
    
    init(service: CBService) {
        self.uuid = service.uuid
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let uuidString = try container.decode(String.self, forKey: .uuid)
        self.init(service: uuidString)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(uuid.uuidString, forKey: .uuid)
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
