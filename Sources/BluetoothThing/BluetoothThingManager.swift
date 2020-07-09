//
//  BluetoothThingManager.swift
//  BluetoothThing
//
//  Created by Antonio Yip on 8/01/20.
//  Copyright © 2020 Antonio Yip. All rights reserved.
//

import Foundation
import CoreBluetooth
import os.log

#if canImport(UIKit)
import UIKit
#endif

#if canImport(WatchKit)
import WatchKit
#endif

#if canImport(TVUIKit)
import TVUIKit
#endif

public class BluetoothThingManager: NSObject {
    public static var deviceName: String {
        #if os(iOS)
        return UIDevice.current.name
        #elseif os(OSX)
        return Host.current().localizedName!
        #elseif os(watchOS)
        return WKInterfaceDevice.current().name
        #else
        return "unknown"
        #endif
    }

    public static var centralId: UUID {
        #if os(iOS)
        return UIDevice.current.identifierForVendor!
        #else
        if let uuidString = UserDefaults.standard.object(forKey: .centralId) as? String,
            let uuid = UUID(uuidString: uuidString) {
            return uuid
        } else {
            let uuid = UUID()
            UserDefaults.standard.set(uuid.uuidString, forKey: .centralId)
            return uuid
        }
        #endif
    }
    
    static let centralManagerOptions: [String: Any]? = [
        CBCentralManagerOptionRestoreIdentifierKey: Bundle.main.bundleIdentifier!
    ]
    
    static let peripheralOptions: [String: Any]? = nil
    
    public internal (set) var delegate: BluetoothThingManagerDelegate
    public internal (set) var dataStore: DataStoreProtocol!
    public internal (set) var subscriptions: Set<BTSubscription>
            
    lazy var centralManager = CBCentralManager(delegate: self,
                                               queue: nil,
                                               options: Self.centralManagerOptions)
        
    public var things: [BluetoothThing] {
        dataStore.things
    }
    
    var nearbyThings: [BluetoothThing] {
        self.knownPeripherals.compactMap {
            self.dataStore.getThing(id: $0.identifier)
        }.filter {
            $0.state == .connected
        }
    }
    
    var serviceUUIDs: [CBUUID] {
        [CBUUID](Set(subscriptions.map({$0.serviceUUID})))
    }
        
    var isPendingToStart = false
    var scanningOptions: [String: Any]?
    var loseThingAfterTimeInterval: TimeInterval = 10
    
    var allowDuplicates: Bool {
        scanningOptions?[CBCentralManagerScanOptionAllowDuplicatesKey] as? Bool == true
    }
    
    var knownPeripherals: Set<CBPeripheral> = []
    var knownThings: Set<BluetoothThing> = []
    
    // MARK: - Public Initializer
    public convenience init<T: Sequence>(delegate: BluetoothThingManagerDelegate,
                            subscriptions: T,
                            useCoreData: Bool = false) where T.Element == BTSubscription {
        self.init(delegate: delegate, subscriptions: subscriptions)
        self.dataStore = DataStore(persistentStore:
            useCoreData ? CoreDataStore() : UserDefaults.standard
        )
        self.knownThings = Set(dataStore.things)
    }
    
    @available(iOS 13.0, watchOS 6.0, macOS 10.15, tvOS 13.0, *)
    public convenience init<T: Sequence>(delegate: BluetoothThingManagerDelegate,
                            subscriptions: T,
                            useCoreData: Bool = false,
                            useCloudKit: Bool = false) where T.Element == BTSubscription {
        self.init(delegate: delegate, subscriptions: subscriptions)
        self.dataStore = DataStore(persistentStore:
            useCoreData ? CoreDataStore(useCloudKit: useCloudKit) : UserDefaults.standard
        )
        self.knownThings = Set(dataStore.things)
    }
    
    init<T: Sequence>(delegate: BluetoothThingManagerDelegate, subscriptions: T) where T.Element == BTSubscription {
        self.delegate = delegate
        self.subscriptions = Set(subscriptions)
        super.init()
    }

    // MARK: -
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
        
