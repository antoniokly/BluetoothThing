//
//  BTPeripheral+CoreDataClass.swift
//  BluetoothThing
//
//  Created by Antonio Yip on 28/02/20.
//  Copyright © 2020 Antonio Yip. All rights reserved.
//
//

import Foundation
import CoreData
import os.log

@objc(BTPeripheral)
public class BTPeripheral: NSManagedObject {
}

extension BTPeripheral{
    public static func fetch(id: String) -> BTPeripheral? {
        let fetchRequest: NSFetchRequest<BTPeripheral> = BTPeripheral.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", id)
        return try? CoreDataStore.default.persistentContainer.viewContext.fetch(fetchRequest).first
    }
    
    public static func create(keyValues: [String: Any]) -> BTPeripheral {
        let context = CoreDataStore.default.persistentContainer.viewContext
        
        let entity = NSEntityDescription.entity(forEntityName: "BTPeripheral", in: context)!
                            
        let object = NSManagedObject(entity: entity, insertInto: context) as! BTPeripheral
        
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
