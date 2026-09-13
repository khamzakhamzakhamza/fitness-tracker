// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "FitnessTrackerPlanning",
    platforms: [.iOS(.v18)],
    products: [.library(name: "FitnessTrackerPlanning", targets: ["FitnessTrackerPlanning"])],
    targets: [.target(name: "FitnessTrackerPlanning")]
)
