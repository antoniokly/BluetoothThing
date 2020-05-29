// swift-tools-version:5.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "BluetoothThing",
    platforms: [.macOS(.v10_13),
                .iOS(.v11),
                .tvOS(.v11),
                .watchOS(.v4)],
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(
            name: "BluetoothThing",
            targets: ["BluetoothThing"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
         .package(url: "https://github.com/antoniokly/core-data-model-description", from: "0.0.12"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "BluetoothThing",
            dependencies: []),
        .testTarget(
            name: "BluetoothThingTests",
            dependencies: ["BluetoothThing"]),
    ]
)

#if os(iOS)
package.targets.first(where: { $0.name == "BluetoothThing" })!
    .exclude += [
        "Helpers/Constants+Watch.swift",
        "Helpers/Constants+Mac.swift",
        "Helpers/Constants+TV.swift",
    ]
#elseif os(macOS)
package.targets.first(where: { $0.name == "BluetoothThing" })!
    .exclude += [
        "Helpers/Constants+iOS.swift",
        "Helpers/Constants+Watch.swift",
        "Helpers/Constants+TV.swift",
    ]
#elseif os(watchOS)
package.targets.first(where: { $0.name == "BluetoothThing" })!
    .exclude += [
        "Helpers/Constants+iOS.swift",
        "Helpers/Constants+Mac.swift",
        "Helpers/Constants+TV.swift",
    ]
#elseif os(tvOS)
package.targets.first(where: { $0.name == "BluetoothThing" })!
    .exclude += [
        "Helpers/Constants+iOS.swift",
        "Helpers/Constants+Mac.swift",
        "Helpers/Constants+Watch.swift",
    ]
#endif
