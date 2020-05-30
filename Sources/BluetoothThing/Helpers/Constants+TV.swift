//
//  Constants+TV.swift
//  BluetoothThingTV
//
//  Created by Antonio Yip on 21/05/20.
//  Copyright © 2020 Antonio Yip. All rights reserved.
//
#if os(tvOS)
import Foundation
import TVUIKit

var bundle: Bundle {
    Bundle(identifier: "yip.antonio.BluetoothThingTV")!
}

var deviceName: String {
    UIDevice.current.name
}

var centralId: UUID {
    UIDevice.current.identifierForVendor!
}
#if os(watchOS)
