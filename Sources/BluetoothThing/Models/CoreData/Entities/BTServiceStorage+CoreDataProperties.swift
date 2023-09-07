//
//  BTServiceStorage+CoreDataProperties.swift
//  BluetoothThing
//
//  Created by Antonio Yip on 30/05/20.
//  Copyright © 2020 Antonio Yip. All rights reserved.
//
//

import Foundation
import CoreData


extension BTServiceStorage {

    @NSManaged public var id: String?
    @NSManaged public var name: String?
    @NSManaged public var characteristics: NSSet?
    @NSManaged public var peripheral: BTPeripheralStorage?

}

// MARK: Generated accessors for characteristics
extension BTServiceStorage {

    @objc(addCharacteristicsObject:)
    @NSManaged public func addToCharacteristics(_ value: BTCharacteristicStorage)

    @objc(removeCharacteristicsObject:)
    @NSManaged public func removeFromCharacteristics(_ value: BTCharacteristicStorage)

    @objc(addCharacteristics:)
    @NSManaged public func addToCharacteristics(_ values: NSSet)

    @objc(removeCharacteristics:)
    @NSManaged public func removeFromCharacteristics(_ values: NSSet)

}
