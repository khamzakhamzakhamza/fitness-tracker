import Foundation

struct NutritionSearchPage: Sendable {
    let items: [FoodListItemModel]
    let totalMatches: Int
}

@MainActor
final class NutritionService {
    static let shared = NutritionService()

    private let repository: any NutritionRepositoryProtocol
    private let foodRepository: any FoodDatabaseRepositoryProtocol
    private let calorieCalculationService: CalorieCalculationService
    private let cache: UserDefaults

    init(
        repository: any NutritionRepositoryProtocol = NutritionRepository(),
        foodRepository: any FoodDatabaseRepositoryProtocol = FoodDatabaseRepository(),
        calorieCalculationService: CalorieCalculationService = CalorieCalculationService(),
        cache: UserDefaults = .standard
    ) {
        self.repository = repository
        self.foodRepository = foodRepository
        self.calorieCalculationService = calorieCalculationService
        self.cache = cache
    }

    func addNutritionLog(
        foodID: String,
        at timestamp: Date = .now,
        timeZone: TimeZone = .current
    ) async throws {
        let timeFormatter = DateFormatter()
        timeFormatter.calendar = Calendar(identifier: .gregorian)
        timeFormatter.locale = Locale(identifier: "en_US_POSIX")
        timeFormatter.timeZone = timeZone
        timeFormatter.dateFormat = "HH:mm:ss"

        try await repository.addNutritionLog(
            foodID: foodID,
            date: formattedDate(timestamp, timeZone: timeZone),
            time: timeFormatter.string(from: timestamp)
        )
    }

    func searchFoods(
        query: String,
        limit: Int,
        offset: Int
    ) async throws -> NutritionSearchPage {
        let trimmedQuery = query.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        guard !trimmedQuery.isEmpty else {
            return NutritionSearchPage(items: [], totalMatches: 0)
        }

        let page = try await foodRepository.searchFoods(
            query: trimmedQuery,
            limit: limit,
            offset: offset
        )

        return NutritionSearchPage(
            items: page.foods.map { food in
                FoodListItemModel(
                    id: food.id,
                    title: food.name,
                    subtitle: food.subtitle,
                    imageURL: food.imageURL,
                    isTrusted: food.isTrusted
                )
            },
            totalMatches: page.totalMatches
        )
    }

    func foodDetails(id: String) async throws -> AddFoodModel? {
        guard let food = try await foodRepository.foodDetails(id: id) else {
            return nil
        }

        let energy = food.nutrients.first { $0.shortName == "energy" }

        return AddFoodModel(
            id: food.id,
            title: food.name,
            subtitle: food.subtitle,
            imageURL: food.imageURL,
            servingSizeGrams: food.servingSizeGrams,
            totalAmountGrams: food.totalAmountGrams,
            sourceName: food.sourceName,
            stats: FoodStatsModel(
                calories: food.calories ?? energy?.amount,
                nutrients: food.nutrients
                    .filter { $0.shortName != "energy" }
                    .map { nutrient in
                        NutrientModel(
                            name: nutrient.name,
                            shortName: nutrient.shortName,
                            amount: nutrient.amount,
                            unit: nutrient.unit
                        )
                    }
            ),
            isTrusted: food.isTrusted
        )
    }

    func fetchDailyNutritionSummary(
        at date: Date = .now,
        timeZone: TimeZone = .current
    ) async throws -> DailyNutritionSummary {
        let values = try await repository.fetchDailyNutrition(
            date: formattedDate(date, timeZone: timeZone)
        )
        let calorieGoal = await dailyCalorieTarget(
            at: date,
            timeZone: timeZone
        )

        return DailyNutritionSummary(
            caloriesConsumed: values.caloriesConsumed,
            calorieGoal: calorieGoal,
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

    private func dailyCalorieTarget(
        at date: Date,
        timeZone: TimeZone
    ) async -> Double {
        let cacheDate = formattedDate(date, timeZone: timeZone)
        if cache.string(forKey: Constants.calorieTargetCacheDateKey) == cacheDate {
            let cachedTarget = cache.double(
                forKey: Constants.calorieTargetCacheValueKey
            )
            if cachedTarget > 0 {
                return cachedTarget
            }
        }

        var calendar = Calendar.current
        calendar.timeZone = timeZone

        guard let week = calendar.dateInterval(of: .weekOfYear, for: date),
              let inputs = try? await repository.fetchDailyCalorieTargetInputs(
                  milestoneStartDate: week.start,
                  milestoneEndDate: week.end
              ) else {
            return Constants.fallbackCalorieGoal
        }

        do {
            let restingCalories = try calorieCalculationService
                .calculateRestingCalories(
                    weightKilograms: inputs.weightSI / Constants.gramsPerKilogram,
                    heightCentimetres: inputs.heightCentimetres,
                    birthday: inputs.birthday,
                    leanMassPercentage: inputs.leanMassPercentage,
                    referenceDate: date
                )
            let maintenanceCalories = try calorieCalculationService
                .calculateFullDailyCalories(
                    restingCalories: restingCalories,
                    activityMultiplier: inputs.activityMultiplier
                )

            let today = calendar.startOfDay(for: date)
            let milestoneDate = calendar.startOfDay(for: inputs.milestoneDate)
            let remainingDays = max(
                calendar.dateComponents(
                    [.day],
                    from: today,
                    to: milestoneDate
                ).day ?? 0,
                1
            )
            let requiredWeightChangeKilograms = (
                inputs.milestoneTargetWeightSI - inputs.weightSI
            ) / Constants.gramsPerKilogram
            let dailyCalorieAdjustment = requiredWeightChangeKilograms
                * Constants.caloriesPerKilogram
                / Double(remainingDays)
            let target = max(
                maintenanceCalories + dailyCalorieAdjustment,
                0
            ).rounded()

            cache.set(cacheDate, forKey: Constants.calorieTargetCacheDateKey)
            cache.set(target, forKey: Constants.calorieTargetCacheValueKey)
            return target
        } catch {
            return Constants.fallbackCalorieGoal
        }
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
    static let fallbackCalorieGoal = 3_000.0
    static let nutrientGoal = 500.0
    static let gramsUnit = "g"
    static let gramsPerKilogram = 1_000.0
    static let caloriesPerKilogram = 7_700.0
    static let calorieTargetCacheDateKey = "nutrition.calorieTarget.date"
    static let calorieTargetCacheValueKey = "nutrition.calorieTarget.value"
    static let trackedNutrients = [
        (name: "Protein", shortName: "protein"),
        (name: "Carbs", shortName: "carbs"),
        (name: "Fat", shortName: "fat"),
        (name: "Water", shortName: "water")
    ]
}
