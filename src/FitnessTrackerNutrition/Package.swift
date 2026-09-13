// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "FitnessTrackerNutrition",
    platforms: [.iOS(.v18)],
    products: [.library(name: "FitnessTrackerNutrition", targets: ["FitnessTrackerNutrition"])],
    dependencies: [.package(path: "../FitnessTrackerShared")],
    targets: [.target(name: "FitnessTrackerNutrition", dependencies: ["FitnessTrackerShared"])]
)
