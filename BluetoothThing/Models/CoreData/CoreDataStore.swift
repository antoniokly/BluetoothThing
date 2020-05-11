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
        let model = "BTModel"
        
        let modelURL = bundle.url(forResource: model, withExtension: "momd")!
        let managedObjectModel =  NSManagedObjectModel(contentsOf: modelURL)!
        
        if #available(iOS 13.0, watchOS 6.0, *), useCloudKit {
            container = NSPersistentCloudKitContainer(name: model, managedObjectModel: managedObjectModel)
        } else {
            container = NSPersistentContainer(name: model, managedObjectModel: managedObjectModel)
        }
                
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error {
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                os_log("loadPersistentStores error: %@", error.localizedDescription)
            }
        })
        return container
    }()
    
    init() {
    }
    
    @available(iOS 13.0, watchOS 6.0, *)
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
                os_log("save error: %@", error.localizedDescription)
            }
        }
    }
    
    func fetchEntities<Entity>(predicate: NSPredicate? = nil) -> [Entity] where Entity: NSManagedObject {
        let fetchRequest = NSFetchRequest<Entity>(entityName: String(describing: Entity.self))
        fetchRequest.predicate = predicate
        
        var entities: [Entity] = []
        
        do {
            entities = try persistentContainer.viewContext.fetch(fetchRequest)
            os_log("fetched %@: %@", String(describing: Entity.self), entities)
        } catch {
            os_log("fetch error: %@", error.localizedDescription)
        }

        return entities
    }
}

extension CoreDataStore: PersistentStoreProtocol {
    
    func fetch() -> Any? {
        return fetch(forCentralId: centralId)
    }
    
    func fetch(forCentralId centralId: UUID) -> Any? {
        let periperals: [BTPeripheral] = fetchEntities()

        return periperals.compactMap({ entity in
            guard let peripheralId = entity.peripheralId(for: centralId) else {
                return nil
            }
          
            let thing = BluetoothThing(id: peripheralId, name: entity.name)
            
            for data in entity.customData as! Set<CustomData> {
                thing.customData[data.key!] = data.value
            }
            
            for service in entity.services as! Set<GATTService> {
                for characteristic in service.characteristics as! Set<GATTCharacteristic> {
                    thing.characteristics[BTCharacteristic(service: service.id!, characteristic: characteristic.id!)] = characteristic.value
                }
            }
            
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
        guard let thing = object as? BluetoothThing, let hardwareId = thing.hardwareSerialNumber else {
            return
        }
        
        let peripherals: [BTPeripheral] = fetchEntities()
        var peripheral: BTPeripheral
        
        if let entity = peripherals.first(where: {$0.id == thing.id.uuidString || $0.hardwareId == hardwareId}) {
            os_log("Periperal with hardwareId: %@ exists", hardwareId)
            peripheral = entity
        } else {
            peripheral = NSManagedObject.createEntity(in: persistentContainer.viewContext)
            peripheral.setValuesForKeys([
                .id: thing.id.uuidString,
                .name: thing.name as Any
            ])
            
            os_log("Created an BTPeripheral")
            
            update(context: context, object: thing, keyValues: [
                String.customData: thing.customData,
                String.characteristics: thing.characteristics
            ])
        }
                
        peripheral.insertDiscovery(centralId: centralId)
        saveContext()
    }
    
    func removeObject(context: Any?, object: Any?) {
        guard let thing = object as? BluetoothThing else {
            return
        }
        
        let peripheral: BTPeripheral? = fetchEntities(
            predicate: NSPredicate(format: "id == %@", thing.id.uuidString)
        ).first
        
        let central: BTCentral? = fetchEntities(
            predicate: NSPredicate(format: "id == %@", centralId.uuidString)
        ).first
        
        guard let peripheralId = peripheral?.id, let centralId = central?.id else {
            os_log("No discovery found")
            return
        }
        
        let discoveries: [BTDiscovery] = fetchEntities(predicate:
            NSPredicate(format: "central.id == %@ AND peripheral.id == %@", centralId, peripheralId)
        )

        for discovery in discoveries {
            persistentContainer.viewContext.delete(discovery)
            os_log("Removed discovery: %@", discovery.debugDescription)
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
        
        guard let btPeripheral = try? persistentContainer.viewContext.fetch(fetchRequest).first else {
            os_log("CoreData cannot found peripheral for %@", thing)
            return
        }
        
        for (key, value) in keyValues {
            switch key {
            case .customData:
                if let dict = value as? [String: Data] {
                    for (key, value) in dict {
                        if let set = btPeripheral.customData as? Set<CustomData>, let customData = set.first(where: {$0.key == key}) {
                            customData.setValuesForKeys([
                                .value: value,
                                .modifiedAt: Date()
                            ])
                            os_log("Updated customData %@: %@", key, String(describing: value))
                        } else {
                            let customData: CustomData = NSManagedObject.createEntity(in: persistentContainer.viewContext)
                            
                            customData.peripheral = btPeripheral
                            customData.key = key
                            btPeripheral.addToCustomData(customData)
                            os_log("Created customData")

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
                                
                                os_log("Updated GATTCharacteristic %@: %@", characteristic.uuid.uuidString, String(describing: value))

                            } else {
                                let gattChar: GATTCharacteristic = NSManagedObject.createEntity(in: persistentContainer.viewContext)
                                
                                gattChar.service = gattService
                                gattChar.id = characteristic.uuid.uuidString
                                gattChar.name = characteristic.uuid.description
                                gattService.addToCharacteristics(gattChar)
                                os_log("Created GATTCharacteristic")
                                
                                update(context: context, object: object, keyValues: keyValues)
                            }
                            
                        } else {
                            let gattService: GATTService = NSManagedObject.createEntity(in: persistentContainer.viewContext)
                            
                            gattService.peripheral = btPeripheral
                            gattService.id = characteristic.serviceUUID.uuidString
                            gattService.name = characteristic.serviceUUID.description
                            btPeripheral.addToServices(gattService)
                            os_log("Created GATTService")
                            
                            update(context: context, object: object, keyValues: keyValues)
                        }
                    }
                }
            default:
                btPeripheral.setValue(value, forKey: key)
                os_log("Updated %@: %@", key, String(describing: value))
            }
        }
    }
}
