//
//  BTHardware+CoreDataProperties.swift
//  BluetoothThing
//
//  Created by Antonio Yip on 27/02/20.
//  Copyright © 2020 Antonio Yip. All rights reserved.
//
//

import Foundation
import CoreData


extension BTHardware {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<BTHardware> {
        return NSFetchRequest<BTHardware>(entityName: "BTHardware")
    }

    @NSManaged public var displayName: String?
    @NSManaged public var id: String?
    @NSManaged public var image: Data?
    @NSManaged public var location: Data?
    @NSManaged public var peripheralId: String?

}
