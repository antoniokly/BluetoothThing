//
//  GATTCharacteristic.swift
//
//
//  Created by Antonio Yip on 7/9/2023.
//

import Foundation

protocol GATTCharacteristic {
    var characteristic: BTCharacteristic { get }
    
    var gattData: [any GATTDataUpdatable] { get }
    
//    mutating func update(_ data: Data)
//
//    mutating func updateFlags()

}

extension GATTCharacteristic {
    mutating func update(_ data: Data) {
        var bytes = [UInt8](data)
        
        gattData.forEach {
            $0.update(bytes.prefix(upTo: $0.byteWidth))
            bytes.removeFirst($0.byteWidth)
        }
        
//        updateFlags()
    }
}
