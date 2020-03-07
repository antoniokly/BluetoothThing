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
        super.init(persistentStore: UserDefaults.standard)
        self.things = peripherals.map({BluetoothThing(peripheral: $0)})
    }
    
}
