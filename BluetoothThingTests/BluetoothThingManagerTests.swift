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
        
    class BluetoothThingManagerDelegateSpy: BluetoothThingManagerDelegate {
        var centralId: UUID = UUID()
        
        func bluetoothThingShouldSubscribeOnConnect(_ thing: BluetoothThing) -> Bool {
            return true
        }
        
        var didFoundThingCalled = 0
        var didFoundThingRSSI: NSNumber?
        var foundThing: BluetoothThing?
        func bluetoothThingManager(_ manager: BluetoothThingManager, didFoundThing thing: BluetoothThing, rssi: NSNumber) {
            didFoundThingCalled += 1
            didFoundThingRSSI = rssi
            foundThing = thing
        }
        
        var didLoseThingExpectation = XCTestExpectation(description: "didloseThing")
        var didLoseThingCalled = 0
        var didLoseThing: BluetoothThing?
        func bluetoothThingManager(_ manager: BluetoothThingManager, didLoseThing thing: BluetoothThing) {
            didLoseThingExpectation.fulfill()
            didLoseThingCalled = 1
            didLoseThing = thing
        }
        
        var didFailToConnectCalled = 0
        var didFailToConnectThing: BluetoothThing?
        var didFailToConnectError: Error?
        func bluetoothThingManager(_ manager: BluetoothThingManager, didFailToConnect thing: BluetoothThing, error: Error?) {
            didFailToConnectCalled += 1
            didFailToConnectThing = thing
            didFailToConnectError = error
        }
        
        var didUpdateValueCalled = 0
        var didUpdateValueThing: BluetoothThing?
        var didUpdateValueCharacteristic: BTCharacteristic?
        var didUpdateValueSubscription: Subscription?
        var didUpdateValue: Data?
        func bluetoothThing(_ thing: BluetoothThing, didUpdateValue value: Data?, for characteristic: BTCharacteristic, subscription: Subscription?) {
            didUpdateValueCalled += 1
            didUpdateValueThing = thing
            didUpdateValueCharacteristic = characteristic
            didUpdateValueSubscription = subscription
            didUpdateValue = value
        }
        
        var didChangeStateCalled = 0
        var didChangeStateThing: BluetoothThing?
        var didChangeState: ConnectionState?
        func bluetoothThing(_ thing: BluetoothThing, didChangeState state: ConnectionState) {
            didChangeStateCalled += 1
            didChangeStateThing = thing
            didChangeState = state
        }
        
        var didChangeRSSICalled = 0
        var didChangeRSSIThing: BluetoothThing?
        var didChangeRSSI: NSNumber?
        func bluetoothThing(_ thing: BluetoothThing, didChangeRSSI rssi: NSNumber) {
            didChangeRSSICalled += 1
            didChangeRSSIThing = thing
            didChangeRSSI = rssi
        }
    }
    
    var delegate: BluetoothThingManagerDelegateSpy!
    
    override func setUp() {
        delegate = BluetoothThingManagerDelegateSpy()
    }

    override func tearDown() {
        sut.reset()
        sut.dataStore.reset()
    }
    
    func testInitialization() {
        // Given
        let serviceUUID = CBUUID(string: "FFF0")
        let characteristicUUID = CBUUID(string: "FFF1")
        
        let subscriptions = [
            Subscription(serviceUUID: serviceUUID, characteristicUUID: characteristicUUID)
        ]
        
        let peripherals = initPeripherals(subscriptions: subscriptions, numberOfPeripherals: 3)
        let dataStore = DataStoreMock(peripherals: peripherals)
        let centralManager = CBCentralManagerMock(peripherals: peripherals)

        sut = initBluetoothThingManager(delegate: delegate,
                                        subscriptions: subscriptions,
                                        dataStore: dataStore,
                                        centralManager: centralManager)

        XCTAssertNotNil(sut.delegate)
        XCTAssertNotNil(sut.dataStore)
        XCTAssertNotNil(sut.centralManager.delegate)

        XCTAssertEqual(sut.subscriptions.count, 1)
        XCTAssertEqual(sut.serviceUUIDs, [serviceUUID])
        XCTAssertEqual(sut.things.count, 3)
        XCTAssertEqual(sut.things.first?.id, peripherals.first?.identifier)
        XCTAssertEqual(sut.things.last?.id, peripherals.last?.identifier)
    }

    func testStartStop() {
        // Given
        let serviceUUID = CBUUID(string: "FFF0")
        let characteristicUUID = CBUUID(string: "FFF1")
        
        let subscriptions = [
            Subscription(serviceUUID: serviceUUID, characteristicUUID: characteristicUUID)
        ]
        
        let peripherals = initPeripherals(subscriptions: subscriptions, numberOfPeripherals: 2)
        let dataStore = DataStoreMock(peripherals: peripherals)
        let centralManager = CBCentralManagerMock(peripherals: peripherals)
        sut = initBluetoothThingManager(delegate: delegate,
                                        subscriptions: subscriptions,
                                        dataStore: dataStore,
                                        centralManager: centralManager)
        
        sut.knownThings = Set(dataStore.things.suffix(1))
        
        // When
        centralManager._state = .poweredOff
        sut.stopScanning()
        
        //Then
        XCTAssertFalse(sut.isPendingToStart)
        XCTAssertFalse(centralManager.stopScanCalled)
        
        // When
        sut.startScanning(allowDuplicates: true)
        
        //Then
        XCTAssertTrue(sut.isPendingToStart)
        XCTAssertEqual(centralManager.scanForPeripheralsCalled, 0)
        XCTAssertTrue(sut.knownPeripherals.isEmpty)
        
        
        // When
        centralManager._state = .poweredOn
        sut.centralManagerDidUpdateState(centralManager)
        
        //Then
        XCTAssertEqual(delegate.didLoseThingCalled, 1)
        XCTAssertEqual(delegate.didLoseThing?.id, sut.knownThings.first?.id)
        XCTAssertFalse(sut.isPendingToStart)
        XCTAssertEqual(centralManager.scanForPeripheralsCalled, 1)
        XCTAssertEqual(centralManager.scanForPeripheralsServiceUUIDs, [serviceUUID])
        
        // When
        sut.stopScanning()
        
        //Then
        XCTAssertFalse(sut.isPendingToStart)
        XCTAssertTrue(centralManager.stopScanCalled)
    }
    
    func testRestoreState() {
        // Given
        let serviceUUID = CBUUID(string: "FFF0")
        let characteristicUUID = CBUUID(string: "FFF1")
        
        let subscriptions = [
            Subscription(serviceUUID: serviceUUID, characteristicUUID: characteristicUUID)
        ]
        
        let peripherals = initPeripherals(subscriptions: subscriptions, numberOfPeripherals: 1)
        let peripheral = peripherals.first!
        let dataStore = DataStoreMock(peripherals: peripherals)
        let thing = dataStore.things.first!
        let centralManager = CBCentralManagerMock(peripherals: peripherals)
        sut = initBluetoothThingManager(delegate: delegate,
                                        subscriptions: subscriptions,
                                        dataStore: dataStore,
                                        centralManager: centralManager)
        
        // When
        let restoreScanServiceUUIDs: [CBUUID] = []
        let restorePeripherals = peripherals
        
        peripheral._state = .connected
        let restoreState: [String: Any] = [
            CBCentralManagerRestoredStateScanServicesKey: restoreScanServiceUUIDs,
            CBCentralManagerRestoredStatePeripheralsKey: restorePeripherals
        ]
        sut.centralManager(sut.centralManager, willRestoreState: restoreState)
        
        centralManager._state = .poweredOn
        sut.centralManagerDidUpdateState(centralManager)
        
        // Then
        XCTAssertNotNil(thing.deregister)
        XCTAssertEqual(delegate.didChangeStateThing?.id, peripheral.identifier)
        XCTAssertEqual(delegate.didChangeStateThing?.state, .connected)
        XCTAssertEqual(delegate.didChangeState, .connected)
        XCTAssertEqual(peripheral.discoverServicesCalled, 1)
        XCTAssertNil(peripheral.discoverServices)
    }
    
    func testPowerOff() {
        // Given
        let serviceUUID = CBUUID(string: "FFF0")
        let characteristicUUID = CBUUID(string: "FFF1")
        
        let subscriptions = [
            Subscription(serviceUUID: serviceUUID, characteristicUUID: characteristicUUID)
        ]
        
        let peripherals = initPeripherals(subscriptions: subscriptions, numberOfPeripherals: 1)
        let dataStore = DataStoreMock(peripherals: peripherals)
        let centralManager = CBCentralManagerMock(peripherals: peripherals)
        sut = initBluetoothThingManager(delegate: delegate,
                                        subscriptions: subscriptions,
                                        dataStore: dataStore,
                                        centralManager: centralManager)

        dataStore.things.first?.state = .connected
        sut.knownThings = Set(dataStore.things)
        sut.knownPeripherals = Set(peripherals)
        
        // When
        centralManager._state = .poweredOff
        sut.centralManagerDidUpdateState(sut.centralManager)
        
        // Then
        XCTAssertEqual(delegate.didChangeStateCalled, 1)
        XCTAssertEqual(delegate.didChangeState, .disconnected)
        XCTAssertEqual(delegate.didLoseThingCalled, 1)
        XCTAssertTrue(sut.isPendingToStart)
    }
    
    func testDidConnect() {
        // Given
        let serviceUUID = CBUUID(string: "FFF0")
        let characteristicUUID = CBUUID(string: "FFF1")
        
        let subscriptions = [
            Subscription(serviceUUID: serviceUUID, characteristicUUID: characteristicUUID)
        ]
        
        let peripherals = initPeripherals(subscriptions: subscriptions, numberOfPeripherals: 1)
        let peripheral = peripherals.first!
        let dataStore = DataStoreMock(peripherals: peripherals)
        let thing = dataStore.things.first!
        let centralManager = CBCentralManagerMock(peripherals: peripherals)
        sut = initBluetoothThingManager(delegate: delegate,
                                        subscriptions: subscriptions,
                                        dataStore: dataStore,
                                        centralManager: centralManager)

        // When
        centralManager._state = .poweredOn
        sut.knownPeripherals = Set(peripherals)
        peripheral._state = .connected
        sut.centralManager(sut.centralManager, didConnect: peripheral)
        
        // Then
        XCTAssertEqual(peripheral.discoverServicesCalled, 1)
        XCTAssertNil(peripheral.discoverServices)
//        XCTAssertEqual(delegate.didUpdateLocationCalled, 1)
        XCTAssertNotNil(thing.deregister)
        XCTAssertNotNil(thing.request)
    }
    
    func testDidDisconnect() {
        // Given
        let serviceUUID = CBUUID(string: "FFF0")
        let characteristicUUID = CBUUID(string: "FFF1")
        
        let subscriptions = [
            Subscription(serviceUUID: serviceUUID, characteristicUUID: characteristicUUID)
        ]
        
        let peripherals = initPeripherals(subscriptions: subscriptions, numberOfPeripherals: 1)
        let peripheral = peripherals.first!
        let dataStore = DataStoreMock(peripherals: peripherals)
        let centralManager = CBCentralManagerMock(peripherals: peripherals)
        sut = initBluetoothThingManager(delegate: delegate,
                                        subscriptions: subscriptions,
                                        dataStore: dataStore,
                                        centralManager: centralManager)

        // When
        centralManager._state = .poweredOn
        sut.centralManager(sut.centralManager, didDisconnectPeripheral: peripheral, error: nil)
        
        // Then
        XCTAssertEqual(centralManager.connectCalled, 1)
        XCTAssertEqual(centralManager.connectPeripheral, peripheral)
    }
    
    func testDidDiscover() {
        // Given
        let serviceUUID = CBUUID(string: "FFF0")
        let characteristicUUID = CBUUID(string: "FFF1")
        
        let subscriptions = [
            Subscription(serviceUUID: serviceUUID, characteristicUUID: characteristicUUID)
        ]

        let peripherals = initPeripherals(subscriptions: subscriptions, numberOfPeripherals: 1)
        let peripheral = peripherals.first!
        let dataStore = DataStoreMock(peripherals: peripherals)
        let thing = dataStore.things.first!
        let centralManager = CBCentralManagerMock(peripherals: peripherals)
        sut = initBluetoothThingManager(delegate: delegate,
                                        subscriptions: subscriptions,
                                        dataStore: dataStore,
                                        centralManager: centralManager)
        centralManager._state = .poweredOn

        // When
        thing.autoReconnect = false
        sut.centralManager(sut.centralManager,
                           didDiscover: peripheral,
                           advertisementData: [CBAdvertisementDataServiceUUIDsKey: [serviceUUID]],
                           rssi: 100)
       
        // Then
        XCTAssertEqual(centralManager.connectCalled, 0)
        
        // When
        thing.autoReconnect = true
        sut.centralManager(sut.centralManager,
                           didDiscover: peripheral,
                           advertisementData: [CBAdvertisementDataServiceUUIDsKey: [serviceUUID]],
                           rssi: 100)
        
        // Then
        XCTAssertEqual(centralManager.connectCalled, 1)
        XCTAssertEqual(centralManager.connectPeripheral, peripheral)
    }
    
    func testDidDiscoverNewThing() {
        // Given
        let serviceUUID = CBUUID(string: "FFF0")
        let characteristicUUID = CBUUID(string: "FFF1")
        
        let subscriptions = [
            Subscription(serviceUUID: serviceUUID, characteristicUUID: characteristicUUID)
        ]

        let peripherals = initPeripherals(subscriptions: subscriptions, numberOfPeripherals: 1)
        let peripheral = peripherals.first!
        let dataStore = DataStoreMock(peripherals: [])
        let centralManager = CBCentralManagerMock(peripherals: [])
        sut = initBluetoothThingManager(delegate: delegate,
                                        subscriptions: subscriptions,
                                        dataStore: dataStore,
                                        centralManager: centralManager)
        
        // When
        centralManager._state = .poweredOn
        sut.centralManager(sut.centralManager,
                           didDiscover: peripheral,
                           advertisementData: [CBAdvertisementDataServiceUUIDsKey: [serviceUUID]],
                           rssi: 100)
        
        // Then
        XCTAssertNotNil(delegate.foundThing)
        XCTAssertNil(delegate.foundThing?.name)
        XCTAssertEqual(delegate.didFoundThingCalled, 1)
        XCTAssertEqual(delegate.didFoundThingRSSI, 100)
        XCTAssertEqual(sut.knownThings.count, 1)
        XCTAssertEqual(delegate.foundThing?.id, peripheral.identifier)
        XCTAssertEqual(dataStore.things.count, 0)
        
        // When discover again
        peripheral._name = "beef"
        sut.centralManager(sut.centralManager,
                           didDiscover: peripheral,
                           advertisementData: [CBAdvertisementDataServiceUUIDsKey: [serviceUUID]],
                           rssi: 100)
        
        // Then
        // should update name
        XCTAssertEqual(sut.knownThings.count, 1)
        XCTAssertEqual(delegate.foundThing?.name, "beef")
        
        // When
        delegate.foundThing?.register()
        
        // Then
        XCTAssertEqual(dataStore.things.count, 1)
        XCTAssertEqual(centralManager.connectCalled, 1)
        XCTAssertEqual(centralManager.connectPeripheral, peripheral)
        
        // When
        delegate.foundThing?.deregister()
        
        // Then
        XCTAssertEqual(dataStore.things.count, 0)
        XCTAssertEqual(centralManager.cancelConnectionCalled, 1)
        XCTAssertEqual(centralManager.cancelConnectionPeripheral, peripheral)
    }
    
    func testDidDiscoverUnsubscribedPeripheral() {
        // Given
        let serviceUUID = CBUUID(string: "FFF0")
        let characteristicUUID = CBUUID(string: "FFF1")
        
        let subscriptions = [
            Subscription(serviceUUID: serviceUUID, characteristicUUID: characteristicUUID)
        ]

        let unsubscribedPeripheral = CBPeripheralMock(identifier: UUID())
        let unknownServiceUUIDs = [CBUUID(string: "BEEF")]
        let dataStore = DataStoreMock(peripherals: [])
        let centralManager = CBCentralManagerMock(peripherals: [])
        sut = initBluetoothThingManager(delegate: delegate,
                                        subscriptions: subscriptions,
                                        dataStore: dataStore,
                                        centralManager: centralManager)
        
        // When
        centralManager._state = .poweredOn
        sut.centralManager(sut.centralManager,
                           didDiscover: unsubscribedPeripheral,
                           advertisementData: [CBAdvertisementDataServiceUUIDsKey: unknownServiceUUIDs],
                           rssi: 100)
        
        // Then
        // should not connect unsubscribed peripheral
        XCTAssertEqual(centralManager.connectCalled, 0)
    }
    
    func testDidDiscoverServices() {
        // Given
        let serviceUUID = CBUUID(string: "FFF0")
        let characteristicUUID = CBUUID(string: "FFF1")
        
        let subscriptions = [
            Subscription(serviceUUID: serviceUUID, characteristicUUID: characteristicUUID)
        ]
        
        let peripherals = initPeripherals(subscriptions: subscriptions, numberOfPeripherals: 1)
        let peripheral = peripherals.first!
        // unsubscribed services
        peripheral._services?.append(CBServiceMock(uuid: CBUUID(string: "EEE1")))
        peripheral._services?.append(CBServiceMock(uuid: CBUUID(string: "EEE2")))
        
        let dataStore = DataStoreMock(peripherals: peripherals)
        let centralManager = CBCentralManagerMock(peripherals: peripherals)
        sut = initBluetoothThingManager(delegate: delegate,
                                        subscriptions: subscriptions,
                                        dataStore: dataStore,
                                        centralManager: centralManager)

        // When
        centralManager._state = .poweredOn
        sut.peripheral(peripheral, didDiscoverServices: nil)
        
        // Then
        XCTAssertEqual(peripheral.discoverCharacteristicsCalled, 1)
        XCTAssertEqual(peripheral.discoverCharacteristicsService, peripheral.services?.first)
        XCTAssertEqual(peripheral.discoverCharacteristics, peripheral.services?.first?.characteristics?.map({$0.uuid}))
    }
    
    func testDidDiscoverCharacteristics() {
        // Given
        let serviceUUID = CBUUID(string: "FFF0")
        let characteristicUUID = CBUUID(string: "FFF1")
        
        let subscriptions = [
            Subscription(serviceUUID: serviceUUID, characteristicUUID: characteristicUUID)
        ]
        
        let peripherals = initPeripherals(subscriptions: subscriptions, numberOfPeripherals: 1)
        let peripheral = peripherals.first!
        let dataStore = DataStoreMock(peripherals: peripherals)
        let centralManager = CBCentralManagerMock(peripherals: peripherals)
        sut = initBluetoothThingManager(delegate: delegate,
                                        subscriptions: subscriptions,
                                        dataStore: dataStore,
                                        centralManager: centralManager)
        peripheral.delegate = sut

        // When
        centralManager._state = .poweredOn
        peripheral.delegate = sut
        sut.peripheral(peripheral, didDiscoverCharacteristicsFor: peripheral.services!.first!, error: nil)
        
        // Then
        XCTAssertEqual(peripheral.readValueCalled, 1)
        XCTAssertEqual(peripheral.readValueCharacteristics.last?.uuid, characteristicUUID)
        XCTAssertEqual(peripheral.setNotifyValueCalled, 1)
        XCTAssertEqual(peripheral.setNotifyValueEnabled, true)
        XCTAssertEqual(peripheral.setNotifyValueCharacteristics.last?.uuid, characteristicUUID)
    }
    
    func testDidUpdateValue() {
        // Given
        let serviceUUID = CBUUID(string: "FFF0")
        let characteristicUUID = CBUUID(string: "FFF1")
        
        let subscriptions = [
            Subscription(serviceUUID: serviceUUID, characteristicUUID: characteristicUUID)
        ]
        
        let peripherals = initPeripherals(subscriptions: subscriptions, numberOfPeripherals: 1)
        let peripheral = peripherals.first!
        let dataStore = DataStoreMock(peripherals: peripherals)
        let centralManager = CBCentralManagerMock(peripherals: peripherals)
        sut = initBluetoothThingManager(delegate: delegate,
                                        subscriptions: subscriptions,
                                        dataStore: dataStore,
                                        centralManager: centralManager)
        
        let characteristic = peripheral.services?.first?.characteristics?.first as! CBCharacteristicMock
        let value = Data()
        characteristic._value = value

        // When
        centralManager._state = .poweredOn
        centralManager.connect(peripheral, options: nil)
        sut.peripheral(peripheral, didUpdateValueFor: characteristic, error: nil)
        let thing = delegate.didUpdateValueThing
        
        // Then
        XCTAssertEqual(delegate.didUpdateValueCalled, 1)
        XCTAssertEqual(thing?.id, peripheral.identifier)
        XCTAssertEqual(delegate.didUpdateValueCharacteristic?.serviceUUID, serviceUUID)
        XCTAssertEqual(delegate.didUpdateValueCharacteristic?.uuid, characteristicUUID)
        XCTAssertEqual(delegate.didUpdateValueSubscription?.serviceUUID, subscriptions.first?.serviceUUID)
        XCTAssertEqual(delegate.didUpdateValueSubscription?.characteristicUUID, subscriptions.first?.characteristicUUID)
        XCTAssertEqual(delegate.didUpdateValue, value)
        XCTAssertEqual(thing?.characteristics[BTCharacteristic(characteristic: characteristic)], value)

        // When
        characteristic._value = nil
        sut.peripheral(peripheral, didUpdateValueFor: characteristic, error: nil)
        
        // Then
        XCTAssertEqual(delegate.didUpdateValueCalled, 2)
        XCTAssertNotNil(thing)
        XCTAssertNil(thing?.characteristics[BTCharacteristic(characteristic: characteristic)])
    }
    
    func testDidReadRSSI() {
        // Given
        let serviceUUID = CBUUID(string: "FFF0")
        let characteristicUUID = CBUUID(string: "FFF1")
        
        let subscriptions = [
            Subscription(serviceUUID: serviceUUID, characteristicUUID: characteristicUUID)
        ]
        
        let peripherals = initPeripherals(subscriptions: subscriptions, numberOfPeripherals: 1)
        let peripheral = peripherals.first!
        let dataStore = DataStoreMock(peripherals: peripherals)
        let centralManager = CBCentralManagerMock(peripherals: peripherals)
        sut = initBluetoothThingManager(delegate: delegate,
                                        subscriptions: subscriptions,
                                        dataStore: dataStore,
                                        centralManager: centralManager)
        
        // When
        sut.peripheral(peripheral, didReadRSSI: 99, error: nil)
        
        // Then
        XCTAssertEqual(delegate.didChangeRSSICalled, 1)
        XCTAssertEqual(delegate.didChangeRSSIThing?.id, peripheral.identifier)
        XCTAssertEqual(delegate.didChangeRSSI, 99)
    }

    func testDidFailToConnect() {
        // Given
        let serviceUUID = CBUUID(string: "FFF0")
        let characteristicUUID = CBUUID(string: "FFF1")
        
        let subscriptions = [
            Subscription(serviceUUID: serviceUUID, characteristicUUID: characteristicUUID)
        ]
        
        let peripherals = initPeripherals(subscriptions: subscriptions, numberOfPeripherals: 1)
        let peripheral = peripherals.first!
        let dataStore = DataStoreMock(peripherals: peripherals)
        let centralManager = CBCentralManagerMock(peripherals: peripherals)
        sut = initBluetoothThingManager(delegate: delegate,
                                        subscriptions: subscriptions,
                                        dataStore: dataStore,
                                        centralManager: centralManager)

        // When
        centralManager._state = .poweredOn
        let error = NSError(domain: "error", code: 0, userInfo: nil)
        sut.centralManager(sut.centralManager,
                           didFailToConnect: peripheral,
                           error: error)
        
        // Then
        XCTAssertEqual(delegate.didFailToConnectCalled, 1)
        XCTAssertEqual(delegate.didFailToConnectThing?.id, peripheral.identifier)
        XCTAssertEqual(delegate.didFailToConnectError as NSError?, error)
    }
    
    func testDidLoseThing() {
        // Given
        let serviceUUID = CBUUID(string: "FFF0")
        let characteristicUUID = CBUUID(string: "FFF1")
        
        let subscriptions = [
            Subscription(serviceUUID: serviceUUID, characteristicUUID: characteristicUUID)
        ]

        let peripherals = initPeripherals(subscriptions: subscriptions, numberOfPeripherals: 1)
        let peripheral = peripherals.first!
        let dataStore = DataStoreMock(peripherals: [])
        let centralManager = CBCentralManagerMock(peripherals: peripherals)
        sut = initBluetoothThingManager(delegate: delegate,
                                        subscriptions: subscriptions,
                                        dataStore: dataStore,
                                        centralManager: centralManager)
        
        sut.loseThingAfterTimeInterval = 0.5
        
        // When
        centralManager._state = .poweredOn
        sut.startScanning(allowDuplicates: true)
        
        
        // Then
        XCTAssertEqual(delegate.didFoundThingCalled, 1)
        XCTAssertEqual(delegate.didLoseThingCalled, 0)
        wait(for: [delegate.didLoseThingExpectation], timeout: 2)
        XCTAssertEqual(delegate.didLoseThingCalled, 1)
        XCTAssertEqual(delegate.didLoseThing?.id, peripheral.identifier)
    }
    
    func testDeregistering() {
        // Given
        let serviceUUID = CBUUID(string: "FFF0")
        let characteristicUUID = CBUUID(string: "FFF1")
        
        let subscriptions = [
            Subscription(serviceUUID: serviceUUID, characteristicUUID: characteristicUUID)
        ]

        let peripherals = initPeripherals(subscriptions: subscriptions, numberOfPeripherals: 1)
        let dataStore = DataStoreMock(peripherals: [])
        let centralManager = CBCentralManagerMock(peripherals: peripherals)
        sut = initBluetoothThingManager(delegate: delegate,
                                        subscriptions: subscriptions,
                                        dataStore: dataStore,
                                        centralManager: centralManager)
        
        sut.loseThingAfterTimeInterval = 0.5
        
        // When
        centralManager._state = .poweredOn
        sut.startScanning(allowDuplicates: true)

        
        // Then
        guard let thing = delegate.foundThing else {
            XCTFail("should find thing")
            return
        }
        
        // When
        thing.register()
        
        // Then
        XCTAssertEqual(delegate.didFoundThingCalled, 1)
        // state will be changed to connecting then connected, so count is 2
        XCTAssertEqual(delegate.didChangeStateCalled, 2)
        
        // When
        thing.deregister()
        
        // Then
        // state will be changed to disconnecting then disconnected, so count is 4
        XCTAssertEqual(delegate.didChangeStateCalled, 4)
    }
    
    func testDidConnectThing() {
        // Given
        let serviceUUID = CBUUID(string: "FFF0")
        let characteristicUUID = CBUUID(string: "FFF1")
        
        let subscriptions = [
            Subscription(serviceUUID: serviceUUID, characteristicUUID: characteristicUUID)
        ]

        let peripherals = initPeripherals(subscriptions: subscriptions, numberOfPeripherals: 1)
        let peripheral = peripherals.first!
        let dataStore = DataStoreMock(peripherals: peripherals)
        let thing = dataStore.things.first!
        thing.autoReconnect = true
        let centralManager = CBCentralManagerMock(peripherals: peripherals)
        sut = initBluetoothThingManager(delegate: delegate,
                                        subscriptions: subscriptions,
                                        dataStore: dataStore,
                                        centralManager: centralManager)

        // When
        sut.centralManager(sut.centralManager,
                           didDiscover: peripheral,
                           advertisementData: [CBAdvertisementDataServiceUUIDsKey: [serviceUUID]],
                           rssi: 100)
        
        // Then
        XCTAssertEqual(peripheral.didReadRSSICalled, 1)
        XCTAssertEqual(peripheral.discoverServicesCalled, 1)
        XCTAssertEqual(peripheral.readValueCalled, 1) // read once for subscription
        XCTAssertNotNil(thing.request)
        
        // When
        let characteristic = BTCharacteristic(service: "FFF0", characteristic: "FFF1")
        let readRequest = BTRequest(method: .read, characteristic: characteristic, value: nil)
        let readRespond = thing.request(readRequest)
        
        // Then
        XCTAssertEqual(readRespond, true)
        XCTAssertEqual(peripheral.readValueCalled, 2)
        XCTAssertEqual(peripheral.readValueCharacteristics.last?.uuid, characteristicUUID)
        
        // When
        let data = Data()
        let writeRequest = BTRequest(method: .write, characteristic: characteristic, value: data)
        let writeRespond = thing.request(writeRequest)
        
        // Then
        XCTAssertEqual(writeRespond, true)
        XCTAssertEqual(peripheral.writeValueCalled, 1)
        XCTAssertEqual(peripheral.writeValueCharacteristic?.uuid, characteristicUUID)
        XCTAssertEqual(peripheral.writeValueData, data)
        XCTAssertEqual(peripheral.writeValueType, .withResponse)
    }
    
    func testDidUpdateCharacteristic() {
        // Given
        let serviceUUID = CBUUID(string: "FFF0")
        let characteristicUUID = CBUUID(string: "FFF1")
        
        let subscriptions = [
            Subscription(serviceUUID: serviceUUID, characteristicUUID: characteristicUUID)
        ]

        let peripherals = initPeripherals(subscriptions: subscriptions, numberOfPeripherals: 1)
        let peripheral = peripherals.first!
        let dataStore = DataStoreMock(peripherals: peripherals)
        let centralManager = CBCentralManagerMock(peripherals: peripherals)
        sut = initBluetoothThingManager(delegate: delegate,
                                        subscriptions: subscriptions,
                                        dataStore: dataStore,
                                        centralManager: centralManager)

        // When
        let serialNumberCharacter = CBCharacteristicMock(.serialNumber)
        serialNumberCharacter._value = Data(hexString: "ffff")
        sut.peripheral(peripheral, didUpdateValueFor: serialNumberCharacter, error: nil)
        
        // Then
        XCTAssertEqual(dataStore.saveThingCalled, 1)
        XCTAssertNotNil(dataStore.savedThing)
        XCTAssertEqual(dataStore.savedThing?.hardwareSerialNumber, "ffff")
    }
    
    func testBluetoothThing() {
        // Given
        let serviceUUID = CBUUID(string: "FFF0")
        let characteristicUUID1 = CBUUID(string: "FFF1")
        let characteristicUUID2 = CBUUID(string: "FFF2")

        let subscriptions = [
            Subscription(serviceUUID: serviceUUID, characteristicUUID: characteristicUUID1),
            Subscription(serviceUUID: serviceUUID, characteristicUUID: characteristicUUID2)
        ]

        let peripherals = initPeripherals(subscriptions: subscriptions, numberOfPeripherals: 1)
        let peripheral = peripherals.first!
        let dataStore = DataStoreMock(peripherals: peripherals)
        let thing = dataStore.things.first!
        let centralManager = CBCentralManagerMock(peripherals: peripherals)
        centralManager._state = .poweredOn
        sut = initBluetoothThingManager(delegate: delegate,
                                        subscriptions: subscriptions,
                                        dataStore: dataStore,
                                        centralManager: centralManager)
        sut.centralManager(sut.centralManager,
                           didDiscover: peripheral,
                           advertisementData: [CBAdvertisementDataServiceUUIDsKey: [serviceUUID]],
                           rssi: -10)
        
        // When
        thing.connect()
        // Then should subscribe
        XCTAssertEqual(peripheral.state, .connected)
        XCTAssertTrue(dataStore.things.contains(thing))
        XCTAssertFalse(thing.autoReconnect)
        XCTAssertEqual(peripheral.discoverServicesCalled, 1)
        XCTAssertNil(peripheral.discoverServices)
        XCTAssertEqual(peripheral.discoverCharacteristicsCalled, 1)
        XCTAssertEqual(Set(peripheral.discoverCharacteristics),
                       Set(subscriptions.compactMap({$0.characteristicUUID})))
        XCTAssertEqual(peripheral.readValueCalled, 2)
        XCTAssertEqual(Set(peripheral.readValueCharacteristics.map{$0.uuid}),
                       Set(subscriptions.compactMap({$0.characteristicUUID})))
        XCTAssertEqual(peripheral.setNotifyValueCalled, 2)
        XCTAssertEqual(peripheral.setNotifyValueEnabled, true)
        XCTAssertEqual(Set(peripheral.setNotifyValueCharacteristics.map{$0.uuid}),
                       Set(subscriptions.compactMap({$0.characteristicUUID})))
        
        XCTAssertTrue(thing.hasService(.batteryService))
        XCTAssertTrue(thing.hasService(.deviceInformation))
        XCTAssertTrue(thing.hasService(BTService(service: "FFF0")))
        XCTAssertFalse(thing.hasService(.cyclingPowerService))
        
        // When
        thing.register()
        // Then
        XCTAssertTrue(dataStore.things.contains(thing))
        XCTAssertTrue(thing.autoReconnect)
        
        // When read unsubscribed characteristic
        thing.read(.cscMeasurement)
        // Then
        XCTAssertEqual(peripheral.discoverCharacteristicsCalled, 2)
        XCTAssertEqual(peripheral.discoverCharacteristics, [BTCharacteristic.cscMeasurement.uuid])
        XCTAssertEqual(peripheral.readValueCalled, 3)
        XCTAssertEqual(peripheral.readValueCharacteristics.last?.uuid, BTCharacteristic.cscMeasurement.uuid)

        // When
        thing.write(.cscMeasurement, value: Data(hexString: "ff"))
        // Then
        XCTAssertEqual(peripheral.writeValueCalled, 1)
        XCTAssertEqual(peripheral.writeValueCharacteristic?.uuid, BTCharacteristic.cscMeasurement.uuid)
        XCTAssertEqual(peripheral.writeValueData?.int, 255)
        
        // When
        thing.unsubscribe()
        // Then
        XCTAssertEqual(peripheral.setNotifyValueCalled, 4)
        XCTAssertEqual(peripheral.setNotifyValueEnabled, false)
        XCTAssertEqual(Set(peripheral.setNotifyValueCharacteristics.suffix(from: 2).map{$0.uuid}),
                       Set(subscriptions.compactMap({$0.characteristicUUID})))
        
        // When
        thing.subscribe()
        // Then
        XCTAssertEqual(peripheral.setNotifyValueCalled, 6)
        XCTAssertEqual(peripheral.setNotifyValueEnabled, true)
        XCTAssertEqual(Set(peripheral.setNotifyValueCharacteristics.suffix(from: 4).map{$0.uuid}),
                       Set(subscriptions.compactMap({$0.characteristicUUID})))
        
        // When
        thing.subscribe(Subscription(.heartRateMeasurement))
        // Then
        XCTAssertEqual(peripheral.discoverServicesCalled, 2)
        XCTAssertEqual(peripheral.discoverServices, [BTCharacteristic.heartRateMeasurement.serviceUUID])
        XCTAssertEqual(peripheral.discoverCharacteristicsCalled, 3)
        XCTAssertEqual(peripheral.discoverCharacteristics, [BTCharacteristic.heartRateMeasurement.uuid])
        XCTAssertEqual(peripheral.setNotifyValueCalled, 7)
        XCTAssertEqual(peripheral.setNotifyValueEnabled, true)
        XCTAssertEqual(peripheral.setNotifyValueCharacteristics.last?.uuid,
                       BTCharacteristic.heartRateMeasurement.uuid)

        // When
        thing.unsubscribe(Subscription(.heartRateMeasurement))
        // Then
        XCTAssertEqual(peripheral.setNotifyValueCalled, 8)
        XCTAssertEqual(peripheral.setNotifyValueEnabled, false)
        XCTAssertEqual(peripheral.setNotifyValueCharacteristics.last?.uuid,
                       BTCharacteristic.heartRateMeasurement.uuid)
        
        // When
        thing.disconnect()
        // Then
        XCTAssertEqual(centralManager.cancelConnectionCalled, 1)
        XCTAssertEqual(centralManager.cancelConnectionPeripheral, peripheral)
        XCTAssertEqual(peripheral.state, .disconnected)
        XCTAssertTrue(thing.autoReconnect)
                

        thing.deregister()
        // Then
        XCTAssertEqual(centralManager.cancelConnectionCalled, 2)
        XCTAssertFalse(thing.autoReconnect)
    }
    
    func testNearbyThings() {
        // Given
        let subscriptions = [Subscription.batteryService]
        let peripherals = initPeripherals(subscriptions: subscriptions, numberOfPeripherals: 4)
        let dataStore = DataStoreMock(peripherals: peripherals)
        let centralManager = CBCentralManagerMock(peripherals: peripherals)
        centralManager._state = .poweredOn
        
        sut = initBluetoothThingManager(delegate: delegate,
                                        subscriptions: subscriptions,
                                        dataStore: dataStore,
                                        centralManager: centralManager)
        for i in 0..<peripherals.count {
            peripherals[i]._state = ConnectionState(rawValue: i)!
            sut.peripheral(peripherals[i], didReadRSSI: -10, error: nil)
        }
        sut.centralManager(centralManager, willRestoreState: [
            CBCentralManagerRestoredStatePeripheralsKey: peripherals
        ])
        
        XCTAssertEqual(sut.nearbyThings.count, 1)
        XCTAssertEqual(sut.nearbyThings.first?.state, .connected)
    }
}
