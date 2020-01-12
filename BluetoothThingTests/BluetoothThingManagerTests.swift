//
//  BluetoothThingManagerTests.swift
//  BluetoothThingTests
//
//  Created by Antonio Yip on 10/01/20.
//  Copyright © 2020 Antonio Yip. All rights reserved.
//

import XCTest
import CoreBluetooth
@testable import BluetoothThing


class BluetoothThingManagerTests: XCTestCase {
    
    var sut: BluetoothThingManager!
    
    class DataStoreMock: DataStoreInterface {
        func getStoredThings() -> [BluetoothThing] {
            return []
        }
        
        var things: [BluetoothThing] = []
        
        func save() {
            
        }
        
        func getThing(id: UUID) -> BluetoothThing {
            return BluetoothThing(id: id)
        }
    }
    
    class BluetoothThingManagerDelegateSpy: BluetoothThingManagerDelegate {
        func bluetoothThing(_ thing: BluetoothThing, didUpdateLocation location: Location) {
            
        }
        
        func bluetoothThingManager(_ manager: BluetoothThingManager, didFoundThing: BluetoothThing) {
            
        }
        
        func bluetoothThing(_ thing: BluetoothThing, didChangeCharacteristic characteristic: Characteristic) {
            
        }
        
        var didChangeStateThing: BluetoothThing?
        var didChangeState: ConnectionState?
        func bluetoothThing(_ thing: BluetoothThing, didChangeState state: ConnectionState) {
            didChangeStateThing = thing
            didChangeState = state
        }
        
        func bluetoothThing(_ thing: BluetoothThing, didChangeRSSI rssi: NSNumber?) {
            
        }
        
    }
    
