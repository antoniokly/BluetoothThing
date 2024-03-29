// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "BluetoothThing",
    platforms: [.macOS(.v10_13),
                .iOS(.v11),
                .tvOS(.v11),
                .watchOS("7.4")],
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(
            name: "BluetoothThing",
            targets: ["BluetoothThing"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
         .package(name: "CoreDataModelDescription",
                  url: "https://github.com/antoniokly/core-data-model-description",
                  .upToNextMajor(from: "0.0.12")),
         .package(name: "Mockingbird",
                  url: "https://github.com/birdrides/mockingbird.git",
                  .upToNextMajor(from: "0.20.0"))
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "BluetoothThing",
            dependencies: ["CoreDataModelDescription"]),
        .testTarget(
            name: "BluetoothThingTests",
            dependencies: ["BluetoothThing", "Mockingbird"]),
    ]
)
