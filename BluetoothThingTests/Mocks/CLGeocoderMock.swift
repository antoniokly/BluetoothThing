//
//  CLGeocoderMock.swift
//  BluetoothThingTests
//
//  Created by Antonio Yip on 13/01/20.
//  Copyright © 2020 Antonio Yip. All rights reserved.
//

import Foundation
import CoreLocation
@testable import BluetoothThing

class CLPlacemarkMock: CLPlacemark {
    var _location: CLLocation? = nil
    
    init(location: CLLocation) {
        super.init()
        _location = location
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var location: CLLocation? {
        return _location
    }
    
    override var locality: String? {
        return "Somewhere"
    }    
}

class CLGeocoderMock: GeocoderProtocol {
    var placemarks: [CLLocation: CLPlacemark] = [:]
    
    func reverseGeocodeLocation(_ location: CLLocation, completionHandler: CLGeocodeCompletionHandler) {
        let placemark = CLPlacemarkMock(location: location)
        placemarks[location] = placemark
        completionHandler([placemark], nil)
    }
}
