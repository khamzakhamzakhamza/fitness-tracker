// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "FitnessTrackerShared",
    platforms: [.iOS(.v18)],
    products: [.library(name: "FitnessTrackerShared", targets: ["FitnessTrackerShared"])],
    targets: [.target(name: "FitnessTrackerShared")]
)
