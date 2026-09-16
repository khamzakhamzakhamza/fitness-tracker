import Foundation

public final class BMIWeightCalculationService {
    public static let shared = BMIWeightCalculationService()

    public init() {}

    public func calculateWeightSI(
        targetBMI: Double,
        heightSI: Double
    ) throws -> Double {
        guard targetBMI > 0, heightSI > 0 else {
            throw BMIWeightCalculationError.invalidInput
        }

        let heightMetres = heightSI / Constants.centimetresPerMetre
        let weightKilograms = targetBMI * heightMetres * heightMetres
        return weightKilograms * Constants.gramsPerKilogram
    }
}

public enum BMIWeightCalculationError: Error {
    case invalidInput
}

private enum Constants {
    static let centimetresPerMetre = 100.0
    static let gramsPerKilogram = 1_000.0
}
