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
    
    // Pretending a view model
    class Receiver: ObservableObject {
        @Published var manufacturerData: Data?
        @Published var cscMeasurement: Data?
        @Published var rssi: Int?

        init(device: BluetoothThing) {
            device.manufacturerDataPublisher()
                .debounce(for: 0.1, scheduler: DispatchQueue.main)
                .assign(to: &$manufacturerData)
            
            device.characteristicPublisher(for: .cscMeasurement)
                .assign(to: &$cscMeasurement)
            
            device.rssiPublisher
                .removeDuplicates()
                .debounce(for: 0.1, scheduler: DispatchQueue.main)
                .assign(to: &$rssi)
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
        
        let rssi = Int.random(in: -100..<0)
        let expRSSI = expectation(description: "rssi")
        let subRSSI = receiver.$rssi
            .dropFirst() // ignore initial value
            .sink {
                XCTAssertEqual($0, rssi)
                expRSSI.fulfill()
            }
        
        // When
        centralManager.delegate?.centralManager?(centralManager,
                                                 didDiscover: peripheral,
                                                 advertisementData: [CBAdvertisementDataServiceUUIDsKey: [CBUUID.cyclingSpeedAndCadenceService], CBAdvertisementDataManufacturerDataKey: "test".data(using: .utf8) as Any],
                                                 rssi: rssi as NSNumber)
        waitForExpectations(timeout: 1)
        sub.cancel()
        subRSSI.cancel()

        // Then
        XCTAssertEqual(sut.advertisementData[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID], [CBUUID.cyclingSpeedAndCadenceService])
        XCTAssertNotNil(sut.manufacturerData)
        XCTAssertEqual(receiver.manufacturerData?.string(encoding: .utf8), "test")
        XCTAssertNil(receiver.cscMeasurement)

        
        // Given cscMeasurement
        let data = Data(hexString: "FFFF")
        let exp1 = expectation(description: "cscMeasurement")
        let repeats = Int.random(in: 1..<50)
        exp1.expectedFulfillmentCount = repeats + 1 // + 1 initial
        let sub1 = receiver.$cscMeasurement.sink { _ in
            exp1.fulfill()
        }
        
        // When
        (0 ..< repeats).forEach { _ in
            peripheral.delegate?.peripheral?(peripheral, didUpdateValueFor: .mock(uuid: .cscMeasurement, service: .mock(uuid: .cyclingSpeedAndCadenceService), value: data), error: nil)
            
            // should not be received by cscMeasurement
            peripheral.delegate?.peripheral?(peripheral, didUpdateValueFor: .mock(uuid: .cscFeature, service: .mock(uuid: .cyclingSpeedAndCadenceService), value: Data(hexString: "0001")), error: nil)
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
        // Discovered now
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
