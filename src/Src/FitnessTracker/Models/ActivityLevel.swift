import Foundation

struct ActivityLevel {
    static let tableName = "ActivityLevels"

    let id: Int
    let name: String
    let calorieMultiplier: Double
    let description: String
    let dateAdded: Date = .now
}
