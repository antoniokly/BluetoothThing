//
//  OSLog+.swift
//  
//
//  Created by Antonio Yip on 23/5/2022.
//

import Foundation
import os.log

extension OSLog {
    static let subsystem = "BluetoothThing"
    static let storage = OSLog(subsystem: subsystem, category: "BluetoothThingStorage")
    static let bluetooth = OSLog(subsystem: subsystem, category: "BluetoothThing")
}
