//
//  Constants.swift
//  BluetoothThing
//
//  Created by Antonio Yip on 1/03/20.
//  Copyright © 2020 Antonio Yip. All rights reserved.
//

import Foundation

#if canImport(WatchKit)
import WatchKit
#endif

#if canImport(TVUIKit)
import TVUIKit
#endif

extension String {
    static let id = "id"
    static let centralId = "centralId"
    static let peripheralId = "peripheralId"
    static let image = "image"
    static let displayName = "displayName"
    static let name = "name"
    static let data = "data"
    static let characteristics = "characteristics"
    static let customData = "customData"
    static let isRegistered = "isRegistered"
    static let key = "key"
    static let value = "value"
    static let modifiedAt = "modifiedAt"
}

var deviceName: String {
    #if os(iOS)
    return UIDevice.current.name
    #elseif os(OSX)
    return Host.current().localizedName!
    #elseif os(watchOS)
    return WKInterfaceDevice.current().name
    #else
    return "unknown"
    #endif
}

var bundle: Bundle {
    Bundle(identifier: "yip.antonio.BluetoothThing")!
}

var centralId: UUID {
    #if os(iOS)
    return UIDevice.current.identifierForVendor!
    #else
    if let uuidString = UserDefaults.standard.object(forKey: .centralId) as? String,
        let uuid = UUID(uuidString: uuidString) {
        return uuid
    } else {
        let uuid = UUID()
        UserDefaults.standard.set(uuid.uuidString, forKey: .centralId)
        return uuid
    }
    #endif
}
