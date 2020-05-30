//
//  Constants+Watch.swift
//  BluetoothThingWatch
//
//  Created by Antonio Yip on 30/04/20.
//  Copyright © 2020 Antonio Yip. All rights reserved.
//
#if os(watchOS)
import Foundation
import WatchKit

var deviceName: String {
    WKInterfaceDevice.current().name
}

var bundle: Bundle {
    Bundle(identifier: "yip.antonio.BluetoothThingWatch")!
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
#endif
