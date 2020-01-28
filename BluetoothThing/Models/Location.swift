//
//  Location.swift
//  BluetoothThing
//
//  Created by Antonio Yip on 9/01/20.
//  Copyright © 2020 Antonio Yip. All rights reserved.
//

import Foundation
import CoreLocation


public struct Location: Hashable, Codable {
    public var latitude: Double
    public var longitude: Double
    public var timestamp: Date
    public var name: String?
    
    public var cooridinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude,
                               longitude: longitude)
    }
    
    public init(location: CLLocation) {
        self.latitude = location.coordinate.latitude
        self.longitude = location.coordinate.longitude
        self.timestamp = location.timestamp
    }
    
    public init(coordinate: CLLocationCoordinate2D, date: Date = Date()) {
        self.latitude = coordinate.latitude
        self.longitude = coordinate.longitude
        self.timestamp = date
    }
}
