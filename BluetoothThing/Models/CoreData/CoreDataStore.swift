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
    private var useCloudKit = false
    
    // MARK: - Core Data stack
    lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
         */
        
        let container: NSPersistentContainer
        #if os(watchOS)
        let bundle = Bundle(identifier: "yip.antonio.BluetoothThingWatch")!
        #else
        let bundle = Bundle(identifier: "yip.antonio.BluetoothThing")!
        #endif
        let model = "BTModel"
        
        let modelURL = bundle.url(forResource: model, withExtension: "momd")!
        let managedObjectModel =  NSManagedObjectModel(contentsOf: modelURL)!
        
        if #available(iOS 13.0, *), useCloudKit {
            container = NSPersistentCloudKitContainer(name: model, managedObjectModel: managedObjectModel)
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
    
    init() {
    }
    
    @available(iOS 13.0, *)
    init(useCloudKit: Bool) {
        self.useCloudKit = useCloudKit
    }
    
    // MARK: - Core Data Saving support
    func saveContext() {
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
        
}

extension CoreDataStore: PersistentStoreProtocol {
    
    func fetch() -> Any? {
        let context = persistentContainer.viewContext

        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "BTPeripheral")
         
        var entities: [BTPeripheral] = []
        
        do {
            entities = try context.fetch(fetchRequest) as! [BTPeripheral]
            os_log("fetched BTPeripherals: %@", entities)//.map({$0.id}))
         } catch {
            os_log("fetch error: %@", error.localizedDescription)
         }

