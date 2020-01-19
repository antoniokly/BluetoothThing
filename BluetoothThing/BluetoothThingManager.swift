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
    static let centralManagerOptions: [String: Any]? = [
        CBCentralManagerOptionRestoreIdentifierKey: Bundle.main.bundleIdentifier!
    ]
    
    static let peripheralOptions: [String: Any]? = nil
    
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
    var scanningOptions: [String: Any]?
    var loseThingAfterTimeInterval: TimeInterval = 10
    
    var allowDuplicates: Bool {
        scanningOptions?[CBCentralManagerScanOptionAllowDuplicatesKey] as? Bool == true
    }
    
    var knownPeripherals: Set<CBPeripheral> = []
    var knownThings: Set<BluetoothThing> = []
        
    var deregisteringThings: [UUID: BluetoothThing] = [:]
        
    public convenience init(delegate: BluetoothThingManagerDelegate,
                            subscriptions: [Subscription],
                            dataStore: DataStoreProtocol? = nil,
                            centralManager: CBCentralManager? = nil,
                            useLocation: Bool = false) {
        self.init(delegate: delegate, subscriptions: subscriptions)        
        self.dataStore = dataStore ?? DataStore()
        
        self.centralManager = centralManager ??
            CBCentralManager(delegate: self, queue: nil, options: Self.centralManagerOptions)
        
        if useLocation {
            setupLocationManager(CLLocationManager())
        }
        
        NotificationCenter.default.addObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: nil) { _ in
            self.startScanning(allowDuplicates: true)
        }
        
        NotificationCenter.default.addObserver(forName: UIApplication.didEnterBackgroundNotification, object: nil, queue: nil) { _ in
            self.stopScanning()
        }
    }
    
    init(delegate: BluetoothThingManagerDelegate, subscriptions: [Subscription]) {
        self.delegate = delegate
        self.subscriptions = subscriptions
        super.init()
    }
    
    func setupLocationManager(_ manager: CLLocationManager) {
        self.locationManager = manager
        manager.delegate = self
        manager.requestAlwaysAuthorization()
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.pausesLocationUpdatesAutomatically = true
        manager.startMonitoringSignificantLocationChanges()
    }
    
    public func startScanning(allowDuplicates: Bool) {
        let options = [
            CBCentralManagerScanOptionAllowDuplicatesKey: allowDuplicates
        ]
        
        startScanning(options: options)
    }
    
    func startScanning(options: [String: Any]?) {
        scanningOptions = options
        
        if centralManager.state == .poweredOn {
            isPendingToStart = false
            
            if allowDuplicates {
                for thing in knownThings.filter({$0.state == .disconnected && !$0.isRegistered}) {
                    delegate.bluetoothThingManager(self, didLoseThing: thing)
                }
            }
            
            os_log("start scanning", serviceUUIDs)
            centralManager.scanForPeripherals(withServices: serviceUUIDs, options: options)
        } else {
            isPendingToStart = true
        }
    }
    
    public func stopScanning() {
        isPendingToStart = false

        guard centralManager.state == .poweredOn else {
            return
        }
        
        os_log("stop scanning")
        centralManager.stopScan()
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
            
            delegate.bluetoothThing(thing, didChangeState: peripheral.state)
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
        
        let subscription = Subscription(characteristic: characteristic)
        delegate.bluetoothThing(thing, didUpdateValue: characteristic.value, for: subscription)
        
        if thing.data[subscription] != characteristic.value {
            thing.data[subscription] = characteristic.value
            dataStore.saveThing(thing)
        }
                
        return thing
    }
    
    func loseThing(_ thing: BluetoothThing) {
        os_log("didLoseThing %@", thing.name ?? thing.id.uuidString)
        
        thing.timer?.invalidate()
        thing.timer = nil
        
        self.delegate.bluetoothThingManager(self, didLoseThing: thing)
    }
    
    func registerThing(_ thing: BluetoothThing, peripheral: CBPeripheral) {
        thing.isRegistered = true
        thing.timer?.invalidate()
        thing.timer = nil
        
        dataStore.addThing(thing)
        centralManager.connect(peripheral, options: Self.peripheralOptions)
        delegate.bluetoothThing(thing, didChangeState: peripheral.state)
    }
    
    func deregisterThing(_ thing: BluetoothThing, peripheral: CBPeripheral) {
        thing.isRegistered = false
        deregisteringThings[peripheral.identifier] = thing
        dataStore.removeThing(id: peripheral.identifier)
        centralManager.cancelPeripheralConnection(peripheral)
        delegate.bluetoothThing(thing, didChangeState: peripheral.state)
    }
    
    func didConnectThing(_ thing: BluetoothThing, peripheral: CBPeripheral) {
        peripheral.readRSSI()
        peripheral.discoverServices(serviceUUIDs)
        
        // MARK: Disconnect request
        thing.deregister = { [weak self, weak peripheral, weak thing] in
            guard let peripheral = peripheral, let thing = thing else {
                return
            }
            self?.deregisterThing(thing, peripheral: peripheral)
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
                if let thing = didUpdatePeripheral(peripheral) {
                    switch peripheral.state {
                    case .connected:
                        didConnectThing(thing, peripheral: peripheral)
                    default:
                        central.connect(peripheral, options: Self.peripheralOptions)
                    }
                } else {
                    central.cancelPeripheralConnection(peripheral)
                }
               
                locationManager?.requestLocation()
            }
            
            if isPendingToStart {
                startScanning(options: scanningOptions)
            }
        } else {
            for peripheral in knownPeripherals {
                didUpdatePeripheral(peripheral)
            }
            
            for thing in knownThings.filter({$0.state == .disconnected && !$0.isRegistered}) {
                delegate.bluetoothThingManager(self, didLoseThing: thing)
            }
            
            startScanning(options: scanningOptions)
        }
    }
    
    public func centralManager(_ central: CBCentralManager, willRestoreState dict: [String: Any]) {
        os_log("willRestoreState: %@", dict)
        
        if let peripherals = dict[CBCentralManagerRestoredStatePeripheralsKey] as? [CBPeripheral] {
            knownPeripherals = Set(peripherals)
            
            for peripheral in peripherals {
                peripheral.delegate = self
                didUpdatePeripheral(peripheral)
            }
        }
        
        if let services = dict[CBCentralManagerRestoredStateScanServicesKey] as? [CBUUID] {
            if Set(serviceUUIDs) != Set(services) {
                startScanning(options: scanningOptions)
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
            var foundThing: BluetoothThing
            
            if let thing = knownThings.first(where: {$0.id == peripheral.identifier}) {
                foundThing = thing
            } else {
                let newThing = BluetoothThing(id: peripheral.identifier)
                newThing.name = peripheral.name

                // MARK: Connect request
                newThing.register = { [weak self, weak peripheral, weak newThing] in
                    guard let peripheral = peripheral, let thing = newThing else {
                        return
                    }
                    self?.registerThing(thing, peripheral: peripheral)
                }
                
                knownThings.insert(newThing)
                foundThing = newThing
            }
            
            foundThing.timer?.invalidate()
            foundThing.timer = nil
            
            if allowDuplicates {
                foundThing.timer = Timer.scheduledTimer(
                    withTimeInterval: loseThingAfterTimeInterval,
                    repeats: false,
                    block: { [weak self, weak foundThing] timer in
                        guard let thing = foundThing else { return }
                        self?.loseThing(thing)
                    }
                )
            }
            
            delegate.bluetoothThingManager(self, didFoundThing: foundThing, rssi: RSSI)
        }
    }
    
    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        os_log("didConnect %@", peripheral)
        if let thing = didUpdatePeripheral(peripheral){
            thing.timer?.invalidate()
            thing.timer = nil
            
            didConnectThing(thing, peripheral: peripheral)
        }
        
        locationManager?.requestLocation()
    }
    
    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        os_log("didDisconnectPeripheral %@", peripheral)
        
        if didUpdatePeripheral(peripheral) != nil {
            // reconnect if lost connection unintentionally
            central.connect(peripheral, options: Self.peripheralOptions)
        } else {
            if let thing = deregisteringThings.removeValue(forKey: peripheral.identifier) {
                thing.state = peripheral.state
                delegate.bluetoothThing(thing, didChangeState: peripheral.state)
            }
        }
    }
    
    public func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        os_log("didFailToConnect %@", peripheral)

        if let thing = didUpdatePeripheral(peripheral) {
            delegate.bluetoothThingManager(self, didFailToConnect: thing, error: error)
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
                
                peripheral.discoverCharacteristics(uuids, for: service)
            }
        }
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let characteristics = service.characteristics {
            os_log("didDiscoverCharacteristicsFor %@ %@", service, characteristics)
            
            for characteristic in characteristics {
                if !characteristic.isNotifying {
                    peripheral.setNotifyValue(true, for: characteristic)
                }
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
        
        for location in locations {
            if let last = userLocation, last.timestamp > location.timestamp {
                return
            }
            
            userLocation = location
            fetchPlacemarks(location)
        }
    }
    
    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        os_log("didFailWithError: %@", error.localizedDescription)
        delegate.bluetoothThingManager(self, locationDidFailWithError: error)
    }
    
    func fetchPlacemarks(_ location: CLLocation) {
        (geocoder ?? CLGeocoder()).reverseGeocodeLocation(location) { placemarks, error in
            let nearbyThings = self.knownPeripherals.filter {
                $0.state == .connected
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
