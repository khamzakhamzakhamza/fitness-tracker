import Foundation

struct HeightMeasurementUnit {
    static let tableName = "HeightMeasurementUnits"

    let id: Int
    let name: String
    let shortName: String
    let siConversionValue: Double
    let isDefault: Bool
    let dateAdded: Date = .now
}
