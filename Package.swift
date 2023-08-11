// swift-tools-version: 5.8

import PackageDescription

#if swift(<5.9)

let package = Package(
    name: "Semalot",
    platforms: [
        .macOS(.v11),
        .iOS(.v14),
        .watchOS(.v7)
    ],
    products: [
        .library(
            name: "Semalot",
            targets: ["Semalot"]),
    ],
    dependencies: [
        .package(url: "https://github.com/ptsochantaris/lista", branch: "main")
    ],
    targets: [
        .target(
            name: "Semalot",
            dependencies: [
                .product(name: "Lista", package: "lista")
            ]),
        .testTarget(
            name: "SemalotTests",
            dependencies: ["Semalot"]),
    ]
)

#else

let package = Package(
    name: "Semalot",
    platforms: [
        .macOS(.v11),
        .iOS(.v14),
        .watchOS(.v7)
    ],
    products: [
        .library(
            name: "Semalot",
            targets: ["Semalot"]),
    ],
    targets: [
        .target(
            name: "Semalot"),
        .testTarget(
            name: "SemalotTests",
            dependencies: ["Semalot"]),
    ]
)

#endif
