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
            central.id = BluetoothThingManager.centralId.uuidString
            central.name = BluetoothThingManager.deviceName
            os_log("CoreData updated central %@: %@", log: .coreData, type: .debug, central.id!, central.name!)
        } else {
            let central = BTCentral(context: self.managedObjectContext!)
            os_log("CoreData created central", log: .coreData, type: .debug)
            self.central = central
            self.insertCentral()
        }
    }
}
