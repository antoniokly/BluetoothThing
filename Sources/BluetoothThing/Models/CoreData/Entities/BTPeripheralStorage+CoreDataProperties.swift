//
//  BTPeripheralStorage+CoreDataProperties.swift
//  BluetoothThing
//
//  Created by Antonio Yip on 30/05/20.
//  Copyright © 2020 Antonio Yip. All rights reserved.
//
//

import Foundation
import CoreData


extension BTPeripheralStorage {

    @NSManaged public var id: String?
    @NSManaged public var name: String?
    @NSManaged public var customData: NSSet?
    @NSManaged public var discoveries: NSSet?
    @NSManaged public var services: NSSet?

}

// MARK: Generated accessors for customData
extension BTPeripheralStorage {

    @objc(addCustomDataObject:)
    @NSManaged public func addToCustomData(_ value: BTCustomDataStorage)

    @objc(removeCustomDataObject:)
    @NSManaged public func removeFromCustomData(_ value: BTCustomDataStorage)

    @objc(addCustomData:)
    @NSManaged public func addToCustomData(_ values: NSSet)

    @objc(removeCustomData:)
    @NSManaged public func removeFromCustomData(_ values: NSSet)

}

// MARK: Generated accessors for discoveries
extension BTPeripheralStorage {

    @objc(addDiscoveriesObject:)
    @NSManaged public func addToDiscoveries(_ value: BTDiscoveryStorage)

    @objc(removeDiscoveriesObject:)
    @NSManaged public func removeFromDiscoveries(_ value: BTDiscoveryStorage)

    @objc(addDiscoveries:)
    @NSManaged public func addToDiscoveries(_ values: NSSet)

    @objc(removeDiscoveries:)
    @NSManaged public func removeFromDiscoveries(_ values: NSSet)

}

// MARK: Generated accessors for services
extension BTPeripheralStorage {

    @objc(addServicesObject:)
    @NSManaged public func addToServices(_ value: BTServiceStorage)

    @objc(removeServicesObject:)
    @NSManaged public func removeFromServices(_ value: BTServiceStorage)

    @objc(addServices:)
    @NSManaged public func addToServices(_ values: NSSet)

    @objc(removeServices:)
    @NSManaged public func removeFromServices(_ values: NSSet)

}
