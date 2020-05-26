# BluetoothThing 
Bluetooth easy as a thing
[![Swift 5.1](https://img.shields.io/badge/Swift-5.1-orange.svg?style=flat)](https://swift.org)
[![Platforms iOS | watchOS | tvOS | macOS](https://img.shields.io/badge/Platforms-iOS%20%7C%20watchOS%20%7C%20tvOS%20%7C%20macOS-lightgray.svg?style=flat)](http://www.apple.com)
[![MIT License](https://img.shields.io/apm/l/atomic-design-ui.svg?)](https://github.com/antoniokly/BluetoothThing/blob/master/LICENSE)
[![codecov](https://codecov.io/gh/antoniokly/BluetoothThing/branch/master/graph/badge.svg?token=3XY446W8S5)](https://codecov.io/gh/antoniokly/BluetoothThing)

Find, connect and subscribe to Bluetooth LE peripherals without the hard works.

Integrates CoreBluetooth with CoreData and CloudKit. Stores last known data and meta data of subscribed Bluetooth peripherals in CoreData database and synchronized on iCloud. (iCloud sync requires iOS 13.0+, watchOS 6.0+, macOS 10.15+ or tvOS 13.0+)

## Usage

```
import BluetoothThing  
```

Subscribe to GATT services or GATT Characteristics

Find GATT UUIDs here: https://www.bluetooth.com/specifications/gatt/services/
```
let subscriptions = [
    Subscription(service: "180A"), // Device Information
    Subscription(service: "180F" , "2A19") // Battery Level
]
```

CoreData Storage with iCloud sync (requires iCloud and remote notification background mode capability)
```
@available(iOS 13.0, watchOS 6.0, macOS 10.15, tvOS 13.0, *)
BluetoothThingManager(delegate: BluetoothThingManagerDelegate, subscriptions: [Subscription], useCoreData: Bool, useCloudKit: Bool)
```

CoreData local Storage for older versions
```
BluetoothThingManager(delegate: BluetoothThingManagerDelegate, subscriptions: [Subscription], useCoreData: Bool)
```

Implement `BluetoothThingManagerDelegate`
```
protocol BluetoothThingManagerDelegate {
    func bluetoothThingManager(_ manager: BluetoothThingManager, didChangeState state: BluetoothState)
    func bluetoothThingManager(_ manager: BluetoothThingManager, didFoundThing thing: BluetoothThing, rssi: NSNumber)
    func bluetoothThingManager(_ manager: BluetoothThingManager, didLoseThing thing: BluetoothThing)
    func bluetoothThingManager(_ manager: BluetoothThingManager, didFailToConnect thing: BluetoothThing, error: Error?)
    func bluetoothThing(_ thing: BluetoothThing, didChangeState state: ConnectionState)
    func bluetoothThing(_ thing: BluetoothThing, didChangeRSSI rssi: NSNumber)
    func bluetoothThing(_ thing: BluetoothThing, didUpdateValue value: Data?, for characteristic: BTCharacteristic, subscription: BTSubscription?)
}
```
