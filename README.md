# BluetoothThing

[![codecov](https://codecov.io/gh/antoniokly/BluetoothThing/branch/master/graph/badge.svg?token=3XY446W8S5)](https://codecov.io/gh/antoniokly/BluetoothThing)

Find, connect and subscribe to Bluetooth peripherals without much codes, the hard works are done in this framework. Compatible with iOS 10.0+ and watchOS 3.0+.

Integrates CoreBluetooth with CoreLocation, CoreData and iCloud. Stores last known data and locations of subscribed Bluetooth peripherals using CoreData with iCloud sync (iOS 13.0+ and watchOS 6.0+).

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
BluetoothThingManager(delegate: self, subscriptions: subscriptions, useLocation: true, useCoreData: true, useCloudKit: true)
```

CoreData Storage only for older versions
```
BluetoothThingManager(delegate: BluetoothThingManagerDelegate, subscriptions: [Subscription], useLocation: Bool = false, useCoreData: Bool = false)
```

Implement `BluetoothThingManagerDelegate`
```
public protocol BluetoothThingManagerDelegate {
    
    var centralId: UUID { get }
    
    func bluetoothThingManager(_ manager: BluetoothThingManager, didFoundThing thing: BluetoothThing, rssi: NSNumber)
    func bluetoothThingManager(_ manager: BluetoothThingManager, didLoseThing thing: BluetoothThing)
    func bluetoothThingManager(_ manager: BluetoothThingManager, didFailToConnect thing: BluetoothThing, error: Error?)
    func bluetoothThingManager(_ manager: BluetoothThingManager, locationDidFailWithError error: Error)
    
    func bluetoothThingShouldSubscribeOnConnect(_ thing: BluetoothThing) -> Bool
    func bluetoothThing(_ thing: BluetoothThing, didChangeState state: ConnectionState)
    func bluetoothThing(_ thing: BluetoothThing, didChangeRSSI rssi: NSNumber)
    func bluetoothThing(_ thing: BluetoothThing, didUpdateLocation location: Location)
    func bluetoothThing(_ thing: BluetoothThing, didUpdateValue value: Data?, for characteristic: BTCharacteristic, subscription: Subscription)
}
```
