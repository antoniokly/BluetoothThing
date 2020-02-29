//
//  BTPeripheral+CoreDataProperties.swift
//  BluetoothThing
//
//  Created by Antonio Yip on 28/02/20.
//  Copyright © 2020 Antonio Yip. All rights reserved.
//
//

import Foundation
import CoreData


extension BTPeripheral {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<BTPeripheral> {
        return NSFetchRequest<BTPeripheral>(entityName: "BTPeripheral")
    }

    @NSManaged public var id: String?
    @NSManaged public var lastFound: Date?
    @NSManaged public var lastFoundBy: String?
    @NSManaged public var name: String?
    @NSManaged public var hardware: BTHardware?

}
