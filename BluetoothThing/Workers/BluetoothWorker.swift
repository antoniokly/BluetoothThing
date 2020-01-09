//
//  BluetoothWorker.swift
//  BluetoothThing
//
//  Created by Antonio Yip on 9/01/20.
//  Copyright © 2020 Antonio Yip. All rights reserved.
//

import Foundation
import CoreBluetooth

protocol BluetoothWorkerInterface {
    func didUpdatePeripheral(_ peripheral: Peripheral)
    func didUpdateCharacteristic(_ characteristic: Characteristic, for peripheral: Peripheral)
    func didUpdateRSSI(_ rssi: NSNumber?, for peripheral: Peripheral)
    
    func subscribePeripheral(_ peripheral: Peripheral)
    func unsubscribePeripheral(_ peripheral: Peripheral)
}

class BluetoothWorker: BluetoothWorkerInterface {
    var dataStore: DataStore = DataStore(storeKey: Bundle.main.bundleIdentifier!)
    
    func didUpdatePeripheral(_ peripheral: Peripheral) {
        let thing = dataStore.getThing(id: peripheral.identifier)
        thing.state = peripheral.state
        thing.name = peripheral.name
        dataStore.save()
    }
    
    func didUpdateCharacteristic(_ characteristic: Characteristic, for peripheral: Peripheral) {
        let thing = dataStore.getThing(id: peripheral.identifier)
        updateCharacteristic(characteristic, for: thing)
        dataStore.save()
    }
    
    func didUpdateRSSI(_ rssi: NSNumber?, for peripheral: Peripheral) {
        let thing = dataStore.getThing(id: peripheral.identifier)
        thing.rssi = rssi as? Int
        dataStore.save()
    }
    
    func subscribePeripheral(_ peripheral: Peripheral) {
        for characteristic in getSubscribedCharacteristic(of: peripheral) {
            peripheral.setNotifyValue(true, for: characteristic)
        }
    }
    
    func unsubscribePeripheral(_ peripheral: Peripheral) {
        for characteristic in getSubscribedCharacteristic(of: peripheral) {
            peripheral.setNotifyValue(false, for: characteristic)
        }
    }
    
    func getSubscribedCharacteristic(of peripheral: Peripheral) -> [CBCharacteristic] {
        guard let services = peripheral.services?.filter({serviceUUIDs.contains($0.uuid)}) else {
            return []
        }
        
        return services.flatMap { (service) -> [CBCharacteristic] in
            let serviceUUID = service.uuid
            guard let uuids = characteristicUUIDs[serviceUUID], let characteristics = service.characteristics?.filter({uuids.contains($0.uuid)}) else {
                return []
            }
            
            return characteristics
        }
    }
    
    func updateCharacteristic(_ characteristic: Characteristic, for thing: BluetoothThing) {
        let serviceID = characteristic.serviceID.uuidString
        let key = characteristic.uuid.uuidString
        
        var storage = thing.data[serviceID] ?? [:]
        
        if let data = characteristic.value {
            storage[key] = data
        } else {
            storage.removeValue(forKey: key)
        }
        
        thing.data[serviceID] = storage
    }
}
