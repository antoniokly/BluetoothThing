//
//  BTPeripheral+.swift
//  BluetoothThing
//
//  Created by Antonio Yip on 6/03/20.
//  Copyright © 2020 Antonio Yip. All rights reserved.
//

import Foundation
import CoreData
import  os.log

extension BTPeripheral {
    
    func peripheralId(for centralId: UUID) -> UUID? {
        guard let discoveries = self.discoveries as? Set<BTDiscovery>, let discovery = discoveries.first(where: {$0.central?.id == centralId.uuidString}), let peripheralId = discovery.peripheral?.id else {
            return nil
        }
        
        return UUID(uuidString: peripheralId)
    }
    
    func insertDiscovery(centralId: UUID) {
        if let set = self.discoveries as? Set<BTDiscovery>, let discovery = set.first(where: {$0.central?.id == centralId.uuidString}) {
            discovery.peripheral = self
            os_log("updated discovery central: %@, peripheral: %@", centralId.uuidString, String(describing: self.id))
        } else {
            let discovery: BTDiscovery = NSManagedObject.createEntity(in: self.managedObjectContext!)
            discovery.insertCentral()
            self.addToDiscoveries(discovery)
            os_log("created discovery %@", discovery.debugDescription)
            self.insertDiscovery(centralId: centralId)
        }
    }
    
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
}
