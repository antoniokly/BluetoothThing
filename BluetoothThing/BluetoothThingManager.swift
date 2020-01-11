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

public class BluetoothThingManager: NSObject {
    var delegate: BluetoothThingManagerDelegate
    var subscriptions: [Subscription]
        
    var dataStore: DataStoreInterface!
    var centralManager: CBCentralManager!
    
    var serviceUUIDs: [CBUUID] {
        return [CBUUID](Set(subscriptions.map({$0.serviceUUID})))
    }
        
    var isPendingToStart = false
    var knownPeripherals: Set<CBPeripheral> = []
    
    static let centralManagerOptions = [
        CBCentralManagerOptionRestoreIdentifierKey: Bundle.main.bundleIdentifier!
    ]

    public init(delegate: BluetoothThingManagerDelegate,
         subscriptions: [Subscription],
         dataStore: DataStoreInterface? = nil,
         centralManager: CBCentralManager? = nil
         ) {
               self.delegate = delegate
        self.subscriptions = subscriptions
        super.init()
        self.dataStore = dataStore ?? DataStore(storeKey: Bundle.main.bundleIdentifier!)
        self.centralManager = centralManager ?? CBCentralManager(delegate: self,
                                                                 queue: nil,
                                                                 options: Self.centralManagerOptions)
    }
    
    public func start() {
        guard centralManager.state == .poweredOn else {
            isPendingToStart = true
            return
        }
        
        isPendingToStart = false
        centralManager.scanForPeripherals(withServices: serviceUUIDs, options: nil)
        
        for peripheral in knownPeripherals {
            peripheral.subscribe(subscriptions: subscriptions)
        }
    }
    
    public func stop() {
        isPendingToStart = false

        guard centralManager.state == .poweredOn else {
            return
        }
        
        centralManager.stopScan()
        
        for peripheral in knownPeripherals {
            peripheral.unsubscribe(subscriptions: subscriptions)
        }
    }
    
//    public func performAction(_ action: String, with data: Data?, on thing: BluetoothThingProtocol) {
//
//    }
    //MARK: - BluetoothThing
    func didUpdatePeripheral(_ peripheral: CBPeripheral) {
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
    
    func didUpdateRSSI(_ rssi: NSNumber?, for peripheral: CBPeripheral) {
        let thing = dataStore.getThing(id: peripheral.identifier)
        delegate.bluetoothThing(thing, didChangeRSSI: rssi)
    }
    
    func didUpdateCharacteristic(_ characteristic: CBCharacteristic, for peripheral: CBPeripheral) {
        let thing = dataStore.getThing(id: peripheral.identifier)
        if thing.updateData(with: characteristic) {
            delegate.bluetoothThing(thing, didChangeCharacteristic: characteristic)
            dataStore.save()
        }
    }
}

//MARK: - CBCentralManagerDelegate
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
            
            if isPendingToStart {
                start()
            }
        } else {
            for peripheral in knownPeripherals {
                didUpdatePeripheral(peripheral)
            }
        }
    }
    
    public func centralManager(_ central: CBCentralManager, willRestoreState dict: [String: Any]) {
        os_log("willRestoreState: %@", dict)
        
        if let peripherals = dict[CBCentralManagerRestoredStatePeripheralsKey] as? [CBPeripheral] {
            knownPeripherals = Set(peripherals)
            for peripheral in peripherals {
                didUpdatePeripheral(peripheral)
                peripheral.delegate = self
                
                if peripheral.state == .connected {
                    peripheral.discoverServices(serviceUUIDs)
                }
            }
        }
        
        if let services = dict[CBCentralManagerRestoredStateScanServicesKey] as? [CBUUID] {
            if Set(serviceUUIDs) != Set(services) {
                start()
            }
        }
    }
    
    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        os_log("didDiscover %@ %@ %@", peripheral, advertisementData, RSSI)
        didUpdatePeripheral(peripheral)
        didUpdateRSSI(RSSI, for: peripheral)
        knownPeripherals.insert(peripheral)
        central.connect(peripheral)
    }
    
    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        os_log("didConnect %@", peripheral)
        didUpdatePeripheral(peripheral)
        
        peripheral.delegate = self
        peripheral.discoverServices(serviceUUIDs)
    }
    
    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        os_log("didDisconnectPeripheral %@", peripheral)
        didUpdatePeripheral(peripheral)
        central.connect(peripheral)
//        locationManager.requestLocation()
    }
}

//MARK: - CBPeripheralDelegate
extension BluetoothThingManager: CBPeripheralDelegate {
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let services = peripheral.services {
            os_log("didDiscoverServices %@ %@", peripheral, services)
            
            for service in services {
                let uuids = subscriptions.filter {
                    $0.serviceUUID == service.uuid
                }.map {
                    $0.characteristicUUID
                }
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
        didUpdateCharacteristic(characteristic, for: peripheral)
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        os_log("didUpdateNotificationStateFor %@", characteristic)
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
        os_log("didReadRSSI %d", RSSI)
        didUpdateRSSI(RSSI, for: peripheral)
    }
}
