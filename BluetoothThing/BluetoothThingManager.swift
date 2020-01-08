//
//  BluetoothThingManager.swift
//  BluetoothThing
//
//  Created by Antonio Yip on 8/01/20.
//  Copyright © 2020 Antonio Yip. All rights reserved.
//

import Foundation
import CoreBluetooth
import CoreLocation
import os.log

let serviceUUIDs: [CBUUID] = []
let characteristicUUIDs: [CBUUID: [CBUUID]] = [:]

public class BluetoothThingManager: NSObject {
    var isPendingForScan = false
    var knownPeripherals: Set<CBPeripheral> = []
    
    var centralManager: CBCentralManager
    
    public init(centralManager: CBCentralManager) {
        self.centralManager = centralManager
    }
    
    func startScanning() {
        guard centralManager.state == .poweredOn else {
            isPendingForScan = true
            return
        }
        
        centralManager.scanForPeripherals(withServices: serviceUUIDs)
        
        if let peripheral = getCurrentPeripheral() {
//            bluetoothWorker.subscribePeripheral(peripheral)
        }
    }
    
    func stopScanning() {
        guard centralManager.state == .poweredOn else {
            isPendingForScan = false
            return
        }
        
        centralManager.stopScan()
        
        if let peripheral = getCurrentPeripheral() {
//            bluetoothWorker.unsubscribePeripheral(peripheral)
        }
    }
    
    func getCurrentPeripheral() -> CBPeripheral? {
//        guard let thing = userData.selectedThing else {
//            return nil
//        }
        
//        return knownPeripherals.first(where: {$0.identifier == thing.id})
        return knownPeripherals.first
    }
}

extension BluetoothThingManager: CBCentralManagerDelegate {
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        /*
         case unknown
         case resetting
         case unsupported
         case unauthorized
         case poweredOff
         case poweredOn
         */
        os_log("centralManagerDidUpdateState: %d", central.state.rawValue)
        
        if central.state == .poweredOn {
            for peripheral in knownPeripherals {
                switch peripheral.state {
                case .connected:
                    peripheral.discoverServices(serviceUUIDs)
                case .connecting:
                    central.connect(peripheral)
                default:
                    break
                }
            }
            
            if isPendingForScan {
                startScanning()
            }
        } else {
            for peripheral in knownPeripherals {
//                bluetoothWorker.updatePeripheral(peripheral)
            }
        }
    }
    
    public func centralManager(_ central: CBCentralManager, willRestoreState dict: [String: Any]) {
        os_log("willRestoreState: %@", dict)
        
        if let peripherals = dict[CBCentralManagerRestoredStatePeripheralsKey] as? [CBPeripheral] {
            knownPeripherals = Set(peripherals)
            for peripheral in peripherals {
//                bluetoothWorker.updatePeripheral(peripheral)
                peripheral.delegate = self
                peripheral.discoverServices(serviceUUIDs)
            }
        } else if let services = dict[CBCentralManagerRestoredStateScanServicesKey] as? [CBUUID] {
            if Set(serviceUUIDs) != Set(services) {
                startScanning()
            }
        }
    }
    
    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        os_log("didDiscover %@ %@ %@", peripheral, advertisementData, RSSI)
//        bluetoothWorker.updatePeripheral(peripheral)
        
        knownPeripherals.insert(peripheral)
        central.connect(peripheral)
    }
    
    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        os_log("didConnect %@", peripheral)
//        bluetoothWorker.updatePeripheral(peripheral)
        
        peripheral.delegate = self
        peripheral.discoverServices(serviceUUIDs)
    }
    
    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        os_log("didDisconnectPeripheral %@", peripheral)
//        bluetoothWorker.updatePeripheral(peripheral)
        central.connect(peripheral)
//        locationManager.requestLocation()
    }
}

extension BluetoothThingManager: CBPeripheralDelegate {
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let services = peripheral.services {
            os_log("didDiscoverServices %@ %@", peripheral, services)
            
            for service in services.filter({characteristicUUIDs.keys.contains($0.uuid)}) {
                peripheral.discoverCharacteristics(characteristicUUIDs[service.uuid],
                                                   for: service)
            }
        }
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let characteristics = service.characteristics {
            os_log("didDiscoverCharacteristicsFor %@ %@", service, characteristics)
            
            for characteristic in characteristics {
                peripheral.readValue(for: characteristic)
                peripheral.setNotifyValue(true, for: characteristic)
            }
        }
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        os_log("didUpdateValueFor %@ %@", peripheral, characteristic)
//        bluetoothWorker.updateCharacteristic(characteristic, of: peripheral)
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        os_log("didUpdateNotificationStateFor %@", characteristic)
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
        os_log("didReadRSSI %d", RSSI)
//        bluetoothWorker.updateRSSI(RSSI, of: peripheral)
    }
}
