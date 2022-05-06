// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "UISwift",
	platforms: [
		.iOS("11.0"),
	],
    products: [
        .library(name: "UISwift", targets: ["UISwift"]),
	],
    dependencies: [],
    targets: [
		.target(name: "UISwift", dependencies: [], path: "Classes"),
	]
)
