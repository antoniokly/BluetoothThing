//
//  BluetoothWorkerTests.swift
//  BluetoothWorkerTests
//
//  Created by Antonio Yip on 8/01/20.
//  Copyright © 2020 Antonio Yip. All rights reserved.
//

import XCTest
import CoreBluetooth
@testable import BluetoothThing

class BluetoothWorkerTests: XCTestCase {

    class BluetoothThingManagerDelegateSpy: BluetoothThingManagerDelegate {
        var bluetoothThing: BluetoothThing?

        func bluetoothThingManager(_ manager: BluetoothThingManager, didFoundThings: [BluetoothThing]) {
            
        }
        
        var didChangeCharacteristicCalled = false
        var characteristic: CharacteristicProtocol?
        func bluetoothThing(_ thing: BluetoothThing, didChangeCharacteristic characteristic: CharacteristicProtocol) {
            didChangeCharacteristicCalled = true
            bluetoothThing = thing
            self.characteristic = characteristic
        }
        
        var didChangeStateCalled = false
        var state: ConnectionState?
        func bluetoothThing(_ thing: BluetoothThing, didChangeState state: ConnectionState) {
            didChangeStateCalled = true
            bluetoothThing = thing
            self.state = state
        }
        
        var didChangeRSSICalled = false
        var rssi: NSNumber?
        func bluetoothThing(_ thing: BluetoothThing, didChangeRSSI rssi: NSNumber?) {
            didChangeRSSICalled = true
            bluetoothThing = thing
            self.rssi = rssi
        }
    }
    

    class Peripheral: PeripheralProtocol {
       
        
        var identifier: UUID
        
        var name: String? = nil
        
        var state: CBPeripheralState = .disconnected
        
        var services: [CBService]? = []
        
        init(identifier: UUID) {
            self.identifier = identifier
        }
        
        func setNotifyValue(_: Bool, for: CBCharacteristic) {
        }
    }
    
    class DataStoreSpy: DataStoreInterface {
        var things: [BluetoothThing] = []
        
        func save() {
            
        }
        
        func getThing(id: UUID) -> BluetoothThing {
            return BluetoothThing(id: id)

        }
        
        func removeThing(id: UUID) -> Bool {
            return true
        }
    }

    var delegate: BluetoothThingManagerDelegateSpy!

    var sut: BluetoothWorker!
    
    let subscriptions = [
        Characteristic(uuid: "FFFF", serviceUUID: "FFFF")
    ]
    
    override func setUp() {
        super.setUp()
        
        delegate = BluetoothThingManagerDelegateSpy()
        sut = BluetoothWorker(delegate: delegate, subscriptions: subscriptions)
        sut.dataStore = DataStoreSpy()
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testDidChangeRSSI() {
        // GIVEN
        let peripheral = Peripheral(identifier: UUID())
        let rssi: NSNumber = 1

        // WHEN
        sut.didUpdateRSSI(rssi, for: peripheral)
        
        // THEN
        XCTAssert(delegate.didChangeRSSICalled)
        XCTAssertEqual(delegate.rssi, rssi)
        XCTAssertEqual(delegate.bluetoothThing?.id, peripheral.identifier)
    }
 
    func testDidChangeState() {
        // GIVEN
        let peripheral = Peripheral(identifier: UUID())
        peripheral.state = .connected

        // WHEN
        sut.didUpdatePeripheral(peripheral)
        
        // THEN
        XCTAssert(delegate.didChangeStateCalled)
        XCTAssertEqual(delegate.state, peripheral.state)
        XCTAssertEqual(delegate.bluetoothThing?.id, peripheral.identifier)
        XCTAssertEqual(delegate.bluetoothThing?.state, peripheral.state)
    }
    
    func testDidUpdateCharacteristic() {
        // GIVEN
        let peripheral = Peripheral(identifier: UUID())
        let characteristic = subscriptions.first!
        characteristic.value = Data()

        // WHEN
        sut.didUpdateCharacteristic(characteristic, for: peripheral)
        
        // THEN
        XCTAssert(delegate.didChangeCharacteristicCalled)
        XCTAssertEqual(delegate.characteristic?.value, characteristic.value)
        let data = delegate.bluetoothThing?.data[characteristic.serviceUUID.uuidString]
        let value = data?[characteristic.uuid.uuidString]
        XCTAssertEqual(value, characteristic.value)
    }
    
    func testDidUpdateCharacteristicNil() {
        // GIVEN
        let peripheral = Peripheral(identifier: UUID())
        let characteristic = subscriptions.first!

        // WHEN
        sut.didUpdateCharacteristic(characteristic, for: peripheral)
        
        // THEN
        XCTAssertFalse(delegate.didChangeCharacteristicCalled)
    }
    
    func testShouldSubscribe() {
        let characteristic1 = Characteristic(uuid: "FFFF", serviceUUID: "FFF1")
        XCTAssertFalse(sut.shouldSubscribe(characteristic: characteristic1))
        
        let characteristic2 = Characteristic(uuid: "FFF1", serviceUUID: "FFFF")
        XCTAssertFalse(sut.shouldSubscribe(characteristic: characteristic2))
        
        let characteristic3 = Characteristic(uuid: "FF21", serviceUUID: "FFF2")
        XCTAssertFalse(sut.shouldSubscribe(characteristic: characteristic3))
        
        let characteristic4 = Characteristic(uuid: "FFFF", serviceUUID: "FFFF")
        XCTAssertTrue(sut.shouldSubscribe(characteristic: characteristic4))
    }
    
    func testSubscribePeripheral() {
        // GIVEN
        let peripheral = Peripheral(identifier: UUID())
        peripheral.services = []
    }
}
