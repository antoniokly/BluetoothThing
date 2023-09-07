//
//  CoreDataModel.swift
//  BluetoothThing
//
//  Created by Antonio Yip on 30/05/20.
//  Copyright © 2020 Antonio Yip. All rights reserved.
//

import Foundation
import CoreData
import CoreDataModelDescription

struct BTModel {
    static let name = String(describing: Self.self)
    
    static let modelDescription = CoreDataModelDescription(
        entities: [
            .entity(
                name: BTDiscoveryStorage.name,
                managedObjectClass: BTDiscoveryStorage.self,
                attributes: [
                    .attribute(name: "lastConnected", type: .dateAttributeType, isOptional: true),
                    .attribute(name: "lastDisconnected", type: .dateAttributeType, isOptional: true),
                    .attribute(name: "lastFound", type: .dateAttributeType, isOptional: true)
                ],
                relationships: [
                    .relationship(name: "central", destination: BTCentralStorage.name, inverse: "discoveries"),
                    .relationship(name: "peripheral", destination: BTPeripheralStorage.name, inverse: "discoveries")
                ]),
            .entity(
                name: BTCentralStorage.name,
                managedObjectClass: BTCentralStorage.self,
                attributes: [
                    .attribute(name: "id", type: .stringAttributeType, isOptional: true),
                    .attribute(name: "name", type: .stringAttributeType, isOptional: true)
                ],
                relationships: [
                    .relationship(name: "discoveries", destination: BTDiscoveryStorage.name, toMany: true, deleteRule: .nullifyDeleteRule, inverse: "central"),
                ]),
            .entity(
                name: BTPeripheralStorage.name,
                managedObjectClass: BTPeripheralStorage.self,
                attributes: [
                    .attribute(name: "id", type: .stringAttributeType, isOptional: true),
                    .attribute(name: "name", type: .stringAttributeType, isOptional: true)
                ],
                relationships: [
                    .relationship(name: "customData", destination: BTCustomDataStorage.name, toMany: true, deleteRule: .cascadeDeleteRule, inverse: "peripheral"),
                    .relationship(name: "discoveries", destination: BTDiscoveryStorage.name, toMany: true, deleteRule: .cascadeDeleteRule, inverse: "peripheral"),
                    .relationship(name: "services", destination: BTServiceStorage.name, toMany: true, deleteRule: .cascadeDeleteRule, inverse: "peripheral"),
                ]),
            .entity(
                name: BTCustomDataStorage.name,
                managedObjectClass: BTCustomDataStorage.self,
                attributes: [
                    .attribute(name: "key", type: .stringAttributeType, isOptional: true),
                    .attribute(name: "modifiedAt", type: .dateAttributeType, isOptional: true),
                    .attribute(name: "value", type: .binaryDataAttributeType, isOptional: true),
                ],
                relationships: [
                    .relationship(name: "peripheral", destination: BTPeripheralStorage.name, inverse: "customData"),
                ]),
            .entity(
                name: BTServiceStorage.name,
                managedObjectClass: BTServiceStorage.self,
                attributes: [
                    .attribute(name: "id", type: .stringAttributeType, isOptional: true),
                    .attribute(name: "name", type: .stringAttributeType, isOptional: true)
                ],
                relationships: [
                    .relationship(name: "peripheral", destination: BTPeripheralStorage.name, inverse: "services"),
                    .relationship(name: "characteristics", destination: BTCharacteristicStorage.name, toMany: true, deleteRule: .cascadeDeleteRule, inverse: "service"),
                ]),
            .entity(
                name: BTCharacteristicStorage.name,
                managedObjectClass: BTCharacteristicStorage.self,
                attributes: [
                    .attribute(name: "id", type: .stringAttributeType, isOptional: true),
                    .attribute(name: "name", type: .stringAttributeType, isOptional: true),
                    .attribute(name: "value", type: .binaryDataAttributeType, isOptional: true),
                ],
                relationships: [
                    .relationship(name: "service", destination: BTServiceStorage.name, inverse: "characteristics"),
                ]),
        ]
    )
}


