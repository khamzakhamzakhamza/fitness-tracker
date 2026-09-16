import Foundation

public final class CalorieCalculationService {
    public static let shared = CalorieCalculationService()

    public init() {}

    public func calculateRestingCalories(
        weightKilograms: Double,
        heightCentimetres: Double,
        birthday: Date,
        leanMassPercentage: Double,
        referenceDate: Date = .now
    ) throws -> Double {
        guard let age = Calendar.current.dateComponents(
            [.year],
            from: birthday,
            to: referenceDate
        ).year else { throw CalorieCalculationError.invalidInput }
        
        return Constants.weightCoefficient * weightKilograms
            + Constants.heightCoefficient * heightCentimetres
            - Constants.ageCoefficient * Double(age)
            + leanMassAdjustment(for: leanMassPercentage)
    }

    public func calculateFullDailyCalories(
        restingCalories: Double,
        activityMultiplier: Double
    ) throws -> Double {
        guard restingCalories > 0, activityMultiplier > 0 else {
            throw CalorieCalculationError.invalidInput
        }

        return restingCalories * activityMultiplier
    }

    private func leanMassAdjustment(for leanMassPercentage: Double) -> Double {
        Constants.averageMaleAdjustment
            + (leanMassPercentage - Constants.averageMaleLeanMass)
            * (Constants.averageMaleAdjustment - Constants.averageFemaleAdjustment)
            / (Constants.averageMaleLeanMass - Constants.averageFemaleLeanMass)
    }
}

public enum CalorieCalculationError: Error {
    case invalidInput
}

private enum Constants {
    static let weightCoefficient = 10.0
    static let heightCoefficient = 6.25
    static let ageCoefficient = 5.0
    static let averageMaleLeanMass = 79.0
    static let averageFemaleLeanMass = 69.0
    static let averageMaleAdjustment = 5.0
    static let averageFemaleAdjustment = -161.0
}
