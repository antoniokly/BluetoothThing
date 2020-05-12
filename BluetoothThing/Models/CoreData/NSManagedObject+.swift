//
//  NSManagedObject+.swift
//  BluetoothThing
//
//  Created by Antonio Yip on 11/05/20.
//  Copyright © 2020 Antonio Yip. All rights reserved.
//

import Foundation
import CoreData
import os.log

public extension NSManagedObject {
    static func createEntity<Entity>(in context: NSManagedObjectContext) -> Entity where Entity: NSManagedObject {
        let entityDescription = NSEntityDescription.entity(forEntityName: String(describing: Entity.self), in: context)!
        os_log("CoreData created %@", String(describing: Entity.self))
        return NSManagedObject(entity: entityDescription, insertInto: context) as! Entity
    }
}
