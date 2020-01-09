//
//  Location.swift
//  BluetoothThing
//
//  Created by Antonio Yip on 9/01/20.
//  Copyright © 2020 Antonio Yip. All rights reserved.
//

import Foundation
import CoreLocation

struct Cooridinate: Hashable, Codable {
    var latitude: Double
    var longitude: Double
}

public struct Location: Hashable, Codable {
    var cooridinate: Cooridinate
    var updated: Date
    var name: String?
}
