//
//  BTPeripheral+CoreDataProperties.swift
//  BluetoothThing
//
//  Created by Antonio Yip on 2/08/20.
//
//

import Foundation
import CoreData


extension BTPeripheral {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<BTPeripheral> {
        return NSFetchRequest<BTPeripheral>(entityName: "BTPeripheral")
    }

    @NSManaged public var id: String?
    @NSManaged public var name: String?
    @NSManaged public var autoReconnect: Bool
    @NSManaged public var customData: NSSet?
    @NSManaged public var discoveries: NSSet?
    @NSManaged public var services: NSSet?

}

// MARK: Generated accessors for customData
extension BTPeripheral {

    @objc(addCustomDataObject:)
    @NSManaged public func addToCustomData(_ value: CustomData)

    @objc(removeCustomDataObject:)
    @NSManaged public func removeFromCustomData(_ value: CustomData)

    @objc(addCustomData:)
    @NSManaged public func addToCustomData(_ values: NSSet)

    @objc(removeCustomData:)
    @NSManaged public func removeFromCustomData(_ values: NSSet)

}

// MARK: Generated accessors for discoveries
extension BTPeripheral {

    @objc(addDiscoveriesObject:)
    @NSManaged public func addToDiscoveries(_ value: BTDiscovery)

    @objc(removeDiscoveriesObject:)
    @NSManaged public func removeFromDiscoveries(_ value: BTDiscovery)

    @objc(addDiscoveries:)
    @NSManaged public func addToDiscoveries(_ values: NSSet)

    @objc(removeDiscoveries:)
    @NSManaged public func removeFromDiscoveries(_ values: NSSet)

}

// MARK: Generated accessors for services
extension BTPeripheral {

    @objc(addServicesObject:)
    @NSManaged public func addToServices(_ value: GATTService)

    @objc(removeServicesObject:)
    @NSManaged public func removeFromServices(_ value: GATTService)

    @objc(addServices:)
    @NSManaged public func addToServices(_ values: NSSet)

    @objc(removeServices:)
    @NSManaged public func removeFromServices(_ values: NSSet)

}
