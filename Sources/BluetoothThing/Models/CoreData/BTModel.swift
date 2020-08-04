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
                name: BTDiscovery.name,
                managedObjectClass: BTDiscovery.self,
                attributes: [
                    .attribute(name: "lastConnected", type: .dateAttributeType, isOptional: true),
                    .attribute(name: "lastDisconnected", type: .dateAttributeType, isOptional: true),
                    .attribute(name: "lastFound", type: .dateAttributeType, isOptional: true)
                ],
                relationships: [
                    .relationship(name: "central", destination: BTCentral.name, inverse: "discoveries"),
                    .relationship(name: "peripheral", destination: BTPeripheral.name, inverse: "discoveries")
                ]),
            .entity(
                name: BTCentral.name,
                managedObjectClass: BTCentral.self,
                attributes: [
                    .attribute(name: "id", type: .stringAttributeType, isOptional: true),
                    .attribute(name: "name", type: .stringAttributeType, isOptional: true)
                ],
                relationships: [
                    .relationship(name: "discoveries", destination: BTDiscovery.name, toMany: true, deleteRule: .nullifyDeleteRule, inverse: "central"),
                ]),
            .entity(
                name: BTPeripheral.name,
                managedObjectClass: BTPeripheral.self,
                attributes: [
                    .attribute(name: "id", type: .stringAttributeType, isOptional: true),
                    .attribute(name: "name", type: .stringAttributeType, isOptional: true)
                ],
                relationships: [
                    .relationship(name: "customData", destination: CustomData.name, toMany: true, deleteRule: .cascadeDeleteRule, inverse: "peripheral"),
                    .relationship(name: "discoveries", destination: BTDiscovery.name, toMany: true, deleteRule: .cascadeDeleteRule, inverse: "peripheral"),
                    .relationship(name: "services", destination: GATTService.name, toMany: true, deleteRule: .cascadeDeleteRule, inverse: "peripheral"),
                ]),
            .entity(
                name: CustomData.name,
                managedObjectClass: CustomData.self,
                attributes: [
                    .attribute(name: "key", type: .stringAttributeType, isOptional: true),
                    .attribute(name: "modifiedAt", type: .dateAttributeType, isOptional: true),
                    .attribute(name: "value", type: .binaryDataAttributeType, isOptional: true),
                ],
                relationships: [
                    .relationship(name: "peripheral", destination: BTPeripheral.name, inverse: "customData"),
                ]),
            .entity(
                name: GATTService.name,
                managedObjectClass: GATTService.self,
                attributes: [
                    .attribute(name: "id", type: .stringAttributeType, isOptional: true),
                    .attribute(name: "name", type: .stringAttributeType, isOptional: true)
                ],
                relationships: [
                    .relationship(name: "peripheral", destination: BTPeripheral.name, inverse: "services"),
                    .relationship(name: "characteristics", destination: GATTCharacteristic.name, toMany: true, deleteRule: .cascadeDeleteRule, inverse: "service"),
                ]),
            .entity(
                name: GATTCharacteristic.name,
                managedObjectClass: GATTCharacteristic.self,
                attributes: [
                    .attribute(name: "id", type: .stringAttributeType, isOptional: true),
                    .attribute(name: "name", type: .stringAttributeType, isOptional: true),
                    .attribute(name: "value", type: .binaryDataAttributeType, isOptional: true),
                ],
                relationships: [
                    .relationship(name: "service", destination: GATTService.name, inverse: "characteristics"),
                ]),
        ]
    )
}


