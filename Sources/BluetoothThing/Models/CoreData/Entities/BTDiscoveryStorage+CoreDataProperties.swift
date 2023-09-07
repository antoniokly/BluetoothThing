//
//  BTDiscoveryStorage+CoreDataProperties.swift
//  BluetoothThing
//
//  Created by Antonio Yip on 30/05/20.
//  Copyright © 2020 Antonio Yip. All rights reserved.
//
//

import Foundation
import CoreData


extension BTDiscoveryStorage {

    @NSManaged public var lastConnected: Date?
    @NSManaged public var lastDisconnected: Date?
    @NSManaged public var lastFound: Date?
    @NSManaged public var central: BTCentralStorage?
    @NSManaged public var peripheral: BTPeripheralStorage?

}
