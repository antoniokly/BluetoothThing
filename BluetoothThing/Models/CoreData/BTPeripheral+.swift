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
        guard let discoveries = self.discoveries as? Set<BTDiscovery>, let discovery = discoveries.first(where: {$0.centralId == centralId.uuidString}), let peripheralId = discovery.peripheralId else {
            return nil
        }
        
        return UUID(uuidString: peripheralId)
    }
    
    func insertDiscovery(centralId: UUID, peripheralId: UUID) {
        if let set = self.discoveries as? Set<BTDiscovery>, let discovery = set.first(where: {$0.centralId == centralId.uuidString}) {
            discovery.setValue(peripheralId.uuidString,
                               forKey: .peripheralId)
            os_log("CoreData updated discovery %@: %@", centralId.uuidString, String(describing: peripheralId.uuidString))
        } else {
            let entity = NSEntityDescription.entity(forEntityName: "BTDiscovery", in: self.managedObjectContext!)!
                                
            let discovery = NSManagedObject(entity: entity, insertInto: self.managedObjectContext!) as! BTDiscovery
            
            discovery.peripheral = self
            discovery.centralId = centralId.uuidString
            self.addToDiscoveries(discovery)
            os_log("CoreData created discovery")
            
            self.insertDiscovery(centralId: centralId, peripheralId: peripheralId)
        }
    }
    
    func isRegistered(centralId: UUID) -> Bool {
        guard let set = self.discoveries as? Set<BTDiscovery> else {
            return false
        }
        
        return set.contains(where: {$0.centralId == centralId.uuidString})
    }
}
