//
//  BluetoothThingRequest.swift
//  BluetoothThing
//
//  Created by Antonio Yip on 20/01/20.
//  Copyright © 2020 Antonio Yip. All rights reserved.
//

import Foundation

public struct BluetoothThingRequest {
    enum Method {
        case read
        case write
    }
    
    var method: Method
    var subscription: Subscription
    var value: Data? = nil
}
