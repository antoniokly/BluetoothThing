//
//  Entity.swift
//  BluetoothThing
//
//  Created by Antonio Yip on 28/02/20.
//  Copyright © 2020 Antonio Yip. All rights reserved.
//

import Foundation
import CoreData
import os.log

protocol Entity {
    associatedtype EntityType: NSManagedObject
}

extension Entity {
    public static func fetch(id: String) -> EntityType? {
        let fetchRequest = EntityType.fetchRequest() as! NSFetchRequest<EntityType>
        fetchRequest.predicate = NSPredicate(format: "id == %@", id)
        return try? CoreDataStore.default.persistentContainer.viewContext.fetch(fetchRequest).first
    }
    
    public static func create(keyValues: [String: Any]) -> EntityType {
        let context = CoreDataStore.default.persistentContainer.viewContext
        
        let entity = NSEntityDescription.entity(forEntityName: "BTHardware", in: context)!
                            
        let object = NSManagedObject(entity: entity, insertInto: context) as! EntityType
        
        for (key, value) in keyValues {
            object.setValue(value, forKeyPath: key)
        }
        
        do {
            try context.save()
        } catch {
            os_log("save error: %@", error.localizedDescription)
        }
        
        return object
    }
}

