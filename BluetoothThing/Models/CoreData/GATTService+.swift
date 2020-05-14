//
//  GATTService+.swift
//  BluetoothThing
//
//  Created by Antonio Yip on 11/05/20.
//  Copyright © 2020 Antonio Yip. All rights reserved.
//

import Foundation
import CoreData
import CoreBluetooth
import os.log

extension GATTService {
    func setValue(for characteristicUUID: CBUUID, value: Data?) {
        if let characteristics = self.characteristics as? Set<GATTCharacteristic>, let characteristic = characteristics.first(where: {$0.id == characteristicUUID.uuidString}) {
            characteristic.value = value
            os_log("Updated GATTCharacteristic %@: %@", characteristicUUID.uuidString, String(describing: value))
        } else {
            let characteristic = GATTCharacteristic(context: self.managedObjectContext!)
            characteristic.service = self
            characteristic.id = characteristicUUID.uuidString
            characteristic.name = characteristicUUID.description
            self.addToCharacteristics(characteristic)
            os_log("Created GATTCharacteristic")
            self.setValue(for: characteristicUUID, value: value)
        }
    }
}
