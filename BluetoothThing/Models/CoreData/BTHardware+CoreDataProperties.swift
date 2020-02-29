//
//  BTHardware+CoreDataProperties.swift
//  BluetoothThing
//
//  Created by Antonio Yip on 28/02/20.
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
    @NSManaged public var lastConnected: Date?
    @NSManaged public var lastConnectedBy: String?
    @NSManaged public var lastDisconnected: Date?
    @NSManaged public var services: NSSet?
    @NSManaged public var peripheral: BTPeripheral?

}

// MARK: Generated accessors for services
extension BTHardware {

    @objc(addServicesObject:)
    @NSManaged public func addToServices(_ value: GATTService)

    @objc(removeServicesObject:)
    @NSManaged public func removeFromServices(_ value: GATTService)

    @objc(addServices:)
    @NSManaged public func addToServices(_ values: NSSet)

    @objc(removeServices:)
    @NSManaged public func removeFromServices(_ values: NSSet)

}
