import Foundation

struct MeasurementUnit {
    static let tableName = "MeasurementUnits"

    let id: Int
    let name: String
    let shortName: String
    let pluralForm: String?
    let siConversionValue: Double?
    let dateAdded: Date = .now
}
