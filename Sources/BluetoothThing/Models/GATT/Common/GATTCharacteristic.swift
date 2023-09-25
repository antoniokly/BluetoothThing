//
//  GATTCharacteristic.swift
//
//
//  Created by Antonio Yip on 7/9/2023.
//

import Foundation

protocol GATTOpCodes {
    associatedtype T: FixedWidthInteger
    var opCodeData: GATTData<T, Dimension> { get }
}

extension GATTOpCodes {
    var opCode: UInt {
        UInt(opCodeData.rawValue)
    }
}

protocol GATTFeatureFlags {
    associatedtype T: FixedWidthInteger
    var flags: GATTData<T, Dimension> { get }
}

extension GATTFeatureFlags {
    func featureFlag(_ bitIndex: UInt) -> Bool {
        flags.rawValue.bit(bitIndex)
    }
}

protocol GATTCharacteristic: GATTCharacteristicUpdatable {
    var characteristic: BTCharacteristic { get }
}

protocol GATTCharacteristicUpdatable {
    
}

extension GATTCharacteristicUpdatable {
    func update( _ bytes: inout [UInt8]) {
        Mirror(reflecting: self).children.compactMap {
            $0.value as? DataUpdatable
        }.forEach {
            if bytes.isEmpty {
                return
            }
            
            if let gattData = $0 as? GATTDataUpdatable,
               bytes.count < gattData.byteWidth {
                bytes.append(contentsOf: [UInt8](repeating: 0, count: gattData.byteWidth - bytes.count))
            }
            
            if let self = self as? (any GATTFeatureFlags),
               let featureUpdatable = $0 as? GATTFeatureUpdatable,
               let i = featureUpdatable.flagIndex,
               self.featureFlag(i) == false {
                return
            }
            
            if let self = self as? (any GATTOpCodes),
               let opCodeUpdatable = $0 as? GATTOpCodeUpdatable,
               let opCode = opCodeUpdatable.opCode,
               self.opCode != opCode {
                return
            }
            
            $0.update(&bytes)
        }
    }
    
    func update(_ data: Data) {
        var bytes = [UInt8](data)
        update(&bytes)
    }
}
