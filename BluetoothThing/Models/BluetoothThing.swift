//
//  BluetoothThing.swift
//  BluetoothThing
//
//  Created by Antonio Yip on 9/01/20.
//  Copyright © 2020 Antonio Yip. All rights reserved.
//

import Foundation
import CoreBluetooth

let batteryServiceUUID = CBUUID(string: "180F")
let batteryLevel = CBUUID(string: "2A19")

//public protocol BluetoothThingProtocol {
//    var id: UUID { get }
//    var isDefault: Bool { get set }
//    var name: String? { get set }
//    var state: CBPeripheralState { get set }
//    var location: Location? { get set }
//    var rssi: Int? { get set }
//    var data: [String: [String: Data]] { get set }
//    init(id: UUID)
//}

class BluetoothThing {
    var id: UUID
    var isDefault: Bool = false
    var name: String? = nil
    var state: CBPeripheralState = .disconnected
    var location: Location? = nil
    var data: [String: [String: Data]] = [:]
    var rssi: Int? = nil

//    var actions: [String: (Any) -> Bool] = [:]

    private enum CodingKeys: String, CodingKey {
        case id
        case isDefault
        case name
        case state
        case location
        case data
        case rssi
    }
    
    required init(id: UUID) {
        self.id = id
    }
}




