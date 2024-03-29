// swift-tools-version:5.1

import PackageDescription

let package = Package(
    name: "FluxorExplorerInterceptor",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v13),
        .tvOS(.v13),
    ],
    products: [
        .library(
            name: "FluxorExplorerInterceptor",
            targets: ["FluxorExplorerInterceptor"]),
    ],
    dependencies: [
        .package(url: "https://github.com/FluxorOrg/Fluxor",
                 from: "5.0.1"),
        .package(url: "https://github.com/FluxorOrg/FluxorExplorerSnapshot",
                 from: "5.0.0"),
    ],
    targets: [
        .target(
            name: "FluxorExplorerInterceptor",
            dependencies: ["Fluxor", "FluxorExplorerSnapshot"]),
        .testTarget(
            name: "FluxorExplorerInterceptorTests",
            dependencies: ["Fluxor", "FluxorExplorerInterceptor"]),
    ])
