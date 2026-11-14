// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "CalloutCore",
    platforms: [.iOS(.v26), .macOS(.v15)],
    products: [.library(name: "CalloutCore", targets: ["CalloutCore"])],
    targets: [
        .target(name: "CalloutCore"),
        .testTarget(name: "CalloutCoreTests", dependencies: ["CalloutCore"]),
    ]
)
