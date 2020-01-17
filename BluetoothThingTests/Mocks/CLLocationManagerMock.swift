//
//  CLLocationManagerMock.swift
//  BluetoothThingTests
//
//  Created by Antonio Yip on 13/01/20.
//  Copyright © 2020 Antonio Yip. All rights reserved.
//

import Foundation
import CoreLocation

class CLLocationManagerMock: CLLocationManager {
    private var fakeLocation: CLLocation?
    
    override var desiredAccuracy: CLLocationAccuracy {
        get { kCLLocationAccuracyBest }
        set { }
    }
    
    override var pausesLocationUpdatesAutomatically: Bool {
        get { true }
        set { }
    }
    
    init(fakeLocation location: CLLocation? = nil) {
        super.init()
        self.fakeLocation = location
    }
    
    override func requestLocation() {
        if let location = fakeLocation {
            delegate?.locationManager?(self, didUpdateLocations: [location])
        } else {
            delegate?.locationManager?(self, didFailWithError: NSError())
        }
    }
    
    override func requestAlwaysAuthorization() {
        
    }
    
    override func startMonitoringSignificantLocationChanges() {
        
    }
    
}
