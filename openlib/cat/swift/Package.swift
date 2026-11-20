// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Cat",
    products: [.library(name: "Cat", targets: ["Cat"])],
    targets: [.target(name: "Cat", path: "Sources/Cat")]
)
