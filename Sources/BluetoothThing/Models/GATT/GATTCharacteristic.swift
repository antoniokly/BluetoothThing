//
//  GATTCharacteristic.swift
//
//
//  Created by Antonio Yip on 7/9/2023.
//

import Foundation

protocol GATTCharacteristic {
    var characteristic: BTCharacteristic { get }
}

extension GATTCharacteristic {
    mutating func update(_ data: Data) {
        var bytes = [UInt8](data)
        
        Mirror(reflecting: self).children.compactMap {
            $0.value as? GATTDataUpdatable
        }.forEach {
            if bytes.count < $0.byteWidth {
                return
            }
            $0.update(bytes.prefix(upTo: $0.byteWidth))
            bytes.removeFirst($0.byteWidth)
        }
    }
}
