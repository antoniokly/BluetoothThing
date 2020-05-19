//
//  BluetoothThingManager+.swift
//  BluetoothThingTests
//
//  Created by Antonio Yip on 19/05/20.
//  Copyright © 2020 Antonio Yip. All rights reserved.
//

import Foundation
import CoreBluetooth
@testable import BluetoothThing

extension BluetoothThingManager {
    // MARK: - Internal Initializer
    convenience init(delegate: BluetoothThingManagerDelegate,
                     subscriptions: [BTSubscription],
                     dataStore: DataStoreProtocol,
                     centralManager: CBCentralManagerMock) {
        self.init(delegate: delegate, subscriptions: subscriptions)
        self.dataStore = dataStore
        self.knownThings = Set(dataStore.things)
        self.centralManager = centralManager
        centralManager.delegate = self
    }
}
