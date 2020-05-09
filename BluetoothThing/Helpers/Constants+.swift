//
//  Constants+.swift
//  BluetoothThing
//
//  Created by Antonio Yip on 30/04/20.
//  Copyright © 2020 Antonio Yip. All rights reserved.
//

import Foundation

var deviceName: String {
    UIDevice.current.name
}

var bundle: Bundle {
    Bundle(identifier: "yip.antonio.BluetoothThing")!
}

var centralId: UUID {
    UIDevice.current.identifierForVendor!
}
