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
        
//        For future develop
//        let model = "BTModel"
//        let modelURL = bundle.url(forResource: model, withExtension: "momd")!
//        let managedObjectModel = NSManagedObjectModel(contentsOf: modelURL)!
        
        let model = BTModel.self
        let managedObjectModel = NSManagedObjectModel(modelDescription: model.modelDescription)
        
        if #available(iOS 13.0, watchOS 6.0, macOS 10.15, tvOS 13.0, *), useCloudKit {
            container = NSPersistentCloudKitContainer(name: model.name, managedObjectModel: managedObjectModel)
        } else {
            container = NSPersistentContainer(name: model.name, managedObjectModel: managedObjectModel)
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
                os_log("loadPersistentStores error: %@", log: .storage, type: .error, error.localizedDescription)
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
                os_log("save error: %@", log: .storage, type: .error, error.localizedDescription)
            }
        }
    }
    
    func fetchEntities<Entity>(predicate: NSPredicate? = nil) -> [Entity] where Entity: NSManagedObject {
        let fetchRequest = NSFetchRequest<Entity>(entityName: String(describing: Entity.self))
        fetchRequest.predicate = predicate
        
        var entities: [Entity] = []
        
        do {
            entities = try persistentContainer.viewContext.fetch(fetchRequest)
            os_log("fetched %@: %@", log: .storage, type: .debug, String(describing: Entity.self), entities)
        } catch {
            os_log("fetch error: %@", log: .storage, type: .error, error.localizedDescription)
        }

        return entities
    }
}

extension CoreDataStore: PersistentStoreProtocol {
    
    func fetch() -> Any? {
        return fetch(forCentralId: BluetoothThingManager.centralId)
    }
    
    func fetch(forCentralId centralId: UUID) -> Any? {
        let periperals: [BTPeripheralStorage] = fetchEntities()

        return periperals.compactMap({ entity in
            guard let peripheralId = entity.peripheralId(for: centralId) else {
                return nil
            }
          
            let thing = BluetoothThing(id: peripheralId, name: entity.name)
            
            for data in entity.customData as! Set<BTCustomDataStorage> {
                thing.customData[data.key!] = data.value
            }
            
            for service in entity.services as! Set<BTServiceStorage> {
                for characteristic in service.characteristics as! Set<BTCharacteristicStorage> {
                    thing.setCharateristic(BTCharacteristic(service: service.id!, characteristic: characteristic.id!), value: characteristic.value)
                }
            }
            
            return thing
            
        }) as [BluetoothThing]
    }
    
    func reset() {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: String(describing: BTPeripheralStorage.self))
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)

        do {
            try persistentContainer.viewContext.execute(deleteRequest)
        } catch  {
            os_log("delete error: %@", log: .storage, type: .error, error.localizedDescription)
        }
    }

    func save(context: Any?) {
        saveContext()
    }
    
    func addObject(context: Any?, object: Any?) {
        guard let thing = object as? BluetoothThing, let hardwareId = thing.hardwareSerialNumber else {
            return
        }
        
        let peripherals: [BTPeripheralStorage] = fetchEntities()
        var peripheral: BTPeripheralStorage
        
        if let entity = peripherals.first(where: {$0.id == thing.id.uuidString || $0.hardwareId == hardwareId}) {
            os_log("Periperal with hardwareId: %@ exists", log: .storage, type: .debug, hardwareId)
            peripheral = entity
        } else {
            peripheral = BTPeripheralStorage(context: persistentContainer.viewContext)
            peripheral.setValuesForKeys([
                .id: thing.id.uuidString,
                .name: thing.name as Any
            ])
            
            os_log("Created an BTPeripheral", log: .storage, type: .debug)
            
            update(context: context, object: thing, keyValues: [
                String.customData: thing.customData,
                String.characteristics: thing.characteristics
            ])
        }
                
        peripheral.insertDiscovery(centralId: BluetoothThingManager.centralId)
        saveContext()
    }
    
    func removeObject(context: Any?, object: Any?) {
        guard let thing = object as? BluetoothThing else {
            return
        }
        
        let peripheral: BTPeripheralStorage? = fetchEntities(
            predicate: NSPredicate(format: "id == %@", thing.id.uuidString)
        ).first
        
        let central: BTCentralStorage? = fetchEntities(
            predicate: NSPredicate(format: "id == %@", BluetoothThingManager.centralId.uuidString)
        ).first
        
        guard let peripheralId = peripheral?.id, let centralId = central?.id else {
            os_log("No discovery found", log: .storage, type: .debug)
            return
        }
        
        let discoveries: [BTDiscoveryStorage] = fetchEntities(predicate:
            NSPredicate(format: "central.id == %@ AND peripheral.id == %@", centralId, peripheralId)
        )

        for discovery in discoveries {
            persistentContainer.viewContext.delete(discovery)
            os_log("Removed discovery: %@", log: .storage, type: .debug, discovery.debugDescription)
        }
    }
    
    func update(context: Any?, object: Any?, keyValues: [AnyHashable : Any]?) {
        guard
            let thing = object as? BluetoothThing,
            let keyValues = keyValues as? [String: Any] else {
            return
        }

        let peripherals : [BTPeripheralStorage] = fetchEntities(predicate:
            NSPredicate(format: "id == %@", thing.id.uuidString)
        )
        
        guard let peripheral = peripherals.first else {
            os_log("CoreData cannot found peripheral for %@", log: .storage, type: .debug, thing)
            return
        }        
        
        for (key, value) in keyValues {
            switch key {
            case .customData:
                if let dict = value as? [String: Data] {
                    peripheral.insertCustomData(dict)
                }
            case .characteristics:
                if let characteristics = value as? [BTCharacteristic: Data] {
                    peripheral.insertCharacteristics(characteristics)
                }
            default:
                peripheral.setValue(value, forKey: key)
                os_log("Updated %@: %@", log: .storage, type: .debug, key, String(describing: value))
            }
        }
    }
}