    var delegate: BluetoothThingManagerDelegateSpy!
    var centralManager: CBCentralManagerMock!
    var dataStore: DataStoreMock!
    
    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        delegate = BluetoothThingManagerDelegateSpy()
        centralManager = CBCentralManagerMock()
        dataStore = DataStoreMock()
    }
    
    func initBluetoothThingManager(subscriptions: [Subscription], numberOfPeripharels: Int = 1) -> BluetoothThingManager {
        let manager = BluetoothThingManager(delegate: delegate,
                                            subscriptions: subscriptions,
                                            dataStore: dataStore,
                                            centralManager: centralManager,
                                            useLocation: false)
        
        centralManager.delegate = manager
        
        let uuids = [CBUUID: [CBUUID]].init(subscriptions.map({($0.serviceUUID,
                                                                [$0.characteristicUUID])}),
                                            uniquingKeysWith: {$0 + $1})
        
        let services = uuids.map { sUUID, cUUID -> CBService in
            let service = CBServiceMock(uuid: sUUID)
            let characteristics = cUUID.map {
                CBCharacteristicMock(uuid: $0, service: service)
            }
            service._characteristics = characteristics
            return service
        }
        
        let peripherals = [CBPeripheralMock](repeating: {CBPeripheralMock(identifier: UUID(),
                                                                          services: services)}(),
                                             count: numberOfPeripharels)

        centralManager.peripherals = peripherals

        return manager
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testStartStop() {
        // Given
        let serviceUUID = CBUUID(string: "FFF0")
        let characteristicUUID = CBUUID(string: "FFF1")
        
        let subsriptions = [
            Subscription(service: serviceUUID,
                         characteristic: characteristicUUID)
        ]
        
        sut = initBluetoothThingManager(subscriptions: subsriptions)
        
        // When
        centralManager.state = .poweredOff
        sut.stop()
        
        //Then
        XCTAssertFalse(sut.isPendingToStart)
        XCTAssertFalse(centralManager.stopScanCalled)
        
        // When
        sut.start()
        
        //Then
        XCTAssertTrue(sut.isPendingToStart)
        XCTAssertEqual(centralManager.scanForPeripheralsCalled, 0)
        XCTAssertTrue(sut.knownPeripherals.isEmpty)
        
        
        // When
        centralManager.state = .poweredOn
        sut.centralManagerDidUpdateState(centralManager)
        
        //Then
        let peripharel = sut.knownPeripherals.first as? CBPeripheralMock
        XCTAssertFalse(sut.isPendingToStart)
        XCTAssertEqual(centralManager.scanForPeripheralsCalled, 1)
        XCTAssertEqual(centralManager.scanForPeripheralsServiceUUIDs, [serviceUUID])
        XCTAssertEqual(peripharel?.setNotifyValueCalled, 1)
        XCTAssertEqual(peripharel?.setNotifyValueEnabled, true)
        XCTAssertEqual(peripharel?.setNotifyValueCharacteristic?.uuid, characteristicUUID)
        
        // When
        sut.stop()
        
        //Then
        XCTAssertFalse(sut.isPendingToStart)
        XCTAssertTrue(centralManager.stopScanCalled)
        XCTAssertEqual(peripharel?.setNotifyValueCalled, 2)
        XCTAssertEqual(peripharel?.setNotifyValueEnabled, false)
        XCTAssertEqual(peripharel?.setNotifyValueCharacteristic?.uuid, characteristicUUID)
    }
    
    func testRestoreState() {
        // Given
        let serviceUUID = CBUUID(string: "FFF0")
        let characteristicUUID = CBUUID(string: "FFF1")
        
        let subsriptions = [
            Subscription(service: serviceUUID,
                         characteristic: characteristicUUID)
        ]
        
        sut = initBluetoothThingManager(subscriptions: subsriptions)
        
        // When
        centralManager.state = .poweredOn
        let restoreScan = [CBUUID()]
        let restorePeripherals = centralManager.peripherals

        guard let peripheral = centralManager.peripherals.first else {
            XCTFail("peripheral should not be nil")
            return
        }
        
        peripheral._state = .connected
        let restoreState: [String: Any] = [
            CBCentralManagerRestoredStateScanServicesKey: restoreScan,
            CBCentralManagerRestoredStatePeripheralsKey: restorePeripherals
        ]
        sut.centralManager(sut.centralManager, willRestoreState: restoreState)
        
        // Then
        XCTAssertEqual(centralManager.scanForPeripheralsCalled, 1)
        XCTAssertEqual(centralManager.scanForPeripheralsServiceUUIDs, [serviceUUID])
        XCTAssertEqual(delegate.didChangeStateThing?.id, restorePeripherals.first?.identifier)
        XCTAssertEqual(delegate.didChangeStateThing?.state, .connected)
        XCTAssertEqual(delegate.didChangeState, .connected)
        XCTAssertEqual(peripheral.discoverServicesCalled, 1)
        XCTAssertEqual(peripheral.discoverServices, peripheral.services?.map({$0.uuid}))
    }
    
    func testDidConnect() {
        // Given
        let serviceUUID = CBUUID(string: "FFF0")
        let characteristicUUID = CBUUID(string: "FFF1")
        
        let subsriptions = [
            Subscription(service: serviceUUID,
                         characteristic: characteristicUUID)
        ]
        
        sut = initBluetoothThingManager(subscriptions: subsriptions)
        
        guard let peripheral = centralManager.peripherals.first else {
            XCTFail("peripheral should not be nil")
            return
        }
    
        // When
        centralManager.state = .poweredOn
        sut.centralManager(sut.centralManager, didConnect: peripheral)
        
        XCTAssertEqual(peripheral.discoverServicesCalled, 1)
        XCTAssertEqual(peripheral.discoverServices, peripheral.services?.map({$0.uuid}))
    }
    
    func testDidDisconnect() {
        // Given
        let serviceUUID = CBUUID(string: "FFF0")
        let characteristicUUID = CBUUID(string: "FFF1")
        
        let subsriptions = [
            Subscription(service: serviceUUID,
                         characteristic: characteristicUUID)
        ]
        
        sut = initBluetoothThingManager(subscriptions: subsriptions)
        
        guard let peripheral = centralManager.peripherals.first else {
            XCTFail("peripheral should not be nil")
            return
        }
    
        // When
        centralManager.state = .poweredOn
        sut.centralManager(sut.centralManager, didDisconnectPeripheral: peripheral, error: nil)
        
        XCTAssertEqual(centralManager.connectCalled, 1)
        XCTAssertEqual(centralManager.connectPeripheral, peripheral)
    }
    
    func testDidDiscoverServices() {
        // Given
        let serviceUUID = CBUUID(string: "FFF0")
        let characteristicUUID = CBUUID(string: "FFF1")
        
        let subsriptions = [
            Subscription(service: serviceUUID,
                         characteristic: characteristicUUID)
        ]
        
        sut = initBluetoothThingManager(subscriptions: subsriptions)
        
        guard let peripheral = centralManager.peripherals.first else {
            XCTFail("peripheral should not be nil")
            return
        }
    
        // When
        centralManager.state = .poweredOn
        sut.peripheral(peripheral, didDiscoverServices: nil)
        
        XCTAssertEqual(peripheral.discoverCharacteristicsCalled, 1)
        XCTAssertEqual(peripheral.discoverCharacteristicsService, peripheral.services?.first)
        XCTAssertEqual(peripheral.discoverCharacteristics, peripheral.services?.first?.characteristics?.map({$0.uuid}))
    }
    
    func testDidDiscoverCharacteristics() {
        // Given
        let serviceUUID = CBUUID(string: "FFF0")
        let characteristicUUID = CBUUID(string: "FFF1")
        
        let subsriptions = [
            Subscription(service: serviceUUID,
                         characteristic: characteristicUUID)
        ]
        
        sut = initBluetoothThingManager(subscriptions: subsriptions)
        
        guard let peripheral = centralManager.peripherals.first else {
            XCTFail("peripheral should not be nil")
            return
        }
        
        // When
        centralManager.state = .poweredOn
        sut.peripheral(peripheral, didDiscoverCharacteristicsFor: peripheral.services!.first!, error: nil)
        
        XCTAssertEqual(peripheral.readValueCalled, 1)
        XCTAssertEqual(peripheral.readValueCharacteristic?.uuid, characteristicUUID)
        XCTAssertEqual(peripheral.setNotifyValueCalled, 1)
        XCTAssertEqual(peripheral.setNotifyValueEnabled, true)
        XCTAssertEqual(peripheral.setNotifyValueCharacteristic?.uuid, characteristicUUID)
    }
}
