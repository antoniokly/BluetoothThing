//
//  BluetoothThingPeripheral.swift
//  BluetoothThing
//
//  Created by Antonio Yip on 9/01/20.
//  Copyright © 2020 Antonio Yip. All rights reserved.
//

import Foundation
import CoreBluetooth
import os.log
import Combine

public class BluetoothThing: NSObject, Codable, Identifiable {
    
    static let didChange = Notification.Name("\(String(describing: BluetoothThing.self)).didChange")
    
    public private (set) var id: UUID
    public internal (set) var services: Set<BTService> = []
    public internal (set) var subscriptions: Set<BTSubscription> = []
    
    public override var debugDescription: String {
        name ?? id.uuidString
    }

    public internal (set) var state: ConnectionState = .disconnected {
        didSet {
            if state != oldValue {
                if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *) {
                    statePublisher.send(state)
                }
            }
        }
    }
    
    public internal (set) var advertisementData: [String : Any] = [:] {
        didSet {
            if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *) {
                advertisementDataPublisher.send(advertisementData)
            }
            NotificationCenter.default.post(name: Self.didChange, object: self.id)
        }
    }
    
    public var name: String? = nil {
        didSet {
            if name != oldValue {
                if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *) {
                    namePublisher.send(name)
                }
                NotificationCenter.default.post(name: Self.didChange, object: self.id)
            }
        }
    }
    
    public private(set) var characteristics: [BTCharacteristic: Data] = [:] {
        didSet {
            if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *) {
                characteristicsPublisher.send(characteristics)
            }
            NotificationCenter.default.post(name: Self.didChange, object: self.id)
        }
    }
    
    public func setCharateristic(_ key: BTCharacteristic, value: Data?) {
        characteristics[key] = value
        
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *) {
            (characteristicPublishers[key] as? CurrentValueSubject<Data?, Never>)?.send(value)
        }
    }
    
    public var customData: [String: Data] = [:] {
        didSet {
            if customData != oldValue {
                if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *) {
                    customDataPublisher.send(customData)
                }
                NotificationCenter.default.post(name: Self.didChange, object: self.id)
            }
        }
    }
    
    public var hardwareSerialNumber: String? {
        characteristics[.serialNumber]?.hexEncodedString
    }
    
    public var manufacturerData: Data? {
        advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data
    }
    
    public var advertisedServiceUUIDs: [CBUUID] {
        advertisementData[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID] ?? []
    }
    
    // MARK: - Publisher
    
    private var _advertisementDataPublisher: Any?
    private var _namePublisher: Any?
    private var _characteristicsPublisher: Any?
    private var _customDataPublisher: Any?
    private var _statePublisher: Any?
    private var _inRangePublisher: Any?
    private var _rssiPublisher: Any?
    private lazy var characteristicPublishers: [BTCharacteristic: Any] = [:]

    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    public var advertisementDataPublisher: CurrentValueSubject<[String : Any], Never> {
        cache(&_advertisementDataPublisher) {
            .init(self.advertisementData)
        }
    }
    
    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    public var namePublisher: CurrentValueSubject<String?, Never> {
        cache(&_namePublisher) {
            .init(self.name)
        }
    }
    
    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    public var characteristicsPublisher: CurrentValueSubject<[BTCharacteristic: Data], Never> {
        cache(&_characteristicsPublisher) {
            .init(self.characteristics)
        }
    }
    
    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    public var customDataPublisher: CurrentValueSubject<[String: Data], Never> {
        cache(&_customDataPublisher) {
            .init(self.customData)
        }
    }
    
    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    public var statePublisher: CurrentValueSubject<ConnectionState, Error> {
        cache(&_statePublisher) {
            .init(.disconnected)
        }
    }
    
    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    public var inRangePublisher: CurrentValueSubject<Bool, Never> {
        cache(&_inRangePublisher) {
            .init(false)
        }
    }
    
    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    public var rssiPublisher: CurrentValueSubject<Int?, Never> {
        cache(&_rssiPublisher) {
            .init(nil)
        }
    }
    
    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    public func advertisementDataPublisher<T>(for key: String) -> AnyPublisher<T?, Never> {
        advertisementDataPublisher
            .map { $0[key] as? T }
            .eraseToAnyPublisher()
    }
    
    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    public func manufacturerDataPublisher() -> AnyPublisher<Data?, Never> {
        advertisementDataPublisher(for: CBAdvertisementDataManufacturerDataKey)
            .eraseToAnyPublisher()
    }
    
    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    public func characteristicPublisher(for characteristic: BTCharacteristic) -> AnyPublisher<Data?, Never> {
        let subject: CurrentValueSubject<Data?, Never>
        
        if let pub = characteristicPublishers[characteristic] as? CurrentValueSubject<Data?, Never> {
            subject = pub
        } else {
            subject = CurrentValueSubject<Data?, Never>(characteristics[characteristic])
            characteristicPublishers[characteristic] = subject
        }
        
        return subject.eraseToAnyPublisher()
    }
    
    // MARK: - Async
    
    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    /// Async connect, with pending options in case of the device is unreachable.
    /// - Parameter pending: A flag to enable pending connection if the device is out of range. Error will be throw if pending = false adn the device is unreachable.
    public func connect(pending: Bool) async throws {
        try await withCheckedThrowingContinuation{ (continuation: CheckedContinuation<Void, Error>) in
            if !pending && !inRangePublisher.value {
                continuation.resume(throwing: BTError.notInRange)
                return
            }
                        
            let sub = statePublisher.receive(on: DispatchQueue.main).filter {
                $0 == .connected
            }.sink { completion in
                switch completion {
                case .finished:
                    break
                case .failure(let e):
                    continuation.resume(throwing: e)
                }
            } receiveValue: { _ in
                continuation.resume()
            }
            
            if !connect(completion: { sub.cancel() } ) {
                continuation.resume(throwing: BTError.pendingConnect)
            }
        }
    }
    
    // MARK: -
    
    var pendingConnect = false
    var disconnecting = false

    var pendingRequests: [BTRequest] = []

    var timer: Timer?
    
    var _connect: (() -> Void)?
    var _disconnect: ((Bool) -> Void)?
    var _request: ((BTRequest) -> Bool)?
    var _notify: ((Bool) -> Void)?
    var _subscribe: ((BTSubscription) -> Void)?
    var _unsubscribe: ((BTSubscription) -> Void)?
    var _onConnected: (() -> Void)?
    
    @available(*, deprecated, message: "Use connect()")
    public func connect(register: Bool) {
        connect()
    }
    
    @discardableResult
    /// Connect with completion handler
    /// - Parameter completion: One time handler will be executed when connected successfully.
    /// - Returns: Returns false if the connection cannot be performed immedialtely, however, the operation will be perfromed as soon as it is available. The operation will not be remembered after app restart.
    public func connect(completion: @escaping () -> Void = {}) -> Bool {
        disconnecting = false
        _onConnected = completion
        guard let _connect = _connect else {
            pendingConnect = true
            os_log("pending to connect %@", log: .bluetooth, type: .debug, self.debugDescription)
            return false
        }
        _connect()
        return true
    }
    
    @available(*, deprecated, message: "Connection will be restored if disconnected by the peripheral, other connection logic should be implemented by the app.")
    public func register() {
        connect()
    }
    
    @available(*, deprecated, message: "Use forget() or disconnect()")
    public func disconnect(deregister: Bool) {
        if deregister {
            forget()
        } else {
            disconnect()
        }
    }
    
    public func disconnect() {
        pendingConnect = false
        disconnecting = true
        _disconnect?(false)
    }
    
    @available(*, deprecated, renamed: "forget")
    public func deregister() {
        forget()
    }
    
    public func forget() {
        pendingConnect = false
        disconnecting = true
        _disconnect?(true)
    }
    
    /// Listen to changes of all subscriptions defined in BluethoothThingManager
    public func subscribe(_ notify: Bool = true) {
        _notify?(notify)
    }
    
    public func unsubscribe() {
        subscribe(false)
    }
    
    /// Listen to changes of subscriptions, but will not re-subscribe after disconnect
    public func subscribe(_ subscription: BTSubscription) {
        subscriptions.insert(subscription)
        _subscribe?(subscription)
    }
    
    public func unsubscribe(_ subscription: BTSubscription) {
        subscriptions.remove(subscription)
        _unsubscribe?(subscription)
    }
    
    public func subscribe(_ service: BTService) {
        subscribe(BTSubscription(service))
    }
    
    public func unsubscribe(_ service: BTService) {
        unsubscribe(BTSubscription(service))
    }

    public func subscribe(_ characteristic: BTCharacteristic) {
        subscribe(BTSubscription(characteristic))
    }
    
    public func unsubscribe(_ characteristic: BTCharacteristic) {
        unsubscribe(BTSubscription(characteristic))
    }
    
    // Read & write
    @discardableResult
    public func request(_ request: BTRequest) -> Bool {
        _request?(request) == true
    }
    
    @discardableResult
    public func read(_ characteristic: BTCharacteristic) -> Bool {
        request(BTRequest(method: .read, characteristic: characteristic))
    }
    
    @discardableResult
    public func write(_ characteristic: BTCharacteristic, value: Data?) -> Bool {
        request(BTRequest(method: .write, characteristic: characteristic, value: value))
    }
    
    public func hasService(_ service: BTService) -> Bool {
        hasService(service.uuid)
    }
    
    public func hasServices<T: Sequence>(_ services: T) -> Bool where T.Element == BTService {
        services.reduce(true) { $0 && hasService($1) }
    }
    
    public func hasService(_ serviceUUID: CBUUID) -> Bool {
        Set(services.map{ $0.uuid }).union(
            advertisementData[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID] ?? []
        ).contains(serviceUUID)
    }
    
    public func hasServices<T: Sequence>(_ serviceUUIDs: T) -> Bool where T.Element == CBUUID {
        serviceUUIDs.reduce(true) { $0 && hasService($1) }
    }
            
    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case characteristics
        case customData
    }
    
    public init(id: UUID, name: String? = nil) {
        self.id = id
        self.name = name
    }
    
    convenience init(peripheral: CBPeripheral) {
        self.init(id: peripheral.identifier, name: peripheral.name)
    }
}
