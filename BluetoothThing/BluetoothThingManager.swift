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

public class BluetoothThingManager: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    var bluetoothWorker: BluetoothWorkerInterface
    var centralManager: CBCentralManager!
    var subscriptions: [CharacteristicProtocol]
    var serviceUUIDs: [CBUUID] {
        return [CBUUID](Set(subscriptions.map({$0.serviceUUID})))
    }
        
    private var isPendingToStart = false
    private var knownPeripherals: Set<CBPeripheral> = []
    
    public init(delegate: BluetoothThingManagerDelegate, subscriptions: [CharacteristicProtocol]) {
        self.subscriptions = subscriptions
        self.bluetoothWorker = BluetoothWorker(delegate: delegate, subscriptions: subscriptions)
        super.init()
        self.centralManager =
            CBCentralManager(delegate: self,
                             queue: nil,
                             options: [CBCentralManagerOptionRestoreIdentifierKey: Bundle.main.bundleIdentifier!])
    }
    
    public func start() {
        guard centralManager.state == .poweredOn else {
            isPendingToStart = true
            return
        }
        
        centralManager.scanForPeripherals(withServices: serviceUUIDs)
        
        for peripheral in knownPeripherals {
            bluetoothWorker.subscribePeripheral(peripheral)
        }
    }
    
    public func stop() {
        guard centralManager.state == .poweredOn else {
            isPendingToStart = false
            return
        }
        
        centralManager.stopScan()
        
        for peripheral in knownPeripherals {
            bluetoothWorker.unsubscribePeripheral(peripheral)
        }
    }
    
//    public func performAction(_ action: String, with data: Data?, on thing: BluetoothThingProtocol) {
//
//    }

    //MARK: - CBCentralManagerDelegate
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
            
            if isPendingToStart {
                start()
            }
        } else {
            for peripheral in knownPeripherals {
                bluetoothWorker.didUpdatePeripheral(peripheral)
            }
        }
    }
    
    public func centralManager(_ central: CBCentralManager, willRestoreState dict: [String: Any]) {
        os_log("willRestoreState: %@", dict)
        
        if let peripherals = dict[CBCentralManagerRestoredStatePeripheralsKey] as? [CBPeripheral] {
            knownPeripherals = Set(peripherals)
            for peripheral in peripherals {
                bluetoothWorker.didUpdatePeripheral(peripheral)
                peripheral.delegate = self
                
                if peripheral.state == .connected {
                    peripheral.discoverServices(serviceUUIDs)
                }
            }
        } else if let services = dict[CBCentralManagerRestoredStateScanServicesKey] as? [CBUUID] {
            if Set(serviceUUIDs) != Set(services) {
                start()
            }
        }
    }
    
    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        os_log("didDiscover %@ %@ %@", peripheral, advertisementData, RSSI)
        bluetoothWorker.didUpdatePeripheral(peripheral)
        bluetoothWorker.didUpdateRSSI(RSSI, for: peripheral)
        knownPeripherals.insert(peripheral)
        central.connect(peripheral)
    }
    
    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        os_log("didConnect %@", peripheral)
        bluetoothWorker.didUpdatePeripheral(peripheral)
        
        peripheral.delegate = self
        peripheral.discoverServices(serviceUUIDs)
    }
    
    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        os_log("didDisconnectPeripheral %@", peripheral)
        bluetoothWorker.didUpdatePeripheral(peripheral)
        central.connect(peripheral)
//        locationManager.requestLocation()
    }

    //MARK: - CBPeripheralDelegate
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let services = peripheral.services {
            os_log("didDiscoverServices %@ %@", peripheral, services)
            
            for service in services {
                let uuids = bluetoothWorker.subscribedCharateristics(for: service).map{$0.uuid}
                peripheral.discoverCharacteristics(uuids, for: service)
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
        bluetoothWorker.didUpdateCharacteristic(characteristic, for: peripheral)
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        os_log("didUpdateNotificationStateFor %@", characteristic)
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
        os_log("didReadRSSI %d", RSSI)
        bluetoothWorker.didUpdateRSSI(RSSI, for: peripheral)
    }
}
