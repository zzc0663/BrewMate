// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "BrewMate",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "BrewMate", targets: ["BrewMate"]),
    ],
    targets: [
        // MARK: - BrewKit (Domain Layer)
        .target(
            name: "BrewKit",
            path: "Modules/BrewKit/Sources/BrewKit"
        ),

        // MARK: - BrewShell (Infrastructure Layer)
        .target(
            name: "BrewShell",
            dependencies: ["BrewKit"],
            path: "Modules/BrewShell/Sources/BrewShell"
        ),

        // MARK: - BrewMate (UI Layer)
        .executableTarget(
            name: "BrewMate",
            dependencies: ["BrewKit", "BrewShell"],
            path: "Modules/BrewMate/Sources/BrewMate"
        ),
    ]
)
