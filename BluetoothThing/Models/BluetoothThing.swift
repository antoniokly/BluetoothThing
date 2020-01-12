//
//  BluetoothThingPeripheral.swift
//  BluetoothThing
//
//  Created by Antonio Yip on 9/01/20.
//  Copyright © 2020 Antonio Yip. All rights reserved.
//

import Foundation
import CoreBluetooth

public class BluetoothThing: Codable {
    
    static func == (lhs: BluetoothThing, rhs: BluetoothThing) -> Bool {
        return lhs.id == rhs.id
    }
    
    public var id: UUID
    public var name: String? = nil
    public var state: CBPeripheralState = .disconnected
    public var location: Location? = nil
    public var data: [String: [String: Data]] = [:]
    
    private enum CodingKeys: String, CodingKey {
        case id
        case name
//        case state
        case location
        case data
    }
    
    public init(id: UUID) {
        self.id = id
    }
    
    func updateData(with characteristic: CBCharacteristic) -> Bool {
        let serviceID = characteristic.service.uuid.uuidString
        let key = characteristic.uuid.uuidString
        var didChange = false
        
        var storage = self.data[serviceID] ?? [:]
        
        if storage[key] != characteristic.value {
            didChange = true
        }
        
        if let data = characteristic.value {
            storage[key] = data
        } else {
            storage.removeValue(forKey: key)
        }
        
        self.data[serviceID] = storage
        
        return didChange
    }
}
