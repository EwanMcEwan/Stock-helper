// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "StockHelper",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "StockHelper", targets: ["StockHelper"]),
    ],
    targets: [
        .target(
            name: "StockHelper",
            path: "StockHelper",
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "StockHelperTests",
            dependencies: ["StockHelper"],
            path: "StockHelperTests"
        ),
    ]
)
