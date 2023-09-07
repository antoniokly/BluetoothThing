//
//  BTCustomDataStorage+CoreDataProperties.swift
//  BluetoothThing
//
//  Created by Antonio Yip on 30/05/20.
//  Copyright © 2020 Antonio Yip. All rights reserved.
//
//

import Foundation
import CoreData


extension BTCustomDataStorage {

    @NSManaged public var key: String?
    @NSManaged public var modifiedAt: Date?
    @NSManaged public var value: Data?
    @NSManaged public var peripheral: BTPeripheralStorage?

}
