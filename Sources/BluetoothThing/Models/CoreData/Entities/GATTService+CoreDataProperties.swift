//
//  GATTService+CoreDataProperties.swift
//  BluetoothThing
//
//  Created by Antonio Yip on 30/05/20.
//  Copyright © 2020 Antonio Yip. All rights reserved.
//
//

import Foundation
import CoreData


extension GATTService {

    @NSManaged public var id: String?
    @NSManaged public var name: String?
    @NSManaged public var characteristics: NSSet?
    @NSManaged public var peripheral: BTPeripheral?

}

// MARK: Generated accessors for characteristics
extension GATTService {

    @objc(addCharacteristicsObject:)
    @NSManaged public func addToCharacteristics(_ value: GATTCharacteristic)

    @objc(removeCharacteristicsObject:)
    @NSManaged public func removeFromCharacteristics(_ value: GATTCharacteristic)

    @objc(addCharacteristics:)
    @NSManaged public func addToCharacteristics(_ values: NSSet)

    @objc(removeCharacteristics:)
    @NSManaged public func removeFromCharacteristics(_ values: NSSet)

}
