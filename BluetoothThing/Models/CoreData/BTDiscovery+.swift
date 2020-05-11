//
//  BTDiscovery+.swift
//  BluetoothThing
//
//  Created by Antonio Yip on 11/05/20.
//  Copyright © 2020 Antonio Yip. All rights reserved.
//

import Foundation
import CoreData
import os.log

extension BTDiscovery {
    func insertCentral() {
        if let central = self.central {
            central.id = centralId.uuidString
            central.name = deviceName
            os_log("CoreData updated central %@: %@", centralId.uuidString, deviceName)
        } else {
            let central: BTCentral = NSManagedObject.createEntity(in: self.managedObjectContext!)
            os_log("CoreData created central")
            self.central = central
            self.insertCentral()
        }
    }
}
