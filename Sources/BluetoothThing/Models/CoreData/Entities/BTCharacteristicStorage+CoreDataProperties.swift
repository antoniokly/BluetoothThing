//
//  BTCharacteristicStorage+CoreDataProperties.swift
//  BluetoothThing
//
//  Created by Antonio Yip on 30/05/20.
//  Copyright © 2020 Antonio Yip. All rights reserved.
//
//

import Foundation
import CoreData


extension BTCharacteristicStorage {

    @NSManaged public var id: String?
    @NSManaged public var name: String?
    @NSManaged public var value: Data?
    @NSManaged public var service: BTServiceStorage?

}
