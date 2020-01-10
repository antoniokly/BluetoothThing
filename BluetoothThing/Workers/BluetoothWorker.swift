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
    var subscriptions: [CharacteristicProtocol] { get }

//    func subscribedServiceUUIDs(for peripheral: PeripheralProtocol) -> [CBUUID]
//    func subscribedCharateristics(for service: ServiceProtocol) -> [CharacteristicProtocol]
    
    func didUpdatePeripheral(_ peripheral: PeripheralProtocol)
    func didUpdateCharacteristic(_ characteristic: CharacteristicProtocol, for peripheral: PeripheralProtocol)
    func didUpdateRSSI(_ rssi: NSNumber?, for peripheral: PeripheralProtocol)
    
    func subscribePeripheral(_ peripheral: PeripheralProtocol)
    func unsubscribePeripheral(_ peripheral: PeripheralProtocol)
}

extension BluetoothWorkerInterface {
    func subscribePeripheral(_ peripheral: PeripheralProtocol) {
        for characteristic in subscribedCharateristics(for: peripheral) {
            peripheral.setNotifyValue(true, for: characteristic)
        }
    }
   
    func unsubscribePeripheral(_ peripheral: PeripheralProtocol) {
        for characteristic in subscribedCharateristics(for: peripheral) {
            peripheral.setNotifyValue(false, for: characteristic)
        }
    }
    
    func subscribedServiceUUIDs(for peripheral: PeripheralProtocol) -> [CBUUID] {
        return [CBUUID](Set(subscriptions.map({$0.serviceUUID})))
    }
    
    func subscribedCharateristics(for service: ServiceProtocol) -> [CharacteristicProtocol] {
        return subscriptions.filter {
            self.shouldSubscribe(characteristic: $0)
        }
    }
    
    func shouldSubscribe(characteristic: CharacteristicProtocol) -> Bool {
        if subscriptions.contains(where: {
            $0.serviceUUID == characteristic.serviceUUID &&
                $0.uuid == characteristic.uuid}) {
            return true
        }
        
        return false
    }
    
    private func subscribedCharateristics(for peripheral: PeripheralProtocol) -> [CBCharacteristic] {
        guard let services = peripheral.services else {
            return []
        }
        
        return services.flatMap {
            $0.characteristics ?? []
        }.filter {
            self.shouldSubscribe(characteristic: $0)
        }
    }
}

class BluetoothWorker: BluetoothWorkerInterface {
    var delegate: BluetoothThingManagerDelegate
    var dataStore: DataStoreInterface = DataStore(storeKey: Bundle.main.bundleIdentifier!)
    var subscriptions: [CharacteristicProtocol]
    
    init(delegate: BluetoothThingManagerDelegate, subscriptions: [CharacteristicProtocol]) {
        self.delegate = delegate
        self.subscriptions = subscriptions
    }
    
    func didUpdatePeripheral(_ peripheral: PeripheralProtocol) {
        let thing = dataStore.getThing(id: peripheral.identifier)
        if thing.name == nil {
            thing.name = peripheral.name
            dataStore.save()
        }
        if thing.state != peripheral.state {
            thing.state = peripheral.state
            delegate.bluetoothThing(thing, didChangeState: thing.state)
        }
    }
    
    func didUpdateCharacteristic(_ characteristic: CharacteristicProtocol, for peripheral: PeripheralProtocol) {
        let thing = dataStore.getThing(id: peripheral.identifier)
        if updateCharacteristic(characteristic, for: thing) {
            delegate.bluetoothThing(thing, didChangeCharacteristic: characteristic)
            dataStore.save()
        }
    }
    
    func didUpdateRSSI(_ rssi: NSNumber?, for peripheral: PeripheralProtocol) {
        let thing = dataStore.getThing(id: peripheral.identifier)
        delegate.bluetoothThing(thing, didChangeRSSI: rssi)
    }
    
    private func updateCharacteristic(_ characteristic: CharacteristicProtocol, for thing: BluetoothThing) -> Bool {
        let serviceID = characteristic.serviceUUID.uuidString
        let key = characteristic.uuid.uuidString
        var didChange = false
        
        var storage = thing.data[serviceID] ?? [:]
        
        if storage[key] != characteristic.value {
            didChange = true
        }
        
        if let data = characteristic.value {
            storage[key] = data
        } else {
            storage.removeValue(forKey: key)
        }
        
        thing.data[serviceID] = storage
        
        return didChange
    }
}
