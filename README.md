# BluetoothThing

[![MIT License](https://img.shields.io/apm/l/atomic-design-ui.svg?)](https://github.com/antoniokly/BluetoothThing/blob/master/LICENSE)
[![codecov](https://codecov.io/gh/antoniokly/BluetoothThing/branch/master/graph/badge.svg?token=3XY446W8S5)](https://codecov.io/gh/antoniokly/BluetoothThing)

Find, connect and subscribe to Bluetooth peripherals without the hard works. Compatible with iOS 10.0+, watchOS 3.0+ and macOS with Bluetooth 4.

Integrates CoreBluetooth with CoreData and iCloud. Stores last known data and meta data of subscribed Bluetooth peripherals in CoreData with iCloud synchronization. (iCloud requires iOS 13.0+ or watchOS 6.0+ or macOS)

## Usage

```
import BluetoothThing  
```

Subscribe to GATT services

Find GATT UUID here: https://www.bluetooth.com/specifications/gatt/services/
```
let subscriptions = [
    Subscription(service: "180F"),
    Subscription(service: "180A")
]
```

CoreData Storage with iCloud sync (requires iCloud and remote notification background mode capability)
```
@available(iOS 13.0, watchOS 6.0, *)
BluetoothThingManager(delegate: BluetoothThingManagerDelegate, subscriptions: [Subscription], useCoreData: Bool, useCloudKit: Bool)
```

CoreData Storage only for older versions
```
BluetoothThingManager(delegate: BluetoothThingManagerDelegate, subscriptions: [Subscription], useCoreData: Bool)
```

Implement `BluetoothThingManagerDelegate`
```
public protocol BluetoothThingManagerDelegate {
    func bluetoothThingManager(_ manager: BluetoothThingManager, didFoundThing thing: BluetoothThing, rssi: NSNumber)
    func bluetoothThingManager(_ manager: BluetoothThingManager, didLoseThing thing: BluetoothThing)
    func bluetoothThingManager(_ manager: BluetoothThingManager, didFailToConnect thing: BluetoothThing, error: Error?)
    func bluetoothThingShouldSubscribeOnConnect(_ thing: BluetoothThing) -> Bool
    func bluetoothThing(_ thing: BluetoothThing, didChangeState state: ConnectionState)
    func bluetoothThing(_ thing: BluetoothThing, didChangeRSSI rssi: NSNumber)
    func bluetoothThing(_ thing: BluetoothThing, didUpdateValue value: Data?, for characteristic: BTCharacteristic, subscription: Subscription?)
}
```
