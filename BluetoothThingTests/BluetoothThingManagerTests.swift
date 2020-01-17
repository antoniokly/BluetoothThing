//
//  BluetoothThingManagerTests.swift
//  BluetoothThingTests
//
//  Created by Antonio Yip on 10/01/20.
//  Copyright © 2020 Antonio Yip. All rights reserved.
//

import XCTest
import CoreBluetooth
import CoreLocation
@testable import BluetoothThing

class BluetoothThingManagerTests: XCTestCase {
    
    var sut: BluetoothThingManager!
        
    class BluetoothThingManagerDelegateSpy: BluetoothThingManagerDelegate {
        var locationDidFailCalled = 0
        var locationDidFailWithError: Error?
        func bluetoothThingManager(_ manager: BluetoothThingManager, locationDidFailWithError error: Error) {
            locationDidFailCalled += 1
            locationDidFailWithError = error
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
        
        var didUpdateLocationCalled = 0
        func bluetoothThing(_ thing: BluetoothThing, didUpdateLocation location: Location) {
            didUpdateLocationCalled += 1
        }
        
        var didChangeCharacteristicCalled = 0
        var didChangeCharacteristicThing: BluetoothThing?
        var didChangeCharacteristic: CBCharacteristic?
        func bluetoothThing(_ thing: BluetoothThing, didChangeCharacteristic characteristic: Characteristic) {
            didChangeCharacteristicCalled += 1
            didChangeCharacteristicThing = thing
            didChangeCharacteristic = characteristic
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
        // Put setup code here. This method is called before the invocation of each test method in the class.
        delegate = BluetoothThingManagerDelegateSpy()
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testInitialization() {
        // Given
        let serviceUUID = CBUUID(string: "FFF0")
        let characteristicUUID = CBUUID(string: "FFF1")
        
        let subsriptions = [
            Subscription(service: serviceUUID,
                         characteristic: characteristicUUID)
        ]
        
        let peripherals = initPeripherals(subscriptions: subsriptions, numberOfPeripherals: 3)
        let dataStore = DataStoreMock(peripherals: peripherals)
        let centralManager = CBCentralManagerMock(peripherals: peripherals)

        let locationManager = CLLocationManagerMock()
        sut = initBluetoothThingManager(delegate: delegate,
                                        subscriptions: subsriptions,
                                        dataStore: dataStore,
                                        centralManager: centralManager,
                                        locationManager: locationManager)

        XCTAssertNotNil(sut.delegate)
        XCTAssertNotNil(sut.dataStore)
        XCTAssertNotNil(sut.centralManager.delegate)
        XCTAssertNotNil(sut.locationManager?.delegate)

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
        
        let subsriptions = [
            Subscription(service: serviceUUID,
                         characteristic: characteristicUUID)
        ]
        
        let peripherals = initPeripherals(subscriptions: subsriptions, numberOfPeripherals: 2)
        let dataStore = DataStoreMock(peripherals: peripherals)
        let centralManager = CBCentralManagerMock(peripherals: peripherals)
        sut = initBluetoothThingManager(delegate: delegate,
                                        subscriptions: subsriptions,
                                        dataStore: dataStore,
                                        centralManager: centralManager)
        
        sut.newFoundThings = dataStore.things.suffix(1)
        
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
        XCTAssertEqual(delegate.didLoseThing?.id, sut.newFoundThings.first?.id)
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
        
        let subsriptions = [
            Subscription(service: serviceUUID,
                         characteristic: characteristicUUID)
        ]
        
        let peripherals = initPeripherals(subscriptions: subsriptions, numberOfPeripherals: 1)
        let peripheral = peripherals.first!
        let dataStore = DataStoreMock(peripherals: peripherals)
        let centralManager = CBCentralManagerMock(peripherals: peripherals)
        sut = initBluetoothThingManager(delegate: delegate,
                                        subscriptions: subsriptions,
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
        XCTAssertEqual(delegate.didChangeStateThing?.id, restorePeripherals.first?.identifier)
        XCTAssertEqual(delegate.didChangeStateThing?.state, .connected)
        XCTAssertEqual(delegate.didChangeState, .connected)
        XCTAssertEqual(peripheral.discoverServices, peripheral.services?.map({$0.uuid}))
    }
    
    func testPowerOff() {
        // Given
        let serviceUUID = CBUUID(string: "FFF0")
        let characteristicUUID = CBUUID(string: "FFF1")
        
        let subsriptions = [
            Subscription(service: serviceUUID,
                         characteristic: characteristicUUID)
        ]
        
        let peripherals = initPeripherals(subscriptions: subsriptions, numberOfPeripherals: 1)
        let dataStore = DataStoreMock(peripherals: peripherals)
        let centralManager = CBCentralManagerMock(peripherals: peripherals)
        sut = initBluetoothThingManager(delegate: delegate,
                                        subscriptions: subsriptions,
                                        dataStore: dataStore,
                                        centralManager: centralManager)

        dataStore.things.first?.state = .connected
        sut.newFoundThings = dataStore.things
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
        
        let subsriptions = [
            Subscription(service: serviceUUID,
                         characteristic: characteristicUUID)
        ]
        
        let peripherals = initPeripherals(subscriptions: subsriptions, numberOfPeripherals: 1)
        let peripheral = peripherals.first!
        let dataStore = DataStoreMock(peripherals: peripherals)
        let centralManager = CBCentralManagerMock(peripherals: peripherals)
        let fakeLocation = CLLocation(latitude: 0, longitude: 0)
        let locationManager = CLLocationManagerMock(fakeLocation: fakeLocation)
        sut = initBluetoothThingManager(delegate: delegate,
                                        subscriptions: subsriptions,
                                        dataStore: dataStore,
                                        centralManager: centralManager,
                                        locationManager: locationManager)

        // When
        centralManager._state = .poweredOn
        sut.knownPeripherals = Set(peripherals)
        peripheral._state = .connected
        sut.centralManager(sut.centralManager, didConnect: peripheral)
        
        // Then
        XCTAssertEqual(peripheral.discoverServicesCalled, 1)
        XCTAssertEqual(peripheral.discoverServices, peripheral.services?.map({$0.uuid}))
        XCTAssertEqual(delegate.didUpdateLocationCalled, 1)
    }
    
    func testDidDisconnect() {
        // Given
        let serviceUUID = CBUUID(string: "FFF0")
        let characteristicUUID = CBUUID(string: "FFF1")
        
        let subsriptions = [
            Subscription(service: serviceUUID,
                         characteristic: characteristicUUID)
        ]
        
        let peripherals = initPeripherals(subscriptions: subsriptions, numberOfPeripherals: 1)
        let peripheral = peripherals.first!
        let dataStore = DataStoreMock(peripherals: peripherals)
        let centralManager = CBCentralManagerMock(peripherals: peripherals)
        sut = initBluetoothThingManager(delegate: delegate,
                                        subscriptions: subsriptions,
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
        
        let subsriptions = [
            Subscription(service: serviceUUID,
                         characteristic: characteristicUUID)
        ]

        let peripherals = initPeripherals(subscriptions: subsriptions, numberOfPeripherals: 1)
        let peripheral = peripherals.first!
        let dataStore = DataStoreMock(peripherals: peripherals)
        let centralManager = CBCentralManagerMock(peripherals: peripherals)
        sut = initBluetoothThingManager(delegate: delegate,
                                        subscriptions: subsriptions,
                                        dataStore: dataStore,
                                        centralManager: centralManager)

        // When
        centralManager._state = .poweredOn
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
        
        let subsriptions = [
            Subscription(service: serviceUUID,
                         characteristic: characteristicUUID)
        ]

        let peripherals = initPeripherals(subscriptions: subsriptions, numberOfPeripherals: 1)
        let peripheral = peripherals.first!
        let dataStore = DataStoreMock(peripherals: [])
        let centralManager = CBCentralManagerMock(peripherals: [])
        sut = initBluetoothThingManager(delegate: delegate,
                                        subscriptions: subsriptions,
                                        dataStore: dataStore,
                                        centralManager: centralManager)
        
        // When
        centralManager._state = .poweredOn
        sut.centralManager(sut.centralManager,
                           didDiscover: peripheral,
                           advertisementData: [CBAdvertisementDataServiceUUIDsKey: [serviceUUID]],
                           rssi: 100)
        
        // Then
        XCTAssertEqual(delegate.didFoundThingCalled, 1)
        XCTAssertEqual(delegate.didFoundThingRSSI, 100)
        
        let thing = delegate.foundThing
        XCTAssertNotNil(thing)
        XCTAssertEqual(thing?.id, peripheral.identifier)
        XCTAssertEqual(dataStore.things.count, 0)
        
        // When
        thing?.register?()
        
        // Then
        XCTAssertEqual(dataStore.things.count, 1)
        XCTAssertEqual(centralManager.connectCalled, 1)
        XCTAssertEqual(centralManager.connectPeripheral, peripheral)
        
        // When
        thing?.deregister?()
        
        // Then
        XCTAssertEqual(dataStore.things.count, 0)
        XCTAssertEqual(centralManager.cancelConnectionCalled, 1)
        XCTAssertEqual(centralManager.cancelConnectionPeripheral, peripheral)
    }
    
    func testDidDiscoverUnsubscribedPeripheral() {
        // Given
        let serviceUUID = CBUUID(string: "FFF0")
        let characteristicUUID = CBUUID(string: "FFF1")
        
        let subsriptions = [
            Subscription(service: serviceUUID,
                         characteristic: characteristicUUID)
        ]

        let unsubscribedPeripheral = CBPeripheralMock(identifier: UUID())
        let unknownServiceUUIDs = [CBUUID(string: "BEEF")]
        let dataStore = DataStoreMock(peripherals: [])
        let centralManager = CBCentralManagerMock(peripherals: [])
        sut = initBluetoothThingManager(delegate: delegate,
                                        subscriptions: subsriptions,
                                        dataStore: dataStore,
                                        centralManager: centralManager)
        
        // When
        centralManager._state = .poweredOn
        sut.centralManager(sut.centralManager,
                           didDiscover: unsubscribedPeripheral,
                           advertisementData: [CBAdvertisementDataServiceUUIDsKey: unknownServiceUUIDs],
                           rssi: 100)
        
        // Then
        XCTAssertEqual(centralManager.connectCalled, 0, "should not connect unsubscribed peripheral")
    }
    
    func testDidDiscoverServices() {
        // Given
        let serviceUUID = CBUUID(string: "FFF0")
        let characteristicUUID = CBUUID(string: "FFF1")
        
        let subsriptions = [
            Subscription(service: serviceUUID,
                         characteristic: characteristicUUID)
        ]
        
        let peripherals = initPeripherals(subscriptions: subsriptions, numberOfPeripherals: 1)
        let peripheral = peripherals.first!
        // unsubscribed services
        peripheral._services?.append(CBServiceMock(uuid: CBUUID(string: "EEE1")))
        peripheral._services?.append(CBServiceMock(uuid: CBUUID(string: "EEE2")))
        
        let dataStore = DataStoreMock(peripherals: peripherals)
        let centralManager = CBCentralManagerMock(peripherals: peripherals)
        sut = initBluetoothThingManager(delegate: delegate,
                                        subscriptions: subsriptions,
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
        
        let subsriptions = [
            Subscription(service: serviceUUID,
                         characteristic: characteristicUUID)
        ]
        
        let peripherals = initPeripherals(subscriptions: subsriptions, numberOfPeripherals: 1)
        let peripheral = peripherals.first!
        let dataStore = DataStoreMock(peripherals: peripherals)
        let centralManager = CBCentralManagerMock(peripherals: peripherals)
        sut = initBluetoothThingManager(delegate: delegate,
                                        subscriptions: subsriptions,
                                        dataStore: dataStore,
                                        centralManager: centralManager)

        // When
        centralManager._state = .poweredOn
        sut.peripheral(peripheral, didDiscoverCharacteristicsFor: peripheral.services!.first!, error: nil)
        
        // Then
        XCTAssertEqual(peripheral.readValueCalled, 1)
        XCTAssertEqual(peripheral.readValueCharacteristic?.uuid, characteristicUUID)
        XCTAssertEqual(peripheral.setNotifyValueCalled, 1)
        XCTAssertEqual(peripheral.setNotifyValueEnabled, true)
        XCTAssertEqual(peripheral.setNotifyValueCharacteristic?.uuid, characteristicUUID)
    }
    
    func testDidUpdateValue() {
        // Given
        let serviceUUID = CBUUID(string: "FFF0")
        let characteristicUUID = CBUUID(string: "FFF1")
        
        let subsriptions = [
            Subscription(service: serviceUUID,
                         characteristic: characteristicUUID)
        ]
        
        let peripherals = initPeripherals(subscriptions: subsriptions, numberOfPeripherals: 1)
        let peripheral = peripherals.first!
        let dataStore = DataStoreMock(peripherals: peripherals)
        let centralManager = CBCentralManagerMock(peripherals: peripherals)
        sut = initBluetoothThingManager(delegate: delegate,
                                        subscriptions: subsriptions,
                                        dataStore: dataStore,
                                        centralManager: centralManager)
        
        let characteristic = peripheral.services?.first?.characteristics?.first as! CBCharacteristicMock
        let value = Data()
        characteristic._value = value

        // When
        centralManager._state = .poweredOn
        centralManager.connect(peripheral, options: nil)
        sut.peripheral(peripheral, didUpdateValueFor: characteristic, error: nil)
        
        // Then
        XCTAssertEqual(delegate.didChangeCharacteristicCalled, 1)
        XCTAssertEqual(delegate.didChangeCharacteristic, characteristic)
        XCTAssertEqual(delegate.didChangeCharacteristic?.value, value)
        
        // When
        characteristic._value = nil
        sut.peripheral(peripheral, didUpdateValueFor: characteristic, error: nil)
        XCTAssertEqual(delegate.didChangeCharacteristicCalled, 2)
        
        let thing = delegate.didChangeCharacteristicThing
        XCTAssertNotNil(thing)
        XCTAssertNotNil(thing?.data[serviceUUID.uuidString])
        XCTAssertNil(thing?.data[serviceUUID.uuidString]?[characteristicUUID.uuidString])
    }
    
    func testDidReadRSSI() {
        // Given
        let serviceUUID = CBUUID(string: "FFF0")
        let characteristicUUID = CBUUID(string: "FFF1")
        
        let subsriptions = [
            Subscription(service: serviceUUID,
                         characteristic: characteristicUUID)
        ]
        
        let peripherals = initPeripherals(subscriptions: subsriptions, numberOfPeripherals: 1)
        let peripheral = peripherals.first!
        let dataStore = DataStoreMock(peripherals: peripherals)
        let centralManager = CBCentralManagerMock(peripherals: peripherals)
        sut = initBluetoothThingManager(delegate: delegate,
                                        subscriptions: subsriptions,
                                        dataStore: dataStore,
                                        centralManager: centralManager)
        
        // When
        sut.peripheral(peripheral, didReadRSSI: 99, error: nil)
        
        // Then
        XCTAssertEqual(delegate.didChangeRSSICalled, 1)
        XCTAssertEqual(delegate.didChangeRSSIThing?.id, peripheral.identifier)
        XCTAssertEqual(delegate.didChangeRSSI, 99)
    }
    
    func testOlderLocation() {
        // Given
        let dataStore = DataStoreMock(peripherals: [])
        let centralManager = CBCentralManagerMock(peripherals: [])
        let olderLocation = CLLocation(latitude: 0, longitude: 0)

        let locationManager = CLLocationManagerMock(fakeLocation: nil)
        sut = initBluetoothThingManager(delegate: delegate,
                                        subscriptions: [],
                                        dataStore: dataStore,
                                        centralManager: centralManager,
                                        locationManager: locationManager)
        let newerLocation = CLLocation(latitude: 0, longitude: 0)
        sut.userLocation = newerLocation

        // When
        sut.locationManager(locationManager,
                            didUpdateLocations: [olderLocation])

        // Then
        XCTAssertEqual(sut.userLocation, newerLocation)
    }
    
    func testDidFailToConnect() {
        // Given
        let serviceUUID = CBUUID(string: "FFF0")
        let characteristicUUID = CBUUID(string: "FFF1")
        
        let subsriptions = [
            Subscription(service: serviceUUID,
                         characteristic: characteristicUUID)
        ]
        
        let peripherals = initPeripherals(subscriptions: subsriptions, numberOfPeripherals: 1)
        let peripheral = peripherals.first!
        let dataStore = DataStoreMock(peripherals: peripherals)
        let centralManager = CBCentralManagerMock(peripherals: peripherals)
        sut = initBluetoothThingManager(delegate: delegate,
                                        subscriptions: subsriptions,
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
        
        let subsriptions = [
            Subscription(service: serviceUUID,
                         characteristic: characteristicUUID)
        ]

        let peripherals = initPeripherals(subscriptions: subsriptions, numberOfPeripherals: 1)
        let peripheral = peripherals.first!
        let dataStore = DataStoreMock(peripherals: [])
        let centralManager = CBCentralManagerMock(peripherals: peripherals)
        sut = initBluetoothThingManager(delegate: delegate,
                                        subscriptions: subsriptions,
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
        
        let subsriptions = [
            Subscription(service: serviceUUID,
                         characteristic: characteristicUUID)
        ]

        let peripherals = initPeripherals(subscriptions: subsriptions, numberOfPeripherals: 1)
        let dataStore = DataStoreMock(peripherals: [])
        let centralManager = CBCentralManagerMock(peripherals: peripherals)
        sut = initBluetoothThingManager(delegate: delegate,
                                        subscriptions: subsriptions,
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
        thing.register?()
        
        // Then
        XCTAssertEqual(delegate.didFoundThingCalled, 1)
        XCTAssertEqual(delegate.didChangeStateCalled, 2, "state should be changed to connecting then connected")
        
        // When
        thing.deregister?()
        
        // Then
        XCTAssertEqual(delegate.didChangeStateCalled, 4, "state should be changed to disconnecting then disconnected")
    }
    
    func testLocationDidFail() {
        // Given
        let dataStore = DataStoreMock(peripherals: [])
        let centralManager = CBCentralManagerMock(peripherals: [])
        let locationManager = CLLocationManagerMock()
        sut = initBluetoothThingManager(delegate: delegate,
                                        subscriptions: [],
                                        dataStore: dataStore,
                                        centralManager: centralManager,
                                        locationManager: locationManager)
        
        // When
        sut.locationManager(locationManager, didFailWithError: NSError(domain: "locationError", code: 0, userInfo: nil))
        
        // Then
        XCTAssertEqual(delegate.locationDidFailCalled, 1)
        XCTAssertNotNil(delegate.locationDidFailWithError)
    }
}
