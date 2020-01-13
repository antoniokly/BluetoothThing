//
//  DataStoreMock.swift
//  BluetoothThingTests
//
//  Created by Antonio Yip on 13/01/20.
//  Copyright © 2020 Antonio Yip. All rights reserved.
//

import Foundation
@testable import BluetoothThing

class DataStoreMock: DataStore {
    
    init(peripherals: [CBPeripheralMock]) {
        super.init()
        self.things = peripherals.map({BluetoothThing(id: $0.identifier)})
    }
    
    override func save() {
        
    }

//    var things: [BluetoothThing] = []
//
//    func save() {
//
//    }
//
//    func getThing(id: UUID) -> BluetoothThing? {
//        return BluetoothThing(id: id)
//    }
//
//    func removeThing(id: UUID) -> Bool {
//        return true
//    }
//
    override func getStoredThings() -> [BluetoothThing] {
        return things
    }
    
    
}
