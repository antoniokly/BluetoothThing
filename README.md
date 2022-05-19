# BluetoothThing
[![iOS](https://github.com/antoniokly/BluetoothThing/workflows/iOS/badge.svg)](https://github.com/antoniokly/BluetoothThing/actions)
[![tvOS](https://github.com/antoniokly/BluetoothThing/workflows/tvOS/badge.svg)](https://github.com/antoniokly/BluetoothThing/actions)
[![watchOS](https://github.com/antoniokly/BluetoothThing/workflows/watchOS/badge.svg)](https://github.com/antoniokly/BluetoothThing/actions)
[![macOS](https://github.com/antoniokly/BluetoothThing/workflows/macOS/badge.svg)](https://github.com/antoniokly/BluetoothThing/actions)
[![codecov](https://codecov.io/gh/antoniokly/BluetoothThing/branch/master/graph/badge.svg?token=3XY446W8S5)](https://codecov.io/gh/antoniokly/BluetoothThing)
[![Latest Stable Version](https://img.shields.io/github/v/tag/antoniokly/BluetoothThing?color=orange&label=Swift%20Package)](https://developer.apple.com/documentation/xcode/adding_package_dependencies_to_your_app)
[![Platforms iOS | watchOS | tvOS | macOS](https://img.shields.io/badge/platforms-iOS%2011.0%20%7C%20tvOS%2011.0%20%7C%20watchOS%207.4%20%7C%20macOS%2010.13-orange.svg)](https://developer.apple.com/documentation/swiftui)
[![GitHub](https://img.shields.io/github/license/antoniokly/HandySwiftUI?color=orange)](https://github.com/antoniokly/BluetoothThing/blob/master/LICENSE)

Find, connect and subscribe to Bluetooth LE peripherals without the hard works.

Integrates CoreBluetooth with CoreData and CloudKit. Stores last known data and meta data of subscribed Bluetooth peripherals in CoreData database and synchronized on iCloud. (iCloud sync requires iOS 13.0+, watchOS 6.0+, macOS 10.15+ or tvOS 13.0+)

## Usage

```swift
import BluetoothThing  
```

Subscribe to GATT services or GATT Characteristics

Find GATT UUIDs here: https://www.bluetooth.com/specifications/gatt/services/
```swift
let subscriptions = [
    Subscription(service: "180A"), // Device Information
    Subscription(service: "180F" , "2A19") // Battery Level
]
```

CoreData Storage with iCloud sync (requires iCloud and remote notification background mode capability)
```swift
@available(iOS 13.0, watchOS 6.0, macOS 10.15, tvOS 13.0, *)
BluetoothThingManager(delegate: BluetoothThingManagerDelegate, subscriptions: [Subscription], useCoreData: Bool, useCloudKit: Bool)
```

CoreData local Storage for older versions
```swift
let btManager = BluetoothThingManager(delegate: BluetoothThingManagerDelegate, subscriptions: [Subscription], useCoreData: Bool)
```

Implement `BluetoothThingManagerDelegate`
```swift
protocol BluetoothThingManagerDelegate {
    func bluetoothThingManager(_ manager: BluetoothThingManager, didChangeState state: BluetoothState)
    func bluetoothThingManager(_ manager: BluetoothThingManager, didFindThing thing: BluetoothThing, rssi: NSNumber)
    func bluetoothThingManager(_ manager: BluetoothThingManager, didLoseThing thing: BluetoothThing)
    func bluetoothThingManager(_ manager: BluetoothThingManager, didFailToConnect thing: BluetoothThing, error: Error?)
    func bluetoothThing(_ thing: BluetoothThing, didChangeState state: ConnectionState)
    func bluetoothThing(_ thing: BluetoothThing, didChangeRSSI rssi: NSNumber)
    func bluetoothThing(_ thing: BluetoothThing, didUpdateValue value: Data?, for characteristic: BTCharacteristic, subscription: BTSubscription?)
}
```

Retrive Things
```swift
let thing = btManager.things.first
```

Methods
```swift
thing.connect() // Can be called anytime, will connect once comes in range

thing.disconnect()

thing.register() // always reconnect if reachable

thing.deregister() //

thing.read(characteristic) // read once, no notify

thing.subscribe(characteristic) // get notified when data changes

thing.write(characteristic) // write to characteristic
```

## Donation

[![](https://www.paypalobjects.com/en_US/i/btn/btn_donateCC_LG.gif)](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=UXRR2S35YMCQC&source=url)
