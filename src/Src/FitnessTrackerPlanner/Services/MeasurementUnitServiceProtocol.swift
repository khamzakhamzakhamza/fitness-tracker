import Foundation

public struct MeasurementUnitOption: Identifiable, Equatable, Hashable {
    public let id: Int
    public let name: String
    public let shortName: String
    public let siConversionValue: Double
    public let isDefault: Bool

    public init(
        id: Int,
        name: String,
        shortName: String,
        siConversionValue: Double,
        isDefault: Bool
    ) {
        self.id = id
        self.name = name
        self.shortName = shortName
        self.siConversionValue = siConversionValue
        self.isDefault = isDefault
    }
}

public protocol MeasurementUnitServiceProtocol {
    func fetchHeightMeasurementUnits() throws -> [MeasurementUnitOption]
    func fetchWeightMeasurementUnits() throws -> [MeasurementUnitOption]
    func setDefaultHeightMeasurementUnit(id: Int) throws
    func setDefaultWeightMeasurementUnit(id: Int) throws
}
