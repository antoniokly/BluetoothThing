//
//  BluetoothThingRequest.swift
//  BluetoothThing
//
//  Created by Antonio Yip on 20/01/20.
//  Copyright © 2020 Antonio Yip. All rights reserved.
//

import Foundation
import CoreBluetooth

public struct BTRequest: Identifiable, Equatable {
    public static func == (lhs: BTRequest, rhs: BTRequest) -> Bool {
        lhs.id == rhs.id
    }
    
    public enum Method: String {
        case read
        case write
    }
    
    public let id: UUID = UUID()
    public private (set) var method: Method
    public private (set) var characteristic: BTCharacteristic
    public private (set) var value: Data?
    var completion: () -> Void
    
    public init(method: Method, characteristic: BTCharacteristic, value: Data? = nil, completion: @escaping () -> Void = {}) {
        self.method = method
        self.characteristic = characteristic
        self.value = value
        self.completion = completion
    }
}
