//
//  CoreDataStore.swift
//  BluetoothThing
//
//  Created by Antonio Yip on 26/02/20.
//  Copyright © 2020 Antonio Yip. All rights reserved.
//

import Foundation
import CoreData
import CloudKit
import os.log

class CoreDataStore {
    var hardwares: [BTHardware] = []
    
    var useCloudKit = false
    
    // MARK: - Core Data stack
    lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
         */
        
        let container: NSPersistentContainer
        
        let bundle = Bundle(identifier: "yip.antonio.BluetoothThing")!
        let model = "BTHardwareModel"
        
        let modelURL = bundle.url(forResource: model, withExtension: "momd")!
        let managedObjectModel =  NSManagedObjectModel(contentsOf: modelURL)!
        
        if #available(iOS 13.0, *), useCloudKit {
            container = NSPersistentCloudKitContainer(name: "BTHardwareModel")
        } else {
            container = NSPersistentContainer(name: model, managedObjectModel: managedObjectModel)
        }
        
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()
    
    // MARK: - Core Data Saving support
    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
    
    @available(iOS 13.0, *)
    convenience init(useCloudKit: Bool = false) {
        self.init()
        self.useCloudKit = useCloudKit
    }
    
    init() {
        let context = persistentContainer.viewContext

        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "BTHardware")
         
        do {
            hardwares = try context.fetch(fetchRequest) as! [BTHardware]
            os_log("fetched hardwares %@", hardwares.map({$0.id}))
         } catch {
            os_log("fetch error: %@", error.localizedDescription)
         }
    }
    
    func getBTHardware(peripheralId: UUID) -> BTHardware? {
        return hardwares.first(where: {$0.peripheralId == peripheralId.uuidString})
    }
    
    func getBTHardware(hardwareId: String) -> BTHardware? {
        let context = persistentContainer.viewContext

        if let hardware = hardwares.first(where: {$0.id == hardwareId}) {
            return hardware
        } else {
            let entity = NSEntityDescription.entity(forEntityName: "BTHardware",
                                                             in: context)!
                                
            let hardware = NSManagedObject(entity: entity,
                                           insertInto: context) as! BTHardware
            
            hardware.setValue(hardwareId, forKeyPath: "id")
            
            do {
                try context.save()
                hardwares.append(hardware)
            } catch {
                os_log("save error: %@", error.localizedDescription)
            }
            
            return hardware
            
        }
                    
    }
    
    
}

