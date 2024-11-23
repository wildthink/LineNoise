// swift-tools-version:6.0
// The swift-tools-version declares the minimum
// version of Swift required to build this package.


import PackageDescription

let package = Package(
    name: "LineNoise",
	platforms: [
        .macOS(.v12),
	],
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(
            name: "LineNoise",
            targets: ["LineNoise"]),
        .executable(
            name: "linenoiseDemo",
            targets: ["linenoiseDemo"]),
    ],
    dependencies: [
//        .package(url: "https://github.com/Quick/Nimble.git", from: "13.0.0"),
//		.package(url: "https://github.com/apple/swift-system", from: "1.2.1"),
//		.package(url: "https://github.com/apple/swift-argument-parser", from: "1.2.3"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "LineNoise",
            dependencies: [
//                .product(name: "SystemPackage", package: "swift-system"),
//						   .product(name: "Toolbox", package: "Toolbox")
						  ],
            path: "Sources/linenoise"),
        .executableTarget(
            name: "linenoiseDemo",
            dependencies: [
				"LineNoise",
//				.product(name: "ArgumentParser", package: "swift-argument-parser"),
			]),
        .testTarget(
            name: "linenoiseTests",
            dependencies: ["LineNoise"]),
    ]
)
