//
//  BTPeripheral+.swift
//  BluetoothThing
//
//  Created by Antonio Yip on 6/03/20.
//  Copyright © 2020 Antonio Yip. All rights reserved.
//

import Foundation
import CoreData
import CoreBluetooth
import  os.log

extension BTPeripheral {
    var hardwareId: String? {
        let serialNumber = BTCharacteristic.serialNumber
        
        guard let services = self.services as? Set<GATTService>,
            let service = services.first(where: {$0.id == serialNumber.serviceUUID.uuidString}),
            let characteristics = service.characteristics as? Set<GATTCharacteristic>,
            let characteristic = characteristics.first(where: {$0.id == serialNumber.uuid.uuidString}),
            let data = characteristic.value else {
            return nil
        }
        
        return String(data: data, encoding: .utf8)
    }
    
    func peripheralId(for centralId: UUID) -> UUID? {
        guard let discoveries = self.discoveries as? Set<BTDiscovery>, let discovery = discoveries.first(where: {$0.central?.id == centralId.uuidString}), let peripheralId = discovery.peripheral?.id else {
            return nil
        }
        
        return UUID(uuidString: peripheralId)
    }
    
    func insertDiscovery(centralId: UUID) {
        if let set = self.discoveries as? Set<BTDiscovery>, let discovery = set.first(where: {$0.central?.id == centralId.uuidString}) {
            discovery.peripheral = self
            os_log("updated discovery central: %@, peripheral: %@", log: .storage, type: .debug, centralId.uuidString, String(describing: self.id))
        } else {
            let discovery = BTDiscovery(context: self.managedObjectContext!) 
            discovery.insertCentral()
            self.addToDiscoveries(discovery)
            os_log("created discovery %@", log: .storage, type: .debug, discovery.debugDescription)
            self.insertDiscovery(centralId: centralId)
        }
    }
    
    func insertCustomData(_ dictionary: [String: Any]) {
        for (key, value) in dictionary {
            if let set = self.customData as? Set<CustomData>, let customData = set.first(where: {$0.key == key}) {
                customData.setValuesForKeys([
                    .value: value,
                    .modifiedAt: Date()
                ])
                os_log("Updated customData %@: %@", log: .storage, type: .debug, key, String(describing: value))
            } else {
                let customData = CustomData(context: self.managedObjectContext!)
                customData.peripheral = self
                customData.key = key
                self.addToCustomData(customData)
                os_log("Created customData", log: .storage, type: .debug)
                self.insertCustomData(dictionary)
            }
        }
    }
    
    func insertGATTService(_ serviceUUID: CBUUID) -> GATTService {
        if let services = self.services as? Set<GATTService>, let service = services.first(where: {$0.id == serviceUUID.uuidString}) {
            return service
        }
        
        let service = GATTService(context: self.managedObjectContext!)
        service.peripheral = self
        service.id = serviceUUID.uuidString
        service.name = serviceUUID.description
        self.addToServices(service)
        os_log("Created GATTService", log: .storage, type: .debug)
        return service
    }
    
    func insertCharacteristics(_ data: [BTCharacteristic: Data]) {
        for (key, value) in data {
            let serviceUUID = key.serviceUUID
            let characteristicUUID = key.uuid
            let service = insertGATTService(serviceUUID)
            service.setValue(for: characteristicUUID, value: value)
        }
    }
}
