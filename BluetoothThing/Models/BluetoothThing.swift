//
//  BluetoothThingPeripheral.swift
//  BluetoothThing
//
//  Created by Antonio Yip on 9/01/20.
//  Copyright © 2020 Antonio Yip. All rights reserved.
//

import Foundation
import CoreBluetooth


open class BluetoothThing: Codable {
    
//    static func == (lhs: BluetoothThing, rhs: BluetoothThing) -> Bool {
//        return lhs.id == rhs.id
//    }
    
    open var id: UUID
    open var name: String? = nil
    open var state: CBPeripheralState = .disconnected
    open var location: Location? = nil
    open var data: [String: [String: Data]] = [:]
    open var lastConnected: Date?
    open var lastDisconnected: Date?

    open var connect: () -> Void = {}
    open var disconnect: () -> Void = {}
    
    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case location
        case data
        case lastConnected
        case lastDisconnected
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
