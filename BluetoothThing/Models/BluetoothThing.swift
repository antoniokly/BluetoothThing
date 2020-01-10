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
    
    init(id: UUID) {
        self.id = id
    }
    
    static func == (lhs: BluetoothThing, rhs: BluetoothThing) -> Bool {
        return lhs.id == rhs.id
    }
}
