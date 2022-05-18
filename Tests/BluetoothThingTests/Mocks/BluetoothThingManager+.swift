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
    convenience init<T: Sequence>(delegate: BluetoothThingManagerDelegate,
                     subscriptions: T,
                     dataStore: DataStoreProtocol,
                     centralManager: CBCentralManagerMock) where T.Element == BTSubscription {
        self.init(delegate: delegate, subscriptions: subscriptions, restoreID: nil)
        self.dataStore = dataStore
        self.knownThings = Set(dataStore.things)
        self.centralManager = centralManager
        centralManager.delegate = self
    }
}
