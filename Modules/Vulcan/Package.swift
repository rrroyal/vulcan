// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Vulcan",
	platforms: [
		.iOS(.v14),
		.macOS(.v11),
		.watchOS(.v7)
	],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "Vulcan",
            targets: ["Vulcan"])
    ],
    dependencies: [
		.package(url: "https://github.com/kishikawakatsumi/KeychainAccess.git", from: "4.0.0"),
		// .package(path: "../AppNotifications")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "Vulcan",
            dependencies: ["KeychainAccess"]),
        .testTarget(
            name: "VulcanTests",
            dependencies: ["Vulcan"]),
    ]
)