        return entities.compactMap({ entity in
            guard let id = entity.id, let uuid = UUID(uuidString: id) else {
                return nil
            }
            
            let thing = BluetoothThing(id: uuid, name: entity.name)
            
            if let data = entity.location {
                thing.location = try? JSONDecoder().decode(Location.self, from: data)
            }
            
            for data in entity.customData as! Set<CustomData> {
                thing.customData[data.key!] = data.value
            }
            
            for service in entity.services as! Set<GATTService> {
                for characteristic in service.characteristics as! Set<GATTCharacteristic> {
                    thing.characteristics[BTCharacteristic(service: service.id!, characteristic: characteristic.id!)] = characteristic.value
                }
            }
            
            thing.isRegistered = entity.isRegistered

            return thing
            
        }) as [BluetoothThing]
    }
    
    func reset() {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "BTPeripheral")
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)

        do {
            try persistentContainer.viewContext.execute(deleteRequest)
        } catch  {
            os_log("delete error: %@", error.localizedDescription)
        }
    }

    func save(context: Any?) {
        saveContext()
    }
    
    func addObject(context: Any?, object: Any?) {
        guard let thing = object as? BluetoothThing else {
            return
        }
        
        let entity = NSEntityDescription.entity(forEntityName: "BTPeripheral", in: persistentContainer.viewContext)!
                            
        let btPeripheral = NSManagedObject(entity: entity, insertInto: persistentContainer.viewContext) as! BTPeripheral
        
        btPeripheral.setValuesForKeys([
            .id: thing.id.uuidString,
            .name: thing.name as Any
        ])
        os_log("CoreData added an BTPeripheral")
    }
    
    func removeObject(context: Any?, object: Any?) {
        guard let thing = object as? BluetoothThing else {
            return
        }
        
        let fetchRequest: NSFetchRequest<BTPeripheral> = BTPeripheral.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", thing.id.uuidString)
        
        if let btPeripheral = try? persistentContainer.viewContext.fetch(fetchRequest).first {
            persistentContainer.viewContext.delete(btPeripheral)
            os_log("CoreData removed an BTPeripheral")
        }
    }
    
    func update(context: Any?, object: Any?, keyValues: [AnyHashable : Any]?) {
        guard
            let thing = object as? BluetoothThing,
            let keyValues = keyValues as? [String: Any] else {
            return
        }

        let fetchRequest: NSFetchRequest<BTPeripheral> = BTPeripheral.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", thing.id.uuidString)
        
        if let btPeripheral = try? persistentContainer.viewContext.fetch(fetchRequest).first {
            
            for (key, value) in keyValues {
                switch key {
                case .location:
                    if let location = value as? Location {
                        btPeripheral.setValue(try? JSONEncoder().encode(location), forKey: key)
                        
                        os_log("CoreData updated location")
                    }
                case .customData:
                    if let dict = value as? [String: Data] {
                        for (key, value) in dict {
                            if let set = btPeripheral.customData as? Set<CustomData>, let customData = set.first(where: {$0.key == key}) {
                                customData.setValuesForKeys([
                                    .value: value,
                                    .modifiedAt: Date()
                                ])
                                os_log("CoreData updated customData %@: %@", key, String(describing: value))
                            } else {
                                let entity = NSEntityDescription.entity(forEntityName: "CustomData", in: persistentContainer.viewContext)!
                                                    
                                let customData = NSManagedObject(entity: entity, insertInto: persistentContainer.viewContext) as! CustomData
                                
                                customData.peripheral = btPeripheral
                                customData.key = key
                                btPeripheral.addToCustomData(customData)
                                os_log("CoreData created customData")

                                update(context: context, object: object, keyValues: keyValues)
                            }
                        }
                    }
                case .characteristics:
                    if let characteristics = value as? [BTCharacteristic: Data] {
                        for (characteristic, value) in characteristics {
                            if let set = btPeripheral.services as? Set<GATTService>, let gattService = set.first(where: {$0.id == characteristic.serviceUUID.uuidString}) {
                                
                                if let set = gattService.characteristics as? Set<GATTCharacteristic>, let gattChar = set.first(where: {$0.id == characteristic.uuid.uuidString}) {
                                    gattChar.value = value
                                    
                                    os_log("CoreData updated GATTCharacteristic %@: %@", characteristic.uuid.uuidString, String(describing: value))

                                } else {
                                    let entity = NSEntityDescription.entity(forEntityName: "GATTCharacteristic", in: persistentContainer.viewContext)!
                                                        
                                    let gattChar = NSManagedObject(entity: entity, insertInto: persistentContainer.viewContext) as! GATTCharacteristic
                                    
                                    gattChar.service = gattService
                                    gattChar.id = characteristic.uuid.uuidString
                                    gattChar.name = characteristic.uuid.description
                                    gattService.addToCharacteristics(gattChar)
                                    os_log("CoreData created GATTCharacteristic")
                                    
                                    update(context: context, object: object, keyValues: keyValues)
                                }
                                
                            } else {
                                let entity = NSEntityDescription.entity(forEntityName: "GATTService", in: persistentContainer.viewContext)!
                                                    
                                let service = NSManagedObject(entity: entity, insertInto: persistentContainer.viewContext) as! GATTService
                                
                                service.peripheral = btPeripheral
                                service.id = characteristic.serviceUUID.uuidString
                                service.name = characteristic.serviceUUID.description
                                btPeripheral.addToServices(service)
                                os_log("CoreData created GATTService")
                                
                                update(context: context, object: object, keyValues: keyValues)
                            }
                        }
                    }
                default:
                    btPeripheral.setValue(value, forKey: key)
                    os_log("CoreData updated %@: %@", key, String(describing: value))
                }
            }
        } else {
            let entity = NSEntityDescription.entity(forEntityName: "BTPeripheral", in: persistentContainer.viewContext)!
                                
            let btPeripheral = NSManagedObject(entity: entity, insertInto: persistentContainer.viewContext) as! BTPeripheral
            
            btPeripheral.setValuesForKeys([
                .id: thing.id.uuidString,
                .name: thing.name as Any
            ])
            os_log("CoreData created BTPeripheral")

            update(context: context, object: object, keyValues: keyValues)
        }
    }
}
