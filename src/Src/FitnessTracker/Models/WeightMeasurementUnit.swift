import Foundation

struct WeightMeasurementUnit {
    static let tableName = "WeightMeasurementUnits"

    let id: Int
    let name: String
    let shortName: String
    let siConversionValue: Double
    let isDefault: Bool
    let dateAdded: Date = .now
}
