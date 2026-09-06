// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "DalsheLiveMac",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "DalsheLiveMac", targets: ["DalsheLiveMac"])
    ],
    targets: [
        .executableTarget(name: "DalsheLiveMac")
    ]
)