        switch centralManager.state {
        case .poweredOn:
            isPendingToStart = false
            
            for thing in knownThings.filter({$0.state == .disconnected}) {
                loseThing(thing)
            }
            
            os_log("start scanning", serviceUUIDs)
            centralManager.scanForPeripherals(withServices: serviceUUIDs, options: options)
        case .poweredOff, .resetting, .unauthorized:
            isPendingToStart = true
        default:
            break
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
    
    public func reset() {
        for id in things.map({$0.id}) {
            if let thing = dataStore.removeThing(id: id) {
                loseThing(thing)
            }
        }
    }
    
    //MARK: - BluetoothThing
    func getThing(for peripheral: CBPeripheral) -> BluetoothThing? {
        return dataStore.getThing(id: peripheral.identifier)
    }
    
    func setupThing(_ thing: BluetoothThing, for peripheral: CBPeripheral?) {
        // MARK: Connect request
        thing._connect = { [weak self, weak peripheral, weak thing] register in
            guard let self = self, self.centralManager.state == .poweredOn, let peripheral = peripheral, let thing = thing else {
                return
            }

            self.connectThing(thing, peripheral: peripheral, register: register)
        }
        
        // MARK: Disconnect request
        thing._disconnect = { [weak self, weak thing] deregister in
            guard let self = self, self.centralManager.state == .poweredOn, let thing = thing else {
                return
            }
            
            self.disconnectThing(thing, peripheral: peripheral, deregister: deregister)
        }
        
        // MARK: Notify request
        thing._notify = { [weak self] notify in
            guard let self = self, self.centralManager.state == .poweredOn, let peripheral = peripheral else {
                return
            }
            
            if notify {
                peripheral.subscribe(subscriptions: self.subscriptions)
            } else {
                peripheral.unsubscribe(subscriptions: self.subscriptions)
            }
        }
    }
    
    @discardableResult
    func didUpdatePeripheral(_ peripheral: CBPeripheral, rssi: NSNumber? = nil) -> BluetoothThing? {
        guard let thing = getThing(for: peripheral) else {
            return nil
        }
        
        if thing.name != peripheral.name && peripheral.name != nil {
            thing.name = peripheral.name
        }
        
        if thing.state != peripheral.state {
            thing.state = peripheral.state
            
            if peripheral.state == .connected {
                didConnectThing(thing, peripheral: peripheral)
            } else {
                delegate.bluetoothThing(thing, didChangeState: peripheral.state)
            }
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
                
        let btCharacteristic = BTCharacteristic(characteristic: characteristic)
        let isNewThing = thing.hardwareSerialNumber == nil
        
        thing.characteristics[btCharacteristic] = characteristic.value
        
        if isNewThing && btCharacteristic == .serialNumber {
            dataStore.saveThing(thing)
        }
            
        let subscription = self.subscriptions.first(where: { shouldSubscribe(characteristic: characteristic, subscriptions: [$0]) })
        delegate.bluetoothThing(thing, didUpdateValue: characteristic.value, for: btCharacteristic, subscription: subscription)
        

        return thing
    }
    
    func loseThing(_ thing: BluetoothThing) {
        os_log("didLoseThing %@", thing.name ?? thing.id.uuidString)
        
        thing.timer?.invalidate()
        thing.timer = nil
        
        self.delegate.bluetoothThingManager(self, didLoseThing: thing)
    }
    
    func connectThing(_ thing: BluetoothThing, peripheral: CBPeripheral, register: Bool) {
        thing.timer?.invalidate()
        thing.timer = nil
        
        if register {
            thing.autoReconnect = true
        }
        
        dataStore.addThing(thing)
        
        if peripheral.state != .connected && peripheral.state != .connecting {
            centralManager.connect(peripheral, options: Self.peripheralOptions)
            // state may change to connecting in real case
            delegate.bluetoothThing(thing, didChangeState: peripheral.state)
        }
    }
        
    func disconnectThing(_ thing: BluetoothThing, peripheral: CBPeripheral?, deregister: Bool) {
        thing.disconnecting = true
        
        if deregister {
            thing.autoReconnect = false
        }
        
        if let peripheral = peripheral {
            if peripheral.state != .disconnected && peripheral.state != .disconnecting {
                centralManager.cancelPeripheralConnection(peripheral)
                // state may change to disconnecting in real case
                delegate.bluetoothThing(thing, didChangeState: peripheral.state)
            }
        } else {
            thing.state = .disconnected
            delegate.bluetoothThing(thing, didChangeState: thing.state)
        }
        
        if deregister {
            dataStore.removeThing(id: thing.id)
            loseThing(thing)
        }
    }
    
    func didConnectThing(_ thing: BluetoothThing, peripheral: CBPeripheral) {
        peripheral.readRSSI()
        peripheral.discoverServices(nil)
                
        // MARK: Data Request
        thing._request = { [weak peripheral] (request) in
            os_log("request %@", request.method.rawValue)
            guard
                let peripheral = peripheral,
                peripheral.state == .connected,
                let service = peripheral.services?.first(where: {$0.uuid == request.characteristic.serviceUUID})
                else {
                    return false
            }
            
            guard let charateristic = service.characteristics?.first(where: {$0.uuid == request.characteristic.uuid}) else {
                peripheral.discoverCharacteristics([request.characteristic.uuid], for: service)
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
        
        thing._subscribe = { [weak peripheral] subscription in
            guard let peripheral = peripheral else {
                return
            }
            
            if let service = peripheral.services?.first(where: {$0.uuid == subscription.serviceUUID}) {
                
                if let characteristic = service.characteristics?.first(where: {$0.uuid == subscription.characteristicUUID}) {
                    if !characteristic.isNotifying {
                        peripheral.setNotifyValue(true, for: characteristic)
                    }
                } else {
                    if let uuid = subscription.characteristicUUID {
                        peripheral.discoverCharacteristics([uuid], for: service)
                    } else {
                        peripheral.discoverCharacteristics(nil, for: service)
                    }
                }
                
            } else {
                peripheral.discoverServices([subscription.serviceUUID])
            }
        }
        
        thing._unsubscribe = { [weak peripheral] subscription in
            guard
                let peripheral = peripheral,
                let service = peripheral.services?.first(where: {$0.uuid == subscription.serviceUUID}),
                let characteristics = service.characteristics else {
                return
            }
            
            for characteristic in characteristics.filter({
                subscription.characteristicUUID == nil || $0.uuid == subscription.characteristicUUID
            }) {
                if characteristic.isNotifying {
                    peripheral.setNotifyValue(false, for: characteristic)
                }
            }
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
        os_log("centralManagerDidUpdateState: %@", central.state.description)

        switch central.state {
        case .poweredOn:
            for peripheral in knownPeripherals {
                if let thing = didUpdatePeripheral(peripheral) {
                    if thing.autoReconnect {
                        central.connect(peripheral, options: Self.peripheralOptions)
                    }
                } else {
                    central.cancelPeripheralConnection(peripheral)
                }
            }
            
            if isPendingToStart {
                startScanning(options: scanningOptions)
            }
        case .poweredOff, .resetting, .unauthorized:
            for peripheral in knownPeripherals {
                didUpdatePeripheral(peripheral)
            }
            
            for thing in knownThings.filter({$0.state != .connected}) {
                loseThing(thing)
            }
            
            startScanning(options: scanningOptions)
        default:
            break
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
        
        let foundThing: BluetoothThing

        if let thing = didUpdatePeripheral(peripheral, rssi: RSSI) {
            setupThing(thing, for: peripheral)

            if thing.autoReconnect || thing.pendingConnect {
                central.connect(peripheral, options: Self.peripheralOptions)
            }
            
            foundThing = thing
        } else {
            if let thing = knownThings.first(where: {$0.id == peripheral.identifier}) {
                thing.name = peripheral.name
                foundThing = thing
            } else {
                let newThing = BluetoothThing(peripheral: peripheral)
                knownThings.insert(newThing)
                foundThing = newThing
            }

            setupThing(foundThing, for: peripheral)
        }
        
        delegate.bluetoothThingManager(self, didFindThing: foundThing, rssi: RSSI)
        
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
    }
    
    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        os_log("didConnect %@", peripheral)
        if let thing = didUpdatePeripheral(peripheral){
            thing.pendingConnect = false
            thing.timer?.invalidate()
            thing.timer = nil
        }
    }
    
    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        os_log("didDisconnectPeripheral %@", peripheral)
        if let error = error {
            os_log("error %@", error as CVarArg)
        }
        if let thing = didUpdatePeripheral(peripheral) {
            // reconnect if lost connection unintentionally
            if !thing.disconnecting {
                central.connect(peripheral, options: Self.peripheralOptions)
            }
            thing.disconnecting = false
            dataStore.updateThing(thing)
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
        os_log("didDiscoverServices %@ %@", peripheral, String(describing: peripheral.services))

        guard let thing = things.first(where: {$0.id == peripheral.identifier}) else {
            return
        }
        
        if let services = peripheral.services {
            for service in services {
                if thing.services.insert(BTService(service: service)).inserted {
                    // new discovery
                    
                    let characteristicUUIDs = subscriptions.union(thing.subscriptions).filter {
                        $0.serviceUUID == service.uuid
                    }.map {
                        $0.characteristicUUID
                    }
                    
                    if characteristicUUIDs.isEmpty {
                        continue
                    }
                    
                    if characteristicUUIDs.contains(nil) {
                        peripheral.discoverCharacteristics(nil, for: service)
                    } else {
                        peripheral.discoverCharacteristics(characteristicUUIDs.compactMap({$0}), for: service)
                    }
                }
            }
        }

        if peripheral.state == .connected {
            // delay connected state until discovered services
            delegate.bluetoothThing(thing, didChangeState: peripheral.state)
        }
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let characteristics = service.characteristics {
            os_log("didDiscoverCharacteristicsFor %@ %@", service, characteristics)
            
            var subscriptions = self.subscriptions
            
            if let thing = getThing(for: peripheral) {
                subscriptions = subscriptions.union(thing.subscriptions)
            }
            
            for characteristic in characteristics {
                if shouldSubscribe(characteristic: characteristic, subscriptions: subscriptions) {
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
