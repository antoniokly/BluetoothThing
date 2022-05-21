//
//  BluetoothThingManagerCombineTests.swift
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
class BluetoothThingManagerCombineTests: XCTestCase {
    
    var sut: BluetoothThingManager!
    var subscriptions: [BTSubscription]!
    var dataStore: DataStore!
    var centralManager: CBCentralManager!
    
    class Receiver: ObservableObject {
        @Published var things: Set<BluetoothThing> = []
        @Published var cyclingPowers: Set<BluetoothThing> = []
        
        init(manager: BluetoothThingManager) {
            manager.thingsPublisher
                .assign(to: &$things)
            
            manager.thingsPublisher(with: .cyclingPowerService)
                .debounce(for: 0.1, scheduler: DispatchQueue.main)
                .assign(to: &$cyclingPowers)
        }
    }
    
    override func setUpWithError() throws {
        
    }
    
    override func tearDownWithError() throws {
        
    }
    
    func testPublisher() {
        subscriptions = [
            BTSubscription(serviceUUID: .fff0),
            BTSubscription(serviceUUID: .cyclingPowerService)
        ]
        
        let peripherals = [CBPeripheral.mock(subscriptions: subscriptions)]
        let dataStore = DataStoreMock(peripherals: peripherals)
        let centralManager = CBCentralManagerMock(peripherals: peripherals)
        sut = BluetoothThingManager(subscriptions: subscriptions,
                                    dataStore: dataStore,
                                    centralManager: centralManager)
        
        // When
        let receiver = Receiver(manager: sut)
        
        // Then
        XCTAssertEqual(sut.knownThings.count, 1)
        XCTAssertEqual(receiver.cyclingPowers.count, 0)
        XCTAssertEqual(receiver.things.count, 1)
        XCTAssertEqual(receiver.things.map{ $0.id }, peripherals.map{ $0.identifier })
        
        // Given new fff0 Peripheral
        let newPeripheral = CBPeripheral.mock(subscriptions: subscriptions)
        let exp = expectation(description: "publisher")
        exp.expectedFulfillmentCount = 2
        let sub = receiver.$things.sink { things in
            exp.fulfill()
        }
        
        // When
        centralManager.delegate?.centralManager?(centralManager, didDiscover: newPeripheral, advertisementData: [CBAdvertisementDataServiceUUIDsKey: [CBUUID.fff0]], rssi: 100)
        
        // Then
        waitForExpectations(timeout: 1)
        sub.cancel()
        
        XCTAssertEqual(sut.knownThings.count, 2)
        XCTAssertEqual(receiver.cyclingPowers.count, 0)
        XCTAssertEqual(receiver.things.count, 2)
        
        // Given new cyclingPower Peripheral
        let exp1 = expectation(description: "cyclingPowers")
        exp1.expectedFulfillmentCount = 2
        let sub1 = receiver.$cyclingPowers.sink { things in
            exp1.fulfill()  // debounced should call 2 times only
        }
        
        // When
        centralManager.delegate?.centralManager?(centralManager, didDiscover: CBPeripheral.mock(identifier: UUID()), advertisementData: [CBAdvertisementDataServiceUUIDsKey: [CBUUID.cyclingPowerService]], rssi: 100)
        centralManager.delegate?.centralManager?(centralManager, didDiscover: CBPeripheral.mock(identifier: UUID()), advertisementData: [CBAdvertisementDataServiceUUIDsKey: [CBUUID.cyclingPowerService]], rssi: 10)
        
        // Then
        waitForExpectations(timeout: 1)
        sub1.cancel()
        
        XCTAssertEqual(sut.knownThings.count, 4)
        XCTAssertEqual(receiver.cyclingPowers.count, 2)
        XCTAssertEqual(receiver.things.count, 4)
    }
}
