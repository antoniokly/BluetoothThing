//
//  Service.swift
//  BluetoothThing
//
//  Created by Antonio Yip on 9/01/20.
//  Copyright © 2020 Antonio Yip. All rights reserved.
//

import Foundation
import CoreBluetooth

protocol Service {
    var uuid: CBUUID { get }
//    var identifier: UUID { get }
//    var name: String? { get }
//    var state: CBPeripheralState { get }
//    var services: [CBService]? { get }
//
//    func setNotifyValue(_: Bool, for: CBCharacteristic)
}

extension CBService: Service {
    
}
