//
//  BluetoothThingManagerTests.swift
//  BluetoothThingTests
//
//  Created by Antonio Yip on 10/01/20.
//  Copyright © 2020 Antonio Yip. All rights reserved.
//

import XCTest
import CoreBluetooth
import Mockingbird
@testable import BluetoothThing

class BluetoothThingManagerTests: XCTestCase {
    
    var sut: BluetoothThingManager!
    var subscriptions: [BTSubscription] = []
        
    class BluetoothThingManagerDelegateSpy: BluetoothThingManagerDelegate {
        func bluetoothThingManager(_ manager: BluetoothThingManager, didChangeState state: BluetoothState) {
            
        }
        
        var centralId: UUID = UUID()
        
        var didFoundThingCalled = 0
        var didFoundThingRSSI: NSNumber?
        var foundThing: BluetoothThing?
        func bluetoothThingManager(_ manager: BluetoothThingManager, didFindThing thing: BluetoothThing, advertisementData: [String : Any], rssi: NSNumber) {
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
        var didUpdateValueSubscription: BTSubscription?
        var didUpdateValue: Data?
        func bluetoothThing(_ thing: BluetoothThing, didUpdateValue value: Data?, for characteristic: BTCharacteristic, subscription: BTSubscription?) {
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
    
    func testInitializer() {
        // Given
        subscriptions = [.fff1]
        
        let peripherals = initPeripherals(subscriptions: subscriptions, numberOfPeripherals: 3)
        let dataStore = DataStoreMock(peripherals: peripherals)
        let centralManager = CBCentralManagerMock(peripherals: peripherals)

        sut = BluetoothThingManager(delegate: delegate,
                                    subscriptions: subscriptions,
                                    dataStore: dataStore,
                                    centralManager: centralManager)

        XCTAssertNotNil(sut.delegate)
        XCTAssertNotNil(sut.dataStore)
        XCTAssertNotNil(sut.centralManager.delegate)

        XCTAssertEqual(sut.subscriptions.count, 1)
        XCTAssertEqual(sut.serviceUUIDs, [.fff0])
        XCTAssertEqual(sut.things.count, 3)
        XCTAssertEqual(sut.things.first?.id, peripherals.first?.identifier)
        XCTAssertEqual(sut.things.last?.id, peripherals.last?.identifier)
    }
    
    func testPublicInitializer() {
        // Given
        subscriptions = [.fff1]
        
        sut = BluetoothThingManager(delegate: delegate,
                                    subscriptions: subscriptions,
                                    useCoreData: false,
                                    restoreID: nil)
        
        XCTAssertNotNil(sut.delegate)
        XCTAssertTrue(sut.dataStore.persistentStore is UserDefaults)
        XCTAssertEqual(sut.subscriptions, Set(subscriptions))
        sut.dataStore.persistentStore.reset()
    }

    func testStartStop() {
        // Given
        subscriptions = [.fff1]

        let peripherals = initPeripherals(subscriptions: subscriptions, numberOfPeripherals: 2)
        let dataStore = DataStoreMock(peripherals: peripherals)
        let centralManager = CBCentralManagerMock(peripherals: peripherals)
        sut = BluetoothThingManager(delegate: delegate,
                                    subscriptions: subscriptions,
                                    dataStore: dataStore,
                                    centralManager: centralManager)
        
        sut.knownThings = Set(dataStore.things.suffix(1))
        
        // When
        centralManager.setState(.poweredOff)
        sut.stopScanning()
        
        //Then
        XCTAssertFalse(sut.isPendingToStart)
        XCTAssertEqual(centralManager.stopScanCalled, 0)
        
        // When
        sut.startScanning(allowDuplicates: true)

        //Then
        XCTAssertTrue(sut.isPendingToStart)
        XCTAssertEqual(centralManager.scanForPeripheralsCalled, 0)
        XCTAssertTrue(sut.knownPeripherals.isEmpty)
        
        
        // When
        centralManager.setState(.poweredOn)
        sut.centralManagerDidUpdateState(centralManager)
        
        //Then
        XCTAssertEqual(delegate.didLoseThingCalled, 1)
        XCTAssertEqual(delegate.didLoseThing?.id, sut.knownThings.first?.id)
        XCTAssertFalse(sut.isPendingToStart)
        XCTAssertEqual(centralManager.stopScanCalled, 1)
        XCTAssertEqual(centralManager.scanForPeripheralsCalled, 1)
        XCTAssertEqual(centralManager.scanForPeripheralsServiceUUIDs, [.fff0])

        // When
        sut.stopScanning()
        
        //Then
        XCTAssertFalse(sut.isPendingToStart)
        XCTAssertEqual(centralManager.stopScanCalled, 2)
    }
    
    func testRestoreState() {
        // Given
        subscriptions = [.fff1]
        
        let peripherals = initPeripherals(subscriptions: subscriptions, numberOfPeripherals: 1)
        let peripheral = peripherals.first!
        let dataStore = DataStoreMock(peripherals: peripherals)
        let thing = dataStore.things.first!
        let centralManager = CBCentralManagerMock(peripherals: peripherals)
        sut = BluetoothThingManager(delegate: delegate,
                                    subscriptions: subscriptions,
                                    dataStore: dataStore,
                                    centralManager: centralManager)
        given(peripheral.delegate).willReturn(sut)
        
        // When
        let restoreScanServiceUUIDs: [CBUUID] = []
        let restorePeripherals = peripherals
        
        peripheral.setState(.connected)
        let restoreState: [String: Any] = [
            CBCentralManagerRestoredStateScanServicesKey: restoreScanServiceUUIDs,
            CBCentralManagerRestoredStatePeripheralsKey: restorePeripherals
        ]
        sut.centralManager(sut.centralManager, willRestoreState: restoreState)
        
        centralManager.setState(.poweredOn)
        sut.centralManagerDidUpdateState(centralManager)
        
        // Then
        XCTAssertNotNil(thing._disconnect)
        XCTAssertEqual(delegate.didChangeStateThing?.id, peripheral.identifier)
        XCTAssertEqual(delegate.didChangeStateThing?.state, .connected)
        XCTAssertEqual(delegate.didChangeState, .connected)
        XCTAssertEqual(delegate.didChangeStateCalled, 1)
        verify(peripheral.discoverServices(nil)).wasCalled(1)
    }
    

    func testPowerOff() {
        // Given
        subscriptions = [.fff1]
        
        let peripherals = initPeripherals(subscriptions: subscriptions, numberOfPeripherals: 1)
        let dataStore = DataStoreMock(peripherals: peripherals)
        let centralManager = CBCentralManagerMock(peripherals: peripherals)
        sut = BluetoothThingManager(delegate: delegate,
                                    subscriptions: subscriptions,
                                    dataStore: dataStore,
                                    centralManager: centralManager)

        dataStore.things.first?.state = .connected
        sut.knownThings = Set(dataStore.things)
        sut.knownPeripherals = Set(peripherals)
        
        // When
        centralManager.setState(.poweredOff)
        sut.centralManagerDidUpdateState(sut.centralManager)
        
        // Then
        XCTAssertEqual(delegate.didChangeStateCalled, 1)
        XCTAssertEqual(delegate.didChangeState, .disconnected)
        XCTAssertEqual(delegate.didLoseThingCalled, 1)
        XCTAssertTrue(sut.isPendingToStart)
    }
    
    func testDidConnect() {
        // Given
        subscriptions = [.fff1]

        let peripherals = initPeripherals(subscriptions: subscriptions, numberOfPeripherals: 1)
        let peripheral = peripherals.first!
        let dataStore = DataStoreMock(peripherals: peripherals)
        let thing = dataStore.things.first!
        let centralManager = CBCentralManagerMock(peripherals: peripherals)
        sut = BluetoothThingManager(delegate: delegate,
                                    subscriptions: subscriptions,
                                    dataStore: dataStore,
                                    centralManager: centralManager)
        given(peripheral.delegate).willReturn(sut)

        // When
        centralManager.setState(.poweredOn)
        sut.knownPeripherals = Set(peripherals)
        peripheral.setState(.connected)
        sut.setupThing(thing, for: peripheral)
        sut.centralManager(sut.centralManager, didConnect: peripheral)
        
        // Then
        verify(peripheral.discoverServices(nil)).wasCalled(1)
        XCTAssertNotNil(thing._disconnect)
        XCTAssertNotNil(thing._notify)
        XCTAssertNotNil(thing._subscribe)
        XCTAssertNotNil(thing._unsubscribe)
        XCTAssertNotNil(thing._request)
    }
    
    func testDidDisconnect() {
        // Given
        subscriptions = [.fff1]

        let peripherals = initPeripherals(subscriptions: subscriptions, numberOfPeripherals: 1)
        let peripheral = peripherals.first!
        let dataStore = DataStoreMock(peripherals: peripherals)
        let centralManager = CBCentralManagerMock(peripherals: peripherals)
        sut = BluetoothThingManager(delegate: delegate,
                                    subscriptions: subscriptions,
                                    dataStore: dataStore,
                                    centralManager: centralManager)
        given(peripheral.delegate).willReturn(sut)

        // When
        centralManager.setState(.poweredOn)
        sut.centralManager(sut.centralManager, didDisconnectPeripheral: peripheral, error: nil)
        
        // Then
        XCTAssertEqual(centralManager.connectCalled, 1)
        XCTAssertEqual(centralManager.connectPeripheral, peripheral)
    }
    
    func testDidDiscover() {
        // Given
        subscriptions = [.fff1]

        let peripherals = initPeripherals(subscriptions: subscriptions, numberOfPeripherals: 1)
        let peripheral = peripherals.first!
        let dataStore = DataStoreMock(peripherals: peripherals)
        let thing = dataStore.things.first!
        let centralManager = CBCentralManagerMock(peripherals: peripherals)
        sut = BluetoothThingManager(delegate: delegate,
                                    subscriptions: subscriptions,
                                    dataStore: dataStore,
                                    centralManager: centralManager)
        centralManager.setState(.poweredOn)
        given(peripheral.delegate).willReturn(sut)

        // When
        thing.pendingConnect = false
        sut.centralManager(sut.centralManager,
                           didDiscover: peripheral,
                           advertisementData: [CBAdvertisementDataServiceUUIDsKey: [CBUUID.fff0]],
                           rssi: 100)
       
        // Then
        XCTAssertEqual(centralManager.connectCalled, 0)
        
        // When
        thing.pendingConnect = true
        sut.centralManager(sut.centralManager,
                           didDiscover: peripheral,
                           advertisementData: [CBAdvertisementDataServiceUUIDsKey: [CBUUID.fff0]],
                           rssi: 100)
        
        // Then
        XCTAssertEqual(centralManager.connectCalled, 1)
        XCTAssertEqual(centralManager.connectPeripheral, peripheral)
    }
    
    func testDidDiscoverNewThing() {
        // Given
        subscriptions = [.fff1]

        let peripherals = initPeripherals(subscriptions: subscriptions, numberOfPeripherals: 1)
        let peripheral = peripherals.first!
        let dataStore = DataStoreMock(peripherals: [])
        let centralManager = CBCentralManagerMock(peripherals: [])
        sut = BluetoothThingManager(delegate: delegate,
                                    subscriptions: subscriptions,
                                    dataStore: dataStore,
                                    centralManager: centralManager)
        given(peripheral.delegate).willReturn(sut)

        // When
        centralManager.setState(.poweredOn)
        sut.centralManager(sut.centralManager,
                           didDiscover: peripheral,
                           advertisementData: [CBAdvertisementDataServiceUUIDsKey: [CBUUID.fff0]],
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
        
        given(peripheral.name).willReturn("beef")
        sut.centralManager(sut.centralManager,
                           didDiscover: peripheral,
                           advertisementData: [CBAdvertisementDataServiceUUIDsKey: [CBUUID.fff0]],
                           rssi: 100)
        
        // Then
        // should update name
        XCTAssertEqual(sut.knownThings.count, 1)
        XCTAssertEqual(delegate.foundThing?.name, "beef")
        
        // When
        delegate.foundThing?.connect()
        
        // Then
        XCTAssertEqual(dataStore.things.count, 1)
        XCTAssertEqual(centralManager.connectCalled, 1)
        XCTAssertEqual(centralManager.connectPeripheral, peripheral)
        
        // When
        delegate.foundThing?.forget()
        
        // Then
        XCTAssertEqual(dataStore.things.count, 0)
        XCTAssertEqual(centralManager.cancelConnectionCalled, 1)
        XCTAssertEqual(centralManager.cancelConnectionPeripheral, peripheral)
    }

    func testDidDiscoverUnsubscribedPeripheral() {
        // Given
        subscriptions = [.fff1]

        let unsubscribedPeripheral = CBPeripheral.mock(identifier: UUID())
        let unknownServiceUUIDs = [CBUUID(string: "BEEF")]
        let dataStore = DataStoreMock(peripherals: [])
        let centralManager = CBCentralManagerMock(peripherals: [])
        sut = BluetoothThingManager(delegate: delegate,
                                    subscriptions: subscriptions,
                                    dataStore: dataStore,
                                    centralManager: centralManager)
        
        // When
        centralManager.setState(.poweredOn)
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
        subscriptions = [.fff1, .fff2]

        let peripherals = initPeripherals(subscriptions: subscriptions, numberOfPeripherals: 1)
        let peripheral = peripherals.first!
        
        // unsubscribed services
//        peripheral._services?.append(CBServiceMock(uuid: CBUUID(string: "EEE1")))
//        peripheral._services?.append(CBServiceMock(uuid: CBUUID(string: "EEE2")))
        //        let service = CBService.mock(uuid: .fff0)
        //        given(peripheral.services).willReturn([
        //            service
        //        ])
        
        let dataStore = DataStoreMock(peripherals: peripherals)
        let centralManager = CBCentralManagerMock(peripherals: peripherals)
        sut = BluetoothThingManager(delegate: delegate,
                                    subscriptions: subscriptions,
                                    dataStore: dataStore,
                                    centralManager: centralManager)
        given(peripheral.delegate).willReturn(sut)

        // When
        centralManager.setState(.poweredOn)
        sut.peripheral(peripheral, didDiscoverServices: nil)
        
        // Then
        // should not discover unsubscribed services
        verify(peripheral.discoverCharacteristics(firstArg(any()), for: any())).wasCalled(1)
    }

    func testDidDiscoverCharacteristics() {
        // Given
        subscriptions = [.fff1]

        let peripherals = initPeripherals(subscriptions: subscriptions, numberOfPeripherals: 1)
        let peripheral = peripherals.first!
        let dataStore = DataStoreMock(peripherals: peripherals)
        let centralManager = CBCentralManagerMock(peripherals: peripherals)
        sut = BluetoothThingManager(delegate: delegate,
                                    subscriptions: subscriptions,
                                    dataStore: dataStore,
                                    centralManager: centralManager)
        given(peripheral.delegate).willReturn(sut)
       
        // When
        centralManager.setState(.poweredOn)
        sut.peripheral(peripheral, didDiscoverCharacteristicsFor: peripheral.services!.first!, error: nil)
        
        // Then
        let characteristic = peripheral.services!.first!.characteristics!.first!
        verify(peripheral.readValue(for: characteristic)).wasCalled(1)
        verify(peripheral.setNotifyValue(true, for: characteristic)).wasCalled(1)
        XCTAssertTrue(characteristic.isNotifying)
    }

    func testDidUpdateValue() {
        // Given
        subscriptions = [.fff1]

        let peripherals = initPeripherals(subscriptions: subscriptions, numberOfPeripherals: 1)
        let peripheral = peripherals.first!
        let dataStore = DataStoreMock(peripherals: peripherals)
        let centralManager = CBCentralManagerMock(peripherals: peripherals)
        sut = BluetoothThingManager(delegate: delegate,
                                    subscriptions: subscriptions,
                                    dataStore: dataStore,
                                    centralManager: centralManager)
        
        let characteristic = peripheral.services!.first!.characteristics!.first!
        let value = "test".data(using: .utf8)
        given(characteristic.value).willReturn(value)
        given(peripheral.delegate).willReturn(sut)

        // When
        centralManager.setState(.poweredOn)
        centralManager.connect(peripheral, options: nil)
        sut.peripheral(peripheral, didUpdateValueFor: characteristic, error: nil)
        let thing = delegate.didUpdateValueThing
        
        // Then
        XCTAssertEqual(delegate.didUpdateValueCalled, 1)
        XCTAssertEqual(thing?.id, peripheral.identifier)
        XCTAssertEqual(delegate.didUpdateValueCharacteristic?.serviceUUID, .fff0)
        XCTAssertEqual(delegate.didUpdateValueCharacteristic?.uuid, .fff1)
        XCTAssertEqual(delegate.didUpdateValueSubscription?.serviceUUID, subscriptions.first?.serviceUUID)
        XCTAssertEqual(delegate.didUpdateValueSubscription?.characteristicUUID, subscriptions.first?.characteristicUUID)
        XCTAssertEqual(String(data: delegate.didUpdateValue ?? Data(), encoding: .utf8), "test")
        XCTAssertEqual(thing?.characteristics[BTCharacteristic(characteristic: characteristic)], value)

        // When
        given(characteristic.value).willReturn(nil)
        sut.peripheral(peripheral, didUpdateValueFor: characteristic, error: nil)
        
        // Then
        XCTAssertEqual(delegate.didUpdateValueCalled, 2)
        XCTAssertNotNil(thing)
        XCTAssertNil(thing?.characteristics[BTCharacteristic(characteristic: characteristic)])
    }

    func testDidReadRSSI() {
        // Given
        subscriptions = [.fff1]

        let peripherals = initPeripherals(subscriptions: subscriptions, numberOfPeripherals: 1)
        let peripheral = peripherals.first!
        let dataStore = DataStoreMock(peripherals: peripherals)
        let centralManager = CBCentralManagerMock(peripherals: peripherals)
        sut = BluetoothThingManager(delegate: delegate,
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
        subscriptions = [.fff1]

        let peripherals = initPeripherals(subscriptions: subscriptions, numberOfPeripherals: 1)
        let peripheral = peripherals.first!
        let dataStore = DataStoreMock(peripherals: peripherals)
        let centralManager = CBCentralManagerMock(peripherals: peripherals)
        sut = BluetoothThingManager(delegate: delegate,
                                    subscriptions: subscriptions,
                                    dataStore: dataStore,
                                    centralManager: centralManager)

        // When
        centralManager.setState(.poweredOn)
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
        subscriptions = [.fff1]

        let peripherals = initPeripherals(subscriptions: subscriptions, numberOfPeripherals: 1)
        let peripheral = peripherals.first!
        let dataStore = DataStoreMock(peripherals: [])
        let centralManager = CBCentralManagerMock(peripherals: peripherals)
        sut = BluetoothThingManager(delegate: delegate,
                                    subscriptions: subscriptions,
                                    dataStore: dataStore,
                                    centralManager: centralManager)
        
        
        // When
        centralManager.setState(.poweredOn)
        sut.startScanning(allowDuplicates: true, timeout: 0.5)
        
        // Then
        XCTAssertEqual(delegate.didFoundThingCalled, 1)
        XCTAssertEqual(delegate.didLoseThingCalled, 0)
        wait(for: [delegate.didLoseThingExpectation], timeout: 2)
        XCTAssertEqual(delegate.didLoseThingCalled, 1)
        XCTAssertEqual(delegate.didLoseThing?.id, peripheral.identifier)
    }
    
    func testDeregistering() {
        // Given
        subscriptions = [.fff1]

        let peripherals = initPeripherals(subscriptions: subscriptions, numberOfPeripherals: 1)
        let peripheral = peripherals.first!
        let dataStore = DataStoreMock(peripherals: [])
        let centralManager = CBCentralManagerMock(peripherals: peripherals)
        sut = BluetoothThingManager(delegate: delegate,
                                    subscriptions: subscriptions,
                                    dataStore: dataStore,
                                    centralManager: centralManager)
        
        sut.loseThingAfterTimeInterval = 0.5
        given(peripheral.delegate).willReturn(sut)

        // When
        centralManager.setState(.poweredOn)
        sut.startScanning(allowDuplicates: true)

        
        // Then
        guard let thing = delegate.foundThing else {
            XCTFail("should find thing")
            return
        }
        
        // When
        thing.connect()
        
        // Then
        XCTAssertEqual(delegate.didFoundThingCalled, 1)
        // state will be changed to connecting then connected, so count is 2
        XCTAssertEqual(delegate.didChangeStateCalled, 2)
        
        // When
        thing.forget()
        
        // Then
        XCTAssertEqual(delegate.didLoseThingCalled, 1)
        // state will be changed to disconnecting then disconnected, so count is 4
        XCTAssertEqual(delegate.didChangeStateCalled, 4)
    }
    
    func testDidConnectThing() {
        // Given
        subscriptions = [.fff1, .serialNumber]

        let peripherals = initPeripherals(subscriptions: subscriptions, numberOfPeripherals: 1)
        let peripheral = peripherals.first!
        let dataStore = DataStoreMock(peripherals: peripherals)
        let thing = dataStore.things.first!
        thing.pendingConnect = true
        let centralManager = CBCentralManagerMock(peripherals: peripherals)
        sut = BluetoothThingManager(delegate: delegate,
                                    subscriptions: subscriptions,
                                    dataStore: dataStore,
                                    centralManager: centralManager)
        given(peripheral.delegate).willReturn(sut)
        
        // When
        sut.centralManager(sut.centralManager,
                           didDiscover: peripheral,
                           advertisementData: [CBAdvertisementDataServiceUUIDsKey: [CBUUID.fff0]],
                           rssi: 100)
        
        // Then
        verify(peripheral.discoverServices(any())).wasCalled(1)
        verify(peripheral.readValue(for: any() as CBCharacteristic)).wasCalled(2) // read once for subscription plus once for serialNumber
        XCTAssertNotNil(thing.request)
        
        // When
        let characteristic = BTCharacteristic(service: BTService(service: "fff0"), characteristic: "FFF1")
        let readRequest = BTRequest(method: .read, characteristic: characteristic, value: nil)
        let readRespond = thing.request(readRequest)

        // Then
        XCTAssertEqual(readRespond, true)
        verify(peripheral.readValue(for: peripheral.services![0].characteristics![0])).wasCalled(3)
        
        // When
        let data = Data()
        let writeRequest = BTRequest(method: .write, characteristic: characteristic, value: data)
        let writeRespond = thing.request(writeRequest)
        
        // Then
        XCTAssertEqual(writeRespond, true)
        verify(peripheral.writeValue(data, for: any(), type: .withoutResponse)).wasCalled(1)
    }

    func testPendingRequest() {
        // Given
        subscriptions = [.fff1]

        let peripherals = initPeripherals(subscriptions: subscriptions, numberOfPeripherals: 1)
        let peripheral = peripherals.first!
        let dataStore = DataStoreMock(peripherals: peripherals)
        let thing = dataStore.things.first!
        let centralManager = CBCentralManagerMock(peripherals: peripherals)
        centralManager.setState(.poweredOn)
        sut = BluetoothThingManager(delegate: delegate,
                                    subscriptions: subscriptions,
                                    dataStore: dataStore,
                                    centralManager: centralManager)
        given(peripheral.delegate).willReturn(sut)

        // When
        sut.centralManager(sut.centralManager,
                           didDiscover: peripheral,
                           advertisementData: [CBAdvertisementDataServiceUUIDsKey: [CBUUID.fff0]],
                           rssi: 100)
        
        let completionExpectation = XCTestExpectation(description: "completion")
        let characteristic = BTCharacteristic(service: CBUUID.fff0.uuidString,
                                              characteristic: CBUUID.fff1.uuidString)
        let request = BTRequest(method: .write,
                                characteristic: characteristic,
                                value: Data(), completion: {
                                    completionExpectation.fulfill()
                                })
        thing.connect {
            let respond = thing.request(request)
            XCTAssertTrue(respond)
        }
        
        // Then
        XCTAssertEqual(centralManager.connectCalled, 1)
        wait(for: [completionExpectation], timeout: 2)
        verify(peripheral.writeValue(firstArg(any()), for: any(), type: .withoutResponse)).wasCalled(1)
    }
    
    func testDidUpdateCharacteristic() {
        // Given
        subscriptions = [.fff1]

        let peripherals = initPeripherals(subscriptions: subscriptions, numberOfPeripherals: 1)
        let peripheral = peripherals.first!
        let dataStore = DataStoreMock(peripherals: peripherals)
        let centralManager = CBCentralManagerMock(peripherals: peripherals)
        sut = BluetoothThingManager(delegate: delegate,
                                    subscriptions: subscriptions,
                                    dataStore: dataStore,
                                    centralManager: centralManager)

        // When
        let serialNumberCharacter = CBCharacteristic.mock(uuid: BTCharacteristic.serialNumber.uuid,
                                                          service: .mock(uuid: BTService.deviceInformation.uuid))
        given(serialNumberCharacter.value).willReturn(Data(hexString: "ffff"))
        sut.peripheral(peripheral, didUpdateValueFor: serialNumberCharacter, error: nil)
        
        // Then
        XCTAssertEqual(dataStore.saveThingCalled, 1)
        XCTAssertNotNil(dataStore.savedThing)
        XCTAssertEqual(dataStore.savedThing?.hardwareSerialNumber, "ffff")
    }
    
#if swift(<5.5)
    func testBluetoothThing() {
        // Given
        subscriptions = [.fff1, .fff2]

        let peripherals = initPeripherals(subscriptions: subscriptions, numberOfPeripherals: 1)
        let peripheral = peripherals.first!
        peripheral._services = nil
        let dataStore = DataStoreMock(peripherals: peripherals)
        let thing = dataStore.things.first!
        let centralManager = CBCentralManagerMock(peripherals: peripherals)
        centralManager._state = .poweredOn
        sut = BluetoothThingManager(delegate: delegate,
                                    subscriptions: subscriptions,
                                    dataStore: dataStore,
                                    centralManager: centralManager)
        sut.centralManager(sut.centralManager,
                           didDiscover: peripheral,
                           advertisementData: [CBAdvertisementDataServiceUUIDsKey: [CBUUID.fff0]],
                           rssi: -10)
        
        // When
        thing.connect()
        // Then should subscribe
        XCTAssertEqual(peripheral.state, .connected)
        XCTAssertTrue(dataStore.things.contains(thing))
        XCTAssertFalse(thing.pendingConnect)
        XCTAssertEqual(peripheral.discoverServicesCalled, 1)
        XCTAssertNil(peripheral.discoverServices)
        XCTAssertEqual(peripheral.discoverCharacteristicsCalled, 2) // read once for subscription plus once for serialNumber
        XCTAssertEqual(peripheral.discoverCharacteristics,
                       Set(subscriptions.compactMap({$0.characteristicUUID})))
        XCTAssertEqual(peripheral.readValueCalled, 3)
        XCTAssertEqual(Set(peripheral.readValueCharacteristics.map{$0.uuid}),
                       Set((subscriptions + [BTSubscription(.serialNumber)]).compactMap({$0.characteristicUUID})))
        XCTAssertEqual(peripheral.setNotifyValueCalled, 2)
        XCTAssertEqual(peripheral.setNotifyValueEnabled, true)
        XCTAssertEqual(Set(peripheral.setNotifyValueCharacteristics.map{$0.uuid}),
                       Set(subscriptions.compactMap({$0.characteristicUUID})))
        
        XCTAssertTrue(thing.hasService(.batteryService))
        XCTAssertTrue(thing.hasService(.deviceInformation))
        XCTAssertTrue(thing.hasService(BTService(service: "FFF0")))
        XCTAssertFalse(thing.hasService(.cyclingPowerService))
        
        // When
        thing.connect()
        // Then
        XCTAssertTrue(dataStore.things.contains(thing))
//        XCTAssertTrue(thing.pendingConnect)
        
        // When read unsubscribed characteristic
        thing.read(.cscMeasurement)
        // Then
        XCTAssertEqual(peripheral.discoverCharacteristicsCalled, 3)
        XCTAssertEqual(peripheral.discoverCharacteristics, [.fff1, .fff2, BTCharacteristic.cscMeasurement.uuid])
        XCTAssertEqual(peripheral.readValueCalled, 4)
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
        thing.subscribe(.heartRateMeasurement)
        // Then
        XCTAssertEqual(peripheral.discoverServicesCalled, 2)
        XCTAssertEqual(peripheral.discoverServices, [BTCharacteristic.heartRateMeasurement.serviceUUID])
        XCTAssertEqual(peripheral.discoverCharacteristicsCalled, 4)
        XCTAssertEqual(peripheral.discoverCharacteristics, [.fff1, .fff2, BTCharacteristic.cscMeasurement.uuid, BTCharacteristic.heartRateMeasurement.uuid])
        XCTAssertEqual(peripheral.setNotifyValueCalled, 7)
        XCTAssertEqual(peripheral.setNotifyValueEnabled, true)
        XCTAssertEqual(peripheral.setNotifyValueCharacteristics.last?.uuid,
                       BTCharacteristic.heartRateMeasurement.uuid)

        // When subscribe duplicated
        thing.subscribe(.heartRateMeasurement)
        // Then
        // discovery should not be called again
        XCTAssertEqual(peripheral.discoverServicesCalled, 2)
        XCTAssertEqual(peripheral.discoverCharacteristicsCalled, 4)
        XCTAssertEqual(peripheral.setNotifyValueCalled, 7)

        
        // When
        thing.unsubscribe(.heartRateMeasurement)
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
        XCTAssertFalse(thing.pendingConnect)
                

        thing.forget()
        // Then
        XCTAssertEqual(centralManager.cancelConnectionCalled, 1) // should call cancel connect only once
        XCTAssertFalse(thing.pendingConnect)
    }
#endif

    func testNearbyThings() {
        // Given
        subscriptions = [.batteryService]
        
        let peripherals = initPeripherals(subscriptions: subscriptions, numberOfPeripherals: 4)
        let dataStore = DataStoreMock(peripherals: peripherals)
        let centralManager = CBCentralManagerMock(peripherals: peripherals)
        centralManager.setState(.poweredOn)
        
        sut = BluetoothThingManager(delegate: delegate,
                                    subscriptions: subscriptions,
                                    dataStore: dataStore,
                                    centralManager: centralManager)
        
        // When
        for i in 0..<peripherals.count {
            peripherals[i].setState(ConnectionState(rawValue: i)!)
            given(peripherals[i].delegate).willReturn(sut)
            sut.peripheral(peripherals[i], didReadRSSI: -10, error: nil)
        }
        sut.centralManager(centralManager, willRestoreState: [
            CBCentralManagerRestoredStatePeripheralsKey: peripherals
        ])
        sut.centralManagerDidUpdateState(centralManager)
        
        // Then
        XCTAssertEqual(sut.nearbyThings.count, 1)
        XCTAssertEqual(sut.nearbyThings.first?.state, .connected)
    }

    func testPendingConnect() {
        // Given
        let uuid = UUID()
        let thing = BluetoothThing(id: uuid)
        
        XCTAssertEqual(thing.pendingConnect, false)
        
        // When
        // connect a thing without a peripheral
        thing.connect()
        
        // Then
        XCTAssertEqual(thing.pendingConnect, true)
        
        // When
        let peripheral = CBPeripheral.mock(identifier: uuid)
        let dataStore = DataStoreMock(peripherals: [])
        dataStore.things = [thing]
        let centralManager = CBCentralManagerMock(peripherals: [peripheral])
        centralManager.setState(.poweredOn)

        sut = BluetoothThingManager(delegate: delegate,
                                    subscriptions: [.batteryService],
                                    dataStore: dataStore,
                                    centralManager: centralManager)
        given(peripheral.delegate).willReturn(sut)
        
        sut.centralManager(sut.centralManager,
                           didDiscover: peripheral,
                           advertisementData: [CBAdvertisementDataServiceUUIDsKey: [BTService.batteryService.uuid]],
                           rssi: 100)

        // Then
        XCTAssertEqual(dataStore.things.count, 1)
        XCTAssertEqual(centralManager.connectCalled, 1)
        XCTAssertEqual(centralManager.connectPeripheral, peripheral)
    }

    func testScaningRefresh() {
        // Given
        subscriptions = [.batteryService]
        let dataStore = DataStoreMock(peripherals: [])
        let centralManager = CBCentralManagerMock(peripherals: [])
        centralManager.setState(.poweredOn)
        sut = BluetoothThingManager(delegate: delegate,
                                    subscriptions: subscriptions,
                                    dataStore: dataStore,
                                    centralManager: centralManager)
        
        // When
        sut.startScanning(refresh: 0.3)
        
        // Then
        XCTAssertEqual(centralManager.scanForPeripheralsCalled, 1)
        let exp = expectation(description: "exp")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            exp.fulfill()
        }
        wait(for: [exp], timeout: 2)
        XCTAssertEqual(centralManager.scanForPeripheralsCalled, 2)
    }
}
