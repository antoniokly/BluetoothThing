//
//  Constants+Mac.swift
//  BluetoothThingMac
//
//  Created by Antonio Yip on 21/05/20.
//  Copyright © 2020 Antonio Yip. All rights reserved.
//

import Foundation

var bundle: Bundle {
    Bundle(identifier: "yip.antonio.BluetoothThingMac")!
}

var deviceName: String {
    Host.current().localizedName!
}

var centralId: UUID {
    if let uuidString = UserDefaults.standard.object(forKey: .centralId) as? String,
        let uuid = UUID(uuidString: uuidString) {
        return uuid
    } else {
        let uuid = UUID()
        UserDefaults.standard.set(uuid.uuidString, forKey: .centralId)
        return uuid
    }
}
