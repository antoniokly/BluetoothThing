//
//  NSEntityDescription+.swift
//  BluetoothThing
//
//  Created by Antonio Yip on 11/05/20.
//  Copyright © 2020 Antonio Yip. All rights reserved.
//

import Foundation
import CoreData
import os.log

extension NSManagedObject {
    static func createEntity<Entity>(in context: NSManagedObjectContext) -> Entity where Entity: NSManagedObject {
        guard let entityDescription = NSEntityDescription.entity(forEntityName: String(describing: Entity.self), in: context) else {
            fatalError("Unknow entity in context")
        }
        guard let entity = NSManagedObject(entity: entityDescription, insertInto: context) as? Entity else {
            fatalError("Cannot create entity")
        }
        os_log("CoreData created %@", String(describing: Entity.self))
        return entity
    }
}
