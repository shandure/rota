// swift-tools-version: 5.10
// This manifest exists so RotaCore's engine can be compiled and unit-tested
// with plain `swift test` (Linux/CI, or in Docker from Windows) without Xcode.
// The shipping Xcode project is generated from project.yml with XcodeGen.
// SwiftData/SwiftUI-dependent files are guarded with `#if canImport(SwiftData)`.
import PackageDescription

let package = Package(
    name: "RotaCore",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "RotaCore", targets: ["RotaCore"]),
    ],
    targets: [
        .target(name: "RotaCore", path: "RotaCore"),
        .testTarget(name: "RotaCoreTests", dependencies: ["RotaCore"], path: "RotaTests/EngineTests"),
    ]
)
