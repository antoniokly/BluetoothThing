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
    static let coreData = OSLog(subsystem: subsystem, category: "coreData")
    static let bluetooth = OSLog(subsystem: subsystem, category: "bluetooth")
}
