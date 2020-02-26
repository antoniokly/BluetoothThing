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

    var isRequestingLocation = false
    var userPlacemark: CLPlacemark? {
        didSet {
            if let placemark = userPlacemark, let location = placemark.location {
                updateLocationForNearbyThings(Location(location: location, name: placemark.locality))
            }
        }
    }
    
    var userLocation: CLLocation? {
        didSet {
            if let location = userLocation {
                self.fetchPlacemarks(location)
            }
        }
    }
    
    var nearbyThings: [BluetoothThing] {
        self.knownPeripherals.compactMap {
            self.dataStore.getThing(id: $0.identifier)
        }.filter {
            $0.state == .connected
        }
    }
    
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
                
    public convenience init(delegate: BluetoothThingManagerDelegate,
                            subscriptions: [Subscription],
                            dataStore: DataStoreProtocol? = nil,
                            centralManager: CBCentralManager? = nil,
                            useLocation: Bool = false) {
        self.init(delegate: delegate, subscriptions: subscriptions)        
        
        let dataStoreProtocol = dataStore ?? DataStore()
        
        self.dataStore = dataStoreProtocol
        
        self.knownThings = Set(dataStoreProtocol.things)
        
        self.centralManager = centralManager ??
            CBCentralManager(delegate: self, queue: nil, options: Self.centralManagerOptions)
        
        if useLocation {
            setupLocationManager(CLLocationManager())
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
        
        #if os(iOS) || os(macOS)
        manager.pausesLocationUpdatesAutomatically = true
        manager.startMonitoringSignificantLocationChanges()
        #endif
    }
    
    public func startScanning(allowDuplicates: Bool) {
        var options: [String: Any]? = nil
        
        if allowDuplicates {
            options = [
                CBCentralManagerScanOptionAllowDuplicatesKey: allowDuplicates
            ]
        }
        
        startScanning(options: options)
    }
    
    func startScanning(options: [String: Any]?) {
        scanningOptions = options
        
        if centralManager.state == .poweredOn {
            isPendingToStart = false
            
            for thing in knownThings.filter({$0.state == .disconnected}) {
                loseThing(thing)
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
    
    public func requestLocation(_ minimumInterval: TimeInterval = 60) {
        if isRequestingLocation {
            return
        }
        
        if let location = userLocation, location.timestamp.timeIntervalSinceNow > -minimumInterval {
            os_log("last location is less than %ds older", Int(minimumInterval))
            return
        }
        
        isRequestingLocation = true
        locationManager?.requestLocation()
    }
    
    func updateLocationForNearbyThings(_ location: Location) {
        for thing in nearbyThings {
            if thing.location != location {
                thing.location = location
                self.delegate.bluetoothThing(thing, didUpdateLocation: location)
            }
        }
    }
    
    //MARK: - BluetoothThing
    func setupThing(_ thing: BluetoothThing, for peripheral: CBPeripheral?) {
        // MARK: Connect request
        thing._connect = { [weak self, weak peripheral, weak thing] register in
            guard let strongSelf = self, strongSelf.centralManager.state == .poweredOn, let peripheral = peripheral, let thing = thing else {
                return
            }

            strongSelf.connectThing(thing, peripheral: peripheral, register: register)
        }
        
        // MARK: Disconnect request
        thing._disconnect = { [weak self, weak thing] deregister in
            guard let strongSelf = self, strongSelf.centralManager.state == .poweredOn, let thing = thing else {
                return
            }
            
            strongSelf.disconnectThing(thing, peripheral: peripheral, deregister: deregister)
        }
        
        thing._notify = { [weak self] notify in
            guard let strongSelf = self, strongSelf.centralManager.state == .poweredOn, let peripheral = peripheral else {
                return
            }
            
            if notify {
                peripheral.subscribe(subscriptions: strongSelf.subscriptions)
            } else {
                peripheral.unsubscribe(subscriptions: strongSelf.subscriptions)
            }
        }
    }
    
    @discardableResult
    func didUpdatePeripheral(_ peripheral: CBPeripheral, rssi: NSNumber? = nil) -> BluetoothThing? {
        guard let thing = dataStore.getThing(id: peripheral.identifier) else {
            return nil
        }
        
        if thing.name != peripheral.name && peripheral.name != nil {
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
                
        if let subscription = self.subscriptions.first(where: {
            shouldSubscribe(characteristic: characteristic, subscriptions: [$0]) }) {
            let btCharacteristic = BTCharacteristic(characteristic: characteristic)
            thing.data[btCharacteristic] = characteristic.value
            delegate.bluetoothThing(thing, didUpdateValue: characteristic.value, for: btCharacteristic, subscription: subscription)
        }

        return thing
    }
    
    func loseThing(_ thing: BluetoothThing) {
        os_log("didLoseThing %@", thing.name ?? thing.id.uuidString)
        
        thing.timer?.invalidate()
        thing.timer = nil
//        thing.inRange = false
        
        self.delegate.bluetoothThingManager(self, didLoseThing: thing)
    }
    
    func connectThing(_ thing: BluetoothThing, peripheral: CBPeripheral, register: Bool) {
        if register {
            thing.isRegistered = true
        }
        
        thing.timer?.invalidate()
        thing.timer = nil
        
        dataStore.addThing(thing)
        centralManager.connect(peripheral, options: Self.peripheralOptions)
        delegate.bluetoothThing(thing, didChangeState: peripheral.state)
    }
        
    func disconnectThing(_ thing: BluetoothThing, peripheral: CBPeripheral?, deregister: Bool) {
        thing.disconnecting = true
        
        if let peripheral = peripheral {
            centralManager.cancelPeripheralConnection(peripheral)
            delegate.bluetoothThing(thing, didChangeState: peripheral.state)
        } else {
            thing.state = .disconnected
            delegate.bluetoothThing(thing, didChangeState: thing.state)
        }
        
        if deregister {
            thing.isRegistered = false
            dataStore.removeThing(id: thing.id)
            loseThing(thing)
        }
    }
    
    func didConnectThing(_ thing: BluetoothThing, peripheral: CBPeripheral) {
        peripheral.readRSSI()
        peripheral.discoverServices(serviceUUIDs)
                
        // MARK: Data Request
        thing._request = { [weak peripheral] (request) in
            os_log("request %@", request.method.rawValue)
            guard
                let peripheral = peripheral,
                peripheral.state == .connected,
                let service = peripheral.services?.first(where: {$0.uuid == request.characteristic.serviceUUID}),
                let charateristic = service.characteristics?.first(where: {$0.uuid == request.characteristic.uuid})
                else {
                    return false
            }
            
            switch request.method {
            case .read:
                peripheral.readValue(for: charateristic)
            case .write:
                guard let data = request.value else { return false }
                peripheral.writeValue(data, for: charateristic, type: .withResponse)
                peripheral.readValue(for: charateristic)
            }
            
            return true
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
                        if thing.autoReconnect {
                            central.connect(peripheral, options: Self.peripheralOptions)
                        }
                    }
                } else {
                    central.cancelPeripheralConnection(peripheral)
                }
            }
            
            if isPendingToStart {
                startScanning(options: scanningOptions)
            }
            
            requestLocation()
            
        } else {
            for peripheral in knownPeripherals {
                didUpdatePeripheral(peripheral)
            }
            
            for thing in knownThings.filter({$0.state != .connected}) {
                loseThing(thing)
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
            
            for thing in dataStore.things {
                let peripheral = peripherals.first(where: {$0.identifier == thing.id})
                // peripheral can be nil
                setupThing(thing, for: peripheral)
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
        
        var foundThing: BluetoothThing

        if let thing = didUpdatePeripheral(peripheral, rssi: RSSI) {
            setupThing(thing, for: peripheral)

            if thing.autoReconnect {
                central.connect(peripheral, options: Self.peripheralOptions)
            }
            
            foundThing = thing
        } else {
            
            if let thing = knownThings.first(where: {$0.id == peripheral.identifier}) {
                foundThing = thing

            } else {
                let newThing = BluetoothThing(peripheral: peripheral)
                knownThings.insert(newThing)
                foundThing = newThing
            }
        }
        
        foundThing.timer?.invalidate()
        foundThing.timer = nil
//        foundThing.inRange = true
        
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

        if let location = userLocation {
            foundThing.location = Location(location: location, name: userPlacemark?.locality)
        } else {
            requestLocation()
        }
        
        setupThing(foundThing, for: peripheral)
        delegate.bluetoothThingManager(self, didFoundThing: foundThing, rssi: RSSI)
    }
    
    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        os_log("didConnect %@", peripheral)
        if let thing = didUpdatePeripheral(peripheral){
            thing.timer?.invalidate()
            thing.timer = nil
            didConnectThing(thing, peripheral: peripheral)
        
            if let location = userLocation {
                thing.location = Location(location: location, name: userPlacemark?.locality)
            } else {
                requestLocation()
            }
        }
    }
    
    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        os_log("didDisconnectPeripheral %@", peripheral)
                
        if let thing = didUpdatePeripheral(peripheral) {
            thing.state = peripheral.state
            delegate.bluetoothThing(thing, didChangeState: peripheral.state)
            
            // reconnect if lost connection unintentionally
            if !thing.disconnecting || thing.autoReconnect {
                central.connect(peripheral, options: Self.peripheralOptions)
            }
            thing.disconnecting = false
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
                
                if uuids.contains(nil) {
                    peripheral.discoverCharacteristics(nil, for: service)
                } else {
                    peripheral.discoverCharacteristics(uuids.compactMap({$0}), for: service)
                }
            }
        }
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let characteristics = service.characteristics, let thing = things.first(where: {$0.id == peripheral.identifier}) {
            os_log("didDiscoverCharacteristicsFor %@ %@", service, characteristics)
                        
            let subscribe = delegate.bluetoothThingShouldSubscribeOnConnect(thing)
            let subscribedCharacteristics = characteristics.filter {
                shouldSubscribe(characteristic: $0, subscriptions: self.subscriptions)
            }
            
            for characteristic in subscribedCharacteristics {
                if subscribe {
                    if !characteristic.isNotifying {
                        peripheral.setNotifyValue(true, for: characteristic)
                    }
                } else {
                    peripheral.readValue(for: characteristic)
                }
            }
        }
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        os_log("didUpdateValueFor %@ %@", peripheral, characteristic)
        didUpdateCharacteristic(characteristic, for: peripheral)
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        os_log("didUpdateNotificationStateFor %@", characteristic)
        peripheral.readValue(for: characteristic)
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
        isRequestingLocation = false
        
        for location in locations {
            if let last = userLocation, last.timestamp > location.timestamp {
                return
            }
            
            userLocation = location
            userPlacemark = nil
            fetchPlacemarks(location)
        }
    }
    
    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        os_log("didFailWithError: %@", error.localizedDescription)
        isRequestingLocation = false
        delegate.bluetoothThingManager(self, locationDidFailWithError: error)
    }
    
    func fetchPlacemarks(_ location: CLLocation) {
        (geocoder ?? CLGeocoder()).reverseGeocodeLocation(location) { placemarks, error in
            if error == nil, self.userLocation == location {
                self.userPlacemark = placemarks?.first
            }
        }
    }
}
