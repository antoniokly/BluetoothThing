//
//  DataUpdatable.swift
//
//
//  Created by Antonio Yip on 24/9/2023.
//

import Foundation

protocol DataUpdatable {
    func update( _ bytes: inout [UInt8])
}

protocol GATTOpCodeUpdatable: DataUpdatable {
    var opCode: UInt? { get }
}

protocol GATTFeatureUpdatable: DataUpdatable {
    var flagIndex: UInt? { get }
}

protocol GATTDataUpdatable: DataUpdatable {
    var byteWidth: Int { get }
}
