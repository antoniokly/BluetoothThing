//
//  Service.swift
//  BluetoothThing
//
//  Created by Antonio Yip on 9/01/20.
//  Copyright © 2020 Antonio Yip. All rights reserved.
//

import Foundation
import CoreBluetooth

protocol ServiceProtocol {
    var uuid: CBUUID { get }
    var characteristics: [CBCharacteristic]? { get }
}

extension CBService: ServiceProtocol {
    
}
