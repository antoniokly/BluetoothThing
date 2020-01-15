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
    public internal (set) var delegate: BluetoothThingManagerDelegate
    public internal (set) var subscriptions: [Subscription]
        
    public internal (set) var dataStore: DataStoreProtocol!
    var centralManager: CBCentralManager!
    var locationManager: CLLocationManager?
    var geocoder: GeocoderProtocol?

    var userLocation: CLLocation?
    
    var serviceUUIDs: [CBUUID] {
        return [CBUUID](Set(subscriptions.map({$0.serviceUUID})))
    }
    
    var things: [BluetoothThing] {
        return dataStore.things
    }
        
    var isPendingToStart = false
    var knownPeripherals: Set<CBPeripheral> = []
    
    static let centralManagerOptions = [
        CBCentralManagerOptionRestoreIdentifierKey: Bundle.main.bundleIdentifier!
    ]
    
    static let peripheralOptions: [String: Any]? = nil

    public init(delegate: BluetoothThingManagerDelegate,
         subscriptions: [Subscription],
         dataStore: DataStoreProtocol? = nil,
         centralManager: CBCentralManager? = nil,
         useLocation: Bool = false
         ) {
               self.delegate = delegate
        self.subscriptions = subscriptions
        super.init()
        
        self.dataStore = dataStore ?? DataStore()
        self.centralManager = centralManager ?? CBCentralManager(delegate: self,
                                                                 queue: nil,
                                                                 options: Self.centralManagerOptions)
        
        if useLocation {
            let manager = CLLocationManager()
            self.locationManager = manager

            manager.delegate = self
            manager.requestAlwaysAuthorization()
            manager.desiredAccuracy = kCLLocationAccuracyBest
            manager.pausesLocationUpdatesAutomatically = true
            manager.startMonitoringSignificantLocationChanges()
        }
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
    
    //MARK: - BluetoothThing
    @discardableResult
    func didUpdatePeripheral(_ peripheral: CBPeripheral, rssi: NSNumber? = nil) -> BluetoothThing? {
        guard let thing = dataStore.getThing(id: peripheral.identifier) else {
            return nil
        }
        
        if thing.name == nil {
            thing.name = peripheral.name
        }
        
        if thing.state != peripheral.state {
            thing.state = peripheral.state
            
            if thing.state == .connected {
                thing.lastConnected = Date()
            } else if thing.state == .disconnected {
                thing.lastDisconnected = Date()
            }
            
            delegate.bluetoothThing(thing, didChangeState: thing.state)
        }
        
        if let rssi = rssi {
            delegate.bluetoothThing(thing, didChangeRSSI: rssi)
        }
        
        return thing
    }
    
    @discardableResult
    func didUpdateCharacteristic(_ characteristic: CBCharacteristic, for peripheral: CBPeripheral) -> BluetoothThing?  {
        guard let thing = dataStore.getThing(id: peripheral.identifier) else {
            return nil
        }
        
        if thing.updateData(with: characteristic) {
            delegate.bluetoothThing(thing, didChangeCharacteristic: characteristic)
        }
        
        return thing
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
                didUpdatePeripheral(peripheral)

                if didUpdatePeripheral(peripheral) != nil {
                    switch peripheral.state {
                    case .connected:
                        peripheral.readRSSI()
                        peripheral.discoverServices(serviceUUIDs)
                    default:
                        central.connect(peripheral, options: Self.peripheralOptions)
                        break
                    }
                } else {
                    central.cancelPeripheralConnection(peripheral)
                }
               
                locationManager?.requestLocation()
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
        knownPeripherals.insert(peripheral)
        peripheral.delegate = self
        
        guard let advertisedServiceUUIDs = advertisementData[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID] else {
            return
        }
        
        if Set(advertisedServiceUUIDs).isDisjoint(with: serviceUUIDs) {
            return
        }
        
        if let _ = didUpdatePeripheral(peripheral, rssi: RSSI) {
            central.connect(peripheral, options: Self.peripheralOptions)
        } else {
            let newThing = BluetoothThing(id: peripheral.identifier)
            newThing.name = peripheral.name
            delegate.bluetoothThingManager(self, didFoundThing: newThing, rssi: RSSI, handler: { connect in
                if connect {
                    self.dataStore.addThing(id: peripheral.identifier)
                    central.connect(peripheral, options: Self.peripheralOptions)
                }
            })
        }
    }
    
    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        os_log("didConnect %@", peripheral)
        didUpdatePeripheral(peripheral)

        peripheral.readRSSI()
        peripheral.discoverServices(serviceUUIDs)
        locationManager?.requestLocation()
    }
    
    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        os_log("didDisconnectPeripheral %@", peripheral)
                
        if didUpdatePeripheral(peripheral) != nil {
            central.connect(peripheral, options: Self.peripheralOptions)
        }
    }
}

//MARK: - CBPeripheralDelegate
extension BluetoothThingManager: CBPeripheralDelegate {
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let services = peripheral.services {
            os_log("didDiscoverServices %@ %@", peripheral, services)
            for service in services {
                guard serviceUUIDs.contains(service.uuid) else {
                    continue
                }
                
                let uuids = subscriptions.filter {
                    $0.serviceUUID == service.uuid
                }.map {
                    $0.characteristicUUID
                }
                //TODO: Test not to discover unsuscribed uuids
                peripheral.discoverCharacteristics(uuids, for: service)
            }
        }
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let characteristics = service.characteristics {
            os_log("didDiscoverCharacteristicsFor %@ %@", service, characteristics)
            
            for characteristic in characteristics {
                peripheral.setNotifyValue(true, for: characteristic)
                peripheral.readValue(for: characteristic)
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
        os_log("didReadRSSI %d", RSSI.stringValue)
        didUpdatePeripheral(peripheral, rssi: RSSI)
    }
}

//MARK: - CLLocationManagerDelegate
extension BluetoothThingManager: CLLocationManagerDelegate {
    
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        os_log("didUpdateLocations: %@", locations)
        
        guard let updated = locations.sorted(by: { $0.timestamp > $1.timestamp }).first else {
            return
        }
        
        if let last = userLocation, last.timestamp > updated.timestamp {
            return
        }
        
        userLocation = updated
        fetchPlacemarks(updated)
    }
    
    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        os_log("didFailWithError: %@", error.localizedDescription)
    }
    
    func fetchPlacemarks(_ location: CLLocation) {
        (geocoder ?? CLGeocoder()).reverseGeocodeLocation(location) { placemarks, error in
            if let error = error  {
                os_log("fetchPlacemarks error: %@", error.localizedDescription)
            }
            
            let nearbyThings = self.knownPeripherals.filter {
                $0.state != .disconnected
            }.compactMap {
                self.dataStore.getThing(id: $0.identifier)
            }
                
            for thing in nearbyThings {
                var loc = Location(location: location)
                loc.name = placemarks?.first?.locality
                thing.location = loc
                self.delegate.bluetoothThing(thing, didUpdateLocation: loc)
            }
        }
    }
}
