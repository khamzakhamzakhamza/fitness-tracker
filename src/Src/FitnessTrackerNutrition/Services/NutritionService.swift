import Foundation

@MainActor
final class NutritionService {
    static let shared = NutritionService()

    private let repository: any NutritionRepositoryProtocol

    init(
        repository: any NutritionRepositoryProtocol = NutritionRepository()
    ) {
        self.repository = repository
    }

    func fetchDailyNutritionSummary(
        at date: Date = .now,
        timeZone: TimeZone = .current
    ) async throws -> DailyNutritionSummary {
        let values = try await repository.fetchDailyNutrition(
            date: formattedDate(date, timeZone: timeZone)
        )

        return DailyNutritionSummary(
            caloriesConsumed: values.caloriesConsumed,
            calorieGoal: Constants.calorieGoal,
            nutrients: Constants.trackedNutrients.map { nutrient in
                DailyNutrientProgress(
                    name: nutrient.name,
                    shortName: nutrient.shortName,
                    consumed: values.nutrientsByShortName[
                        nutrient.shortName
                    ] ?? 0,
                    goal: Constants.nutrientGoal,
                    unit: Constants.gramsUnit
                )
            }
        )
    }

    private func formattedDate(
        _ date: Date,
        timeZone: TimeZone
    ) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = timeZone
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}

private enum Constants {
    static let calorieGoal = 3_000.0
    static let nutrientGoal = 500.0
    static let gramsUnit = "g"
    static let trackedNutrients = [
        (name: "Protein", shortName: "protein"),
        (name: "Carbs", shortName: "carbs"),
        (name: "Fat", shortName: "fat"),
        (name: "Water", shortName: "water")
    ]
}
