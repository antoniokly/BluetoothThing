//
//  BTCentralStorage+CoreDataProperties.swift
//  BluetoothThing
//
//  Created by Antonio Yip on 30/05/20.
//  Copyright © 2020 Antonio Yip. All rights reserved.
//
//

import Foundation
import CoreData


extension BTCentralStorage {

    @NSManaged public var id: String?
    @NSManaged public var name: String?
    @NSManaged public var discoveries: NSSet?

}

// MARK: Generated accessors for discoveries
extension BTCentralStorage {

    @objc(addDiscoveriesObject:)
    @NSManaged public func addToDiscoveries(_ value: BTDiscoveryStorage)

    @objc(removeDiscoveriesObject:)
    @NSManaged public func removeFromDiscoveries(_ value: BTDiscoveryStorage)

    @objc(addDiscoveries:)
    @NSManaged public func addToDiscoveries(_ values: NSSet)

    @objc(removeDiscoveries:)
    @NSManaged public func removeFromDiscoveries(_ values: NSSet)

}
