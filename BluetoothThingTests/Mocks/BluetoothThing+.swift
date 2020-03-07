//
//  BluetoothThing+.swift
//  BluetoothThingTests
//
//  Created by Antonio Yip on 7/03/20.
//  Copyright © 2020 Antonio Yip. All rights reserved.
//

import Foundation
@testable import BluetoothThing

extension BluetoothThing {
    convenience init(id: UUID, name: String? = nil, serialNumber: Data? = nil) {
        self.init(id: id, name: name)
        self.characteristics[.serialNumber] = serialNumber
    }
}
