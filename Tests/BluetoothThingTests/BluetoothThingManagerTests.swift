//
//  BluetoothThingManagerTests.swift
//  BluetoothThingTests
//
//  Created by Antonio Yip on 10/01/20.
//  Copyright © 2020 Antonio Yip. All rights reserved.
//

import XCTest
import CoreBluetooth
import CoreData
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
        
        let peripherals = [
            CBPeripheral.mock(subscriptions: subscriptions),
            CBPeripheral.mock(subscriptions: subscriptions),
            CBPeripheral.mock(subscriptions: subscriptions)
        ]
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
    
    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    func testPublicInitializerCoreData() {
        // Given
        subscriptions = [.fff1]
        
        sut = BluetoothThingManager(delegate: delegate,
                                    subscriptions: subscriptions,
                                    useCoreData: true,
                                    useCloudKit: false,
                                    restoreID: nil)
        
        XCTAssertNotNil(sut.delegate)
        XCTAssertNotNil((sut.dataStore.persistentStore as? CoreDataStore)?.persistentContainer as? NSPersistentContainer)
        XCTAssertFalse((sut.dataStore.persistentStore as? CoreDataStore)?.persistentContainer is NSPersistentCloudKitContainer)
        XCTAssertEqual(sut.subscriptions, Set(subscriptions))
        sut.dataStore.persistentStore.reset()
    }

    func testStartStop() {
        // Given
        subscriptions = [.fff1]

        let peripheral = CBPeripheral.mock(subscriptions: subscriptions)
        let peripherals = [peripheral]
        let dataStore = DataStoreMock(peripherals: peripherals)
        let centralManager = CBCentralManagerMock(peripherals: peripherals)
        sut = BluetoothThingManager(delegate: delegate,
                                    subscriptions: subscriptions,
                                    dataStore: dataStore,
                                    centralManager: centralManager)
        
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
        
        let peripheral = CBPeripheral.mock(subscriptions: subscriptions)
        let peripherals = [peripheral]
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
        
        let peripherals = [CBPeripheral.mock(subscriptions: subscriptions)]
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

        let peripheral = CBPeripheral.mock(subscriptions: subscriptions)
        let peripherals = [peripheral]
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

        let peripheral = CBPeripheral.mock(subscriptions: subscriptions)
        let peripherals = [peripheral]
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

        let peripheral = CBPeripheral.mock(subscriptions: subscriptions)
        let peripherals = [peripheral]
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

        let peripheral = CBPeripheral.mock(subscriptions: subscriptions)
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

        let peripheral = CBPeripheral.mock(subscriptions: subscriptions)
        let peripherals = [peripheral]
        let dataStore = DataStoreMock(peripherals: peripherals)
        let centralManager = CBCentralManagerMock(peripherals: peripherals)
        sut = BluetoothThingManager(delegate: delegate,
                                    subscriptions: subscriptions,
                                    dataStore: dataStore,
                                    centralManager: centralManager)
        given(peripheral.delegate).willReturn(sut)

        // When
        centralManager.setState(.poweredOn)
        peripheral.discoverServices(nil)
        
        // Then
        let fff0 = peripheral.getService(.fff0)!
        let deviceInformation = peripheral.getService(.deviceInformation)!
        let fff1 = peripheral.getCharacteristic(.fff1)!
        let fff2 = peripheral.getCharacteristic(.fff2)!
        // should not discover unsubscribed services
        verify(peripheral.discoverCharacteristics(firstArg(any()), for: fff0)).wasCalled(1)
        verify(peripheral.discoverCharacteristics(firstArg(any()), for: deviceInformation)).wasCalled(1)
        verify(peripheral.setNotifyValue(true, for: any())).wasCalled(2)
        XCTAssertTrue(fff1.isNotifying)
        XCTAssertTrue(fff2.isNotifying)
    }

    func testDidDiscoverCharacteristics() {
        // Given
        subscriptions = [.fff1]

        let peripheral = CBPeripheral.mock(subscriptions: subscriptions)
        let peripherals = [peripheral]
        let dataStore = DataStoreMock(peripherals: peripherals)
        let centralManager = CBCentralManagerMock(peripherals: peripherals)
        sut = BluetoothThingManager(delegate: delegate,
                                    subscriptions: subscriptions,
                                    dataStore: dataStore,
                                    centralManager: centralManager)
        given(peripheral.delegate).willReturn(sut)
       
        // When
        centralManager.setState(.poweredOn)
        peripheral.discoverServices([.fff0])
                
        // Then
        let characteristic = peripheral.getCharacteristic(.fff1)!
        verify(peripheral.readValue(for: characteristic)).wasCalled(1)
        verify(peripheral.setNotifyValue(true, for: characteristic)).wasCalled(1)
        XCTAssertTrue(characteristic.isNotifying)
    }

    func testDidUpdateValue() {
        // Given
        subscriptions = [.fff1]

        let peripheral = CBPeripheral.mock(subscriptions: subscriptions)
        let peripherals = [peripheral]
        let dataStore = DataStoreMock(peripherals: peripherals)
        let centralManager = CBCentralManagerMock(peripherals: peripherals)
        sut = BluetoothThingManager(delegate: delegate,
                                    subscriptions: subscriptions,
                                    dataStore: dataStore,
                                    centralManager: centralManager)
        given(peripheral.delegate).willReturn(sut)

        centralManager.setState(.poweredOn)
        centralManager.connect(peripheral, options: nil)
        peripheral.discoverServices(nil)
        let characteristic = peripheral.services!.first!.characteristics!.first!
        let value = "test".data(using: .utf8)
        given(characteristic.value).willReturn(value)
        
        // When
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

        let peripheral = CBPeripheral.mock(subscriptions: subscriptions)
        let peripherals = [peripheral]
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

        let peripheral = CBPeripheral.mock(subscriptions: subscriptions)
        let peripherals = [peripheral]
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

        let peripheral = CBPeripheral.mock(subscriptions: subscriptions)
        let peripherals = [peripheral]
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

        let peripheral = CBPeripheral.mock(subscriptions: subscriptions)
        let peripherals = [peripheral]
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

        let peripheral = CBPeripheral.mock(subscriptions: subscriptions)
        let peripherals = [peripheral]
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

        let peripheral = CBPeripheral.mock(subscriptions: subscriptions)
        let peripherals = [peripheral]
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

        let peripheral = CBPeripheral.mock(subscriptions: subscriptions)
        let peripherals = [peripheral]
        let dataStore = DataStoreMock(peripherals: peripherals)
        let centralManager = CBCentralManagerMock(peripherals: peripherals)
        sut = BluetoothThingManager(delegate: delegate,
                                    subscriptions: subscriptions,
                                    dataStore: dataStore,
                                    centralManager: centralManager)

        // When
        let serialNumber = CBCharacteristic.mock(uuid: .serialNumber,
                                                 service: .mock(uuid: .deviceInformation))
        given(serialNumber.value).willReturn(Data(hexString: "ffff"))
        sut.peripheral(peripheral, didUpdateValueFor: serialNumber, error: nil)
        
        // Then
        XCTAssertEqual(dataStore.saveThingCalled, 1)
        XCTAssertNotNil(dataStore.savedThing)
        XCTAssertEqual(dataStore.savedThing?.hardwareSerialNumber, "ffff")
    }
    
    func testBluetoothThing() {
        // Given 1 service with 2 characteristics
        subscriptions = [.fff1, .fff2]

        let peripheral = CBPeripheral.mock(subscriptions: subscriptions)
        let peripherals = [peripheral]
        given(peripheral.services).willReturn(nil)
        
        let dataStore = DataStoreMock(peripherals: peripherals)
        let thing = dataStore.things.first!
        let centralManager = CBCentralManagerMock(peripherals: peripherals)
        centralManager.setState(.poweredOn)
        sut = BluetoothThingManager(delegate: delegate,
                                    subscriptions: subscriptions,
                                    dataStore: dataStore,
                                    centralManager: centralManager)
        sut.centralManager(sut.centralManager,
                           didDiscover: peripheral,
                           advertisementData: [CBAdvertisementDataServiceUUIDsKey: [CBUUID.fff0]],
                           rssi: -10)
        given(peripheral.delegate).willReturn(sut)

        // When
        thing.connect()
        // Then should subscribe
        XCTAssertEqual(peripheral.state, .connected)
        XCTAssertTrue(dataStore.things.contains(thing))
        XCTAssertFalse(thing.pendingConnect)
        
        let fff0 = peripheral.getService(.fff0)!
        let deviceInformation = peripheral.getService(.deviceInformation)!
        let fff1 = peripheral.getCharacteristic(.fff1)!
        let fff2 = peripheral.getCharacteristic(.fff2)!
        
        verify(peripheral.discoverServices(nil)).wasCalled(1)
        verify(peripheral.discoverCharacteristics(firstArg(any()), for: fff0)).wasCalled(1)
        verify(peripheral.discoverCharacteristics(firstArg(any()), for: deviceInformation)).wasCalled(1)
        verify(peripheral.readValue(for: fff1)).wasCalled(1)
        verify(peripheral.readValue(for: fff2)).wasCalled(1)
        verify(peripheral.setNotifyValue(true, for: fff1)).wasCalled(1)
        verify(peripheral.setNotifyValue(true, for: fff2)).wasCalled(1)

        XCTAssertTrue(thing.hasService(CBUUID.batteryService))
        XCTAssertTrue(thing.hasService(CBUUID.deviceInformation))
        XCTAssertTrue(thing.hasService(CBUUID.heartRateService))
        XCTAssertTrue(thing.hasService(CBUUID.cyclingSpeedAndCadenceService))
        XCTAssertTrue(thing.hasService(BTService(service: "FFF0")))
        XCTAssertFalse(thing.hasService(CBUUID.cyclingPowerService))
        
        // When
        thing.connect()
        // Then
        XCTAssertTrue(dataStore.things.contains(thing))
        verify(peripheral.discoverServices(nil)).wasCalled(1) //should not be called again
                
        // When read unsubscribed characteristic
        thing.read(.cscMeasurement)
        // Then
        let cscService = peripheral.getService(.cyclingSpeedAndCadenceService)!
        let cscMeasurement = peripheral.getCharacteristic(.cscMeasurement)!
        verify(peripheral.setNotifyValue(true, for: cscMeasurement)).wasNeverCalled() // should not subscribe
        verify(peripheral.discoverCharacteristics([.cscMeasurement], for: cscService)).wasCalled(1)
        verify(peripheral.readValue(for: cscMeasurement)).wasCalled(1)
        
        // When
        let data = Data(hexString: "ff")
        thing.write(.cscMeasurement, value: data)
        // Then
        verify(peripheral.writeValue(data, for: cscMeasurement, type: .withoutResponse)).wasCalled(1)
        
        // When
        thing.unsubscribe()
        // Then
        verify(peripheral.setNotifyValue(false, for: fff1)).wasCalled(1)
        verify(peripheral.setNotifyValue(false, for: fff2)).wasCalled(1)
        
        // When
        thing.subscribe()
        // Then
        verify(peripheral.setNotifyValue(true, for: fff1)).wasCalled(2)
        verify(peripheral.setNotifyValue(true, for: fff2)).wasCalled(2)

        // When subscribe others
        thing.subscribe(.heartRateMeasurement)
        // Then
        let heartRateService = peripheral.getService(.heartRateService)!
        let heartRateMeasurement = peripheral.getCharacteristic(.heartRateMeasurement)!
        verify(peripheral.discoverCharacteristics([.heartRateMeasurement], for: heartRateService)).wasCalled(1)
        verify(peripheral.setNotifyValue(true, for: heartRateMeasurement)).wasCalled(1)

        // When subscribe duplicated
        thing.subscribe(.heartRateMeasurement)
        // Then should not call the methods again
        verify(peripheral.discoverCharacteristics([.heartRateMeasurement], for: heartRateService)).wasCalled(1)
        verify(peripheral.setNotifyValue(true, for: heartRateMeasurement)).wasCalled(1)

        // When
        thing.unsubscribe(.heartRateMeasurement)
        // Then
        verify(peripheral.setNotifyValue(false, for: heartRateMeasurement)).wasCalled(1)

        // When
        thing.disconnect()
        // Then
        XCTAssertEqual(centralManager.cancelConnectionCalled, 1)
        XCTAssertEqual(centralManager.cancelConnectionPeripheral, peripheral)
        XCTAssertEqual(peripheral.state, .disconnected)
        XCTAssertFalse(thing.pendingConnect)
                
        thing.forget()
        // Then
        XCTAssertEqual(centralManager.cancelConnectionCalled, 1, "should call cancel connect only once")
        XCTAssertFalse(thing.pendingConnect)
    }

    func testNearbyThings() {
        // Given
        subscriptions = [.batteryService]
        
        let peripherals = [
            CBPeripheral.mock(subscriptions: subscriptions),
            CBPeripheral.mock(subscriptions: subscriptions),
            CBPeripheral.mock(subscriptions: subscriptions),
            CBPeripheral.mock(subscriptions: subscriptions)
        ]
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
    
    func testSetSubscriptions() {
        // Given
        subscriptions = [.batteryService]

        
        let dataStore = DataStoreMock(peripherals: [])
        let centralManager = CBCentralManagerMock(peripherals: [])
        centralManager.setState(.poweredOn)
        sut = BluetoothThingManager(delegate: delegate,
                                    subscriptions: subscriptions,
                                    dataStore: dataStore,
                                    centralManager: centralManager)
        
        XCTAssertEqual(centralManager.stopScanCalled, 0)
        XCTAssertEqual(centralManager.scanForPeripheralsCalled, 0)
        
        sut.startScanning(options: nil)
        
        XCTAssertEqual(centralManager.stopScanCalled, 1)
        XCTAssertEqual(centralManager.scanForPeripheralsCalled, 1)
        
        sut.insertSubscription(BTSubscription(BTService(service: "180F")))

        XCTAssertEqual(centralManager.stopScanCalled, 1)
        XCTAssertEqual(centralManager.scanForPeripheralsCalled, 1)
        
        sut.insertSubscription(.deviceInfomation)
        
        XCTAssertEqual(centralManager.stopScanCalled, 2)
        XCTAssertEqual(centralManager.scanForPeripheralsCalled, 2)
        
        sut.removeSubscription(.fff1)
        
        XCTAssertEqual(centralManager.stopScanCalled, 2)
        XCTAssertEqual(centralManager.scanForPeripheralsCalled, 2)
        
        sut.removeSubscription(.deviceInfomation)
        
        XCTAssertEqual(centralManager.stopScanCalled, 3)
        XCTAssertEqual(centralManager.scanForPeripheralsCalled, 3)
        
        sut.setSubscription([.fff1, .fff2])
        
        XCTAssertEqual(centralManager.stopScanCalled, 4)
        XCTAssertEqual(centralManager.scanForPeripheralsCalled, 4)
        
        sut.insertSubscriptions([.fff1, .fff2])
        
        XCTAssertEqual(centralManager.stopScanCalled, 4)
        XCTAssertEqual(centralManager.scanForPeripheralsCalled, 4)
        
        sut.insertSubscriptions([.fff1, .fff2, .batteryService])
        
        XCTAssertEqual(centralManager.stopScanCalled, 5)
        XCTAssertEqual(centralManager.scanForPeripheralsCalled, 5)
        
        sut.removeSubscriptions([.deviceInfomation])
        
        XCTAssertEqual(centralManager.stopScanCalled, 5)
        XCTAssertEqual(centralManager.scanForPeripheralsCalled, 5)
        
        sut.removeSubscriptions([.batteryService])
        
        XCTAssertEqual(centralManager.stopScanCalled, 6)
        XCTAssertEqual(centralManager.scanForPeripheralsCalled, 6)

    }
}
