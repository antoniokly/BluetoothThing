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
    // MARK: - Convenience Initializer for Testing
    convenience init<T: Sequence>(delegate: BluetoothThingManagerDelegate? = nil,
                                  subscriptions: T,
                                  dataStore: DataStoreProtocol,
                                  centralManager: CBCentralManager) where T.Element == BTSubscription {
        self.init(delegate: delegate,
                  subscriptions: subscriptions,
                  dataStore: dataStore,
                  restoreID: nil)
        self.centralManager = centralManager
        centralManager.delegate = self
    }
}
