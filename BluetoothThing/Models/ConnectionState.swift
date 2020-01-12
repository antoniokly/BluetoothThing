//
//  ConnectionState.swift
//  BluetoothThing
//
//  Created by Antonio Yip on 9/01/20.
//  Copyright © 2020 Antonio Yip. All rights reserved.
//

import Foundation
import CoreBluetooth

public typealias ConnectionState = CBPeripheralState
public extension CBPeripheralState {
    var string: String {
        switch self {
        case .connected:
            return "connected"
        case .disconnected:
            return "disconnected"
        case .connecting:
            return "connecting"
        case .disconnecting:
            return "disconnecting"
        default:
            return "unknown"
        }
    }
}
