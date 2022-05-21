//
//  BluetoothThingCombineTests.swift
//  
//
//  Created by Antonio Yip on 21/5/2022.
//

import XCTest
import CoreBluetooth
import Combine
import Mockingbird
@testable import BluetoothThing

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
class BluetoothThingCombineTests: XCTestCase {

    var sut: BluetoothThing!
    var peripheral: CBPeripheral!
    var manager: BluetoothThingManager!
    var subscriptions: [BTSubscription]!
    var dataStore: DataStore!
    var centralManager: CBCentralManager!
    
    class Receiver: ObservableObject {
        @Published var manufacturerData: Data?
        @Published var cscMeasurement: Data?

        init(device: BluetoothThing) {
            device.manufacturerDataPublisher()
                .debounce(for: 0.1, scheduler: DispatchQueue.main)
                .assign(to: &$manufacturerData)
            
            device.characteristicPublisher(for: .cscMeasurement)
                .assign(to: &$cscMeasurement)
        }
    }
    
    override func setUpWithError() throws {
        subscriptions = [
            BTSubscription(serviceUUID: .cyclingSpeedAndCadenceService, characteristicUUID: .cscMeasurement)
        ]
        
        peripheral = CBPeripheral.mock(subscriptions: subscriptions)
        dataStore = DataStoreMock(peripherals: [peripheral])
        centralManager = CBCentralManagerMock(peripherals: [peripheral])
        manager = BluetoothThingManager(subscriptions: subscriptions,
                                    dataStore: dataStore,
                                    centralManager: centralManager)
        
        sut = manager.knownThings.first
    }

    override func tearDownWithError() throws {
        
    }

    func testPublisher() throws {
        // Given
        let receiver = Receiver(device: sut)

        XCTAssertTrue(sut.advertisementData.isEmpty)
        XCTAssertNil(sut.manufacturerData)
        XCTAssertTrue(sut.characteristics.isEmpty)
        XCTAssertNil(receiver.manufacturerData)
        XCTAssertNil(receiver.cscMeasurement)

        let exp = expectation(description: "manufacturerData")
        exp.expectedFulfillmentCount = 2
        let sub = receiver.$manufacturerData.sink { data in
            exp.fulfill()
        }
        given(peripheral.delegate).willReturn(manager)
        
        // When
        centralManager.delegate?.centralManager?(centralManager,
                                                 didDiscover: peripheral,
                                                 advertisementData: [CBAdvertisementDataServiceUUIDsKey: [CBUUID.cyclingSpeedAndCadenceService], CBAdvertisementDataManufacturerDataKey: "test".data(using: .utf8) as Any],
                                                 rssi: 100)
        waitForExpectations(timeout: 1)
        sub.cancel()

        // Then
        XCTAssertEqual(sut.advertisementData[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID], [CBUUID.cyclingSpeedAndCadenceService])
        XCTAssertNotNil(sut.manufacturerData)
        XCTAssertEqual(receiver.manufacturerData?.string(encoding: .utf8), "test")
        XCTAssertNil(receiver.cscMeasurement)

        
        // Given cscMeasurement
        let data = Data(hexString: "FFFF")
        let exp1 = expectation(description: "cscMeasurement")
        let times = 50
        exp1.expectedFulfillmentCount = 2
        let sub1 = receiver.$cscMeasurement.sink { _ in
            exp1.fulfill() // debounced
        }

        // When
        (0..<times).forEach { _ in
            peripheral.delegate?.peripheral?(peripheral, didUpdateValueFor: .mock(uuid: .cscMeasurement, service: .mock(uuid: .cyclingSpeedAndCadenceService), value: data), error: nil)
        }


        waitForExpectations(timeout: 1)
        sub1.cancel()
        
        // Then
        XCTAssertEqual(receiver.cscMeasurement?.hexEncodedString, "ffff")
    }
    
    func testConnectAsync() async throws {
        // Given
        XCTAssertEqual(sut.state, .disconnected)
        
        // When
        do {
            try await sut.connect(pending: false)
            XCTFail("not discovered yet")
        } catch {
            XCTAssertEqual(error as? BTError, BTError.notInRange)
        }
        
        // Then
        XCTAssertEqual(sut.state, .disconnected)
        
        // Given
        sut.inRangePublisher.value = true
        
        // When
        do {
            try await sut.connect(pending: false)
            XCTFail("not discovered yet")
        } catch {
            XCTAssertEqual(error as? BTError, BTError.pendingConnect)
        }
        
        // Then
        XCTAssertEqual(sut.state, .disconnected)
        
        // Given
        given(peripheral.delegate).willReturn(manager)
        centralManager.delegate?.centralManager?(centralManager,
                                                 didDiscover: peripheral,
                                                 advertisementData: [CBAdvertisementDataServiceUUIDsKey: [CBUUID.cyclingSpeedAndCadenceService], CBAdvertisementDataManufacturerDataKey: "test".data(using: .utf8) as Any],
                                                 rssi: 100)
        
        
        let exp = expectation(description: "state")
        let sub = sut.statePublisher.sink { competion in
            switch competion {
            case .finished:
                XCTFail()
            case .failure:
                XCTFail()
            }
        } receiveValue: { state in
            XCTAssertEqual(state, .connected)
            exp.fulfill()
        }
        
        // When
        do {
            try await sut.connect(pending: false)
        } catch {
            XCTAssertEqual(error as? BTError, BTError.pendingConnect)
        }
        
        // Then
        wait(for: [exp], timeout: 1)
        sub.cancel()
        XCTAssertEqual(sut.state, .connected)
    }
}
