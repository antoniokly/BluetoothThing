//
//  GATTCharacteristic.swift
//
//
//  Created by Antonio Yip on 7/9/2023.
//

import Foundation

protocol GATTFeatureFlags {
    associatedtype T: FixedWidthInteger
    var flags: GATTData<T, Dimension> { get }
}

extension GATTFeatureFlags {
    func featureFlag(_ bitIndex: Int) -> Bool {
        flags.rawValue.bit(bitIndex)
    }
}

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
            
            if let self = self as? (any GATTFeatureFlags),
               let i = $0.flagIndex,
               self.featureFlag(i) == false {
                return
            }
            
            $0.update(bytes.prefix(upTo: $0.byteWidth))
            bytes.removeFirst($0.byteWidth)
        }
    }
}
