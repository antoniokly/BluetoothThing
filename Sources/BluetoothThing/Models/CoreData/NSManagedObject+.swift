//
//  NSManagedObject+.swift
//  BluetoothThing
//
//  Created by Antonio Yip on 30/05/20.
//  Copyright © 2020 Antonio Yip. All rights reserved.
//

import CoreData

extension NSManagedObject {
    static var name: String {
        String(describing: Self.self)
    }
}
