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
        let targets = await dailyNutritionTargets(
            at: date,
            timeZone: timeZone
        )

        return DailyNutritionSummary(
            caloriesConsumed: values.caloriesConsumed,
            calorieGoal: targets.calories,
            nutrients: Constants.trackedNutrients.map { nutrient in
                DailyNutrientProgress(
                    name: nutrient.name,
                    shortName: nutrient.shortName,
                    consumed: values.nutrientsByShortName[
                        nutrient.shortName
                    ] ?? 0,
                    goal: targets.goal(for: nutrient.shortName),
                    unit: Constants.gramsUnit
                )
            }
        )
    }

    private func dailyNutritionTargets(
        at date: Date,
        timeZone: TimeZone
    ) async -> DailyNutritionTargets {
        let cacheDate = formattedDate(date, timeZone: timeZone)
        if let cachedTargets = cachedNutritionTargets(for: cacheDate) {
            return cachedTargets
        }

        var calendar = Calendar.current
        calendar.timeZone = timeZone

        guard let week = calendar.dateInterval(of: .weekOfYear, for: date),
              let inputs = try? await repository.fetchDailyCalorieTargetInputs(
                  milestoneStartDate: week.start,
                  milestoneEndDate: week.end
              ) else {
            return .fallback
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
            let calorieTarget = max(
                maintenanceCalories + dailyCalorieAdjustment,
                0
            ).rounded()
            let weightKilograms = inputs.weightSI / Constants.gramsPerKilogram
            let proteinTarget = weightKilograms
                * Constants.proteinGramsPerKilogram
            let fatTarget = calorieTarget
                * Constants.fatCalorieFraction
                / Constants.fatCaloriesPerGram
            let carbohydrateTarget = max(
                (
                    calorieTarget
                    - proteinTarget * Constants.proteinCaloriesPerGram
                    - fatTarget * Constants.fatCaloriesPerGram
                ) / Constants.carbohydrateCaloriesPerGram,
                0
            )
            let waterTarget = weightKilograms
                * Constants.waterGramsPerKilogram
            let targets = DailyNutritionTargets(
                calories: calorieTarget,
                protein: proteinTarget.rounded(),
                carbohydrates: carbohydrateTarget.rounded(),
                fat: fatTarget.rounded(),
                water: waterTarget.rounded()
            )

            cache(targets, for: cacheDate)
            return targets
        } catch {
            return .fallback
        }
    }

    private func cachedNutritionTargets(
        for date: String
    ) -> DailyNutritionTargets? {
        guard cache.string(forKey: Constants.targetCacheDateKey) == date else {
            return nil
        }

        let targets = DailyNutritionTargets(
            calories: cache.double(forKey: Constants.calorieTargetCacheKey),
            protein: cache.double(forKey: Constants.proteinTargetCacheKey),
            carbohydrates: cache.double(forKey: Constants.carbohydrateTargetCacheKey),
            fat: cache.double(forKey: Constants.fatTargetCacheKey),
            water: cache.double(forKey: Constants.waterTargetCacheKey)
        )
        return targets.calories > 0 ? targets : nil
    }

    private func cache(
        _ targets: DailyNutritionTargets,
        for date: String
    ) {
        cache.set(date, forKey: Constants.targetCacheDateKey)
        cache.set(targets.calories, forKey: Constants.calorieTargetCacheKey)
        cache.set(targets.protein, forKey: Constants.proteinTargetCacheKey)
        cache.set(
            targets.carbohydrates,
            forKey: Constants.carbohydrateTargetCacheKey
        )
        cache.set(targets.fat, forKey: Constants.fatTargetCacheKey)
        cache.set(targets.water, forKey: Constants.waterTargetCacheKey)
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

private struct DailyNutritionTargets {
    let calories: Double
    let protein: Double
    let carbohydrates: Double
    let fat: Double
    let water: Double

    func goal(for nutrient: String) -> Double {
        switch nutrient {
        case "protein": protein
        case "carbs": carbohydrates
        case "fat": fat
        case "water": water
        default: 0
        }
    }

    static let fallback = DailyNutritionTargets(
        calories: 3_000,
        protein: 150,
        carbohydrates: 425,
        fat: 78,
        water: 2_500
    )
}

private enum Constants {
    static let gramsUnit = "g"
    static let gramsPerKilogram = 1_000.0
    static let caloriesPerKilogram = 7_700.0
    static let proteinGramsPerKilogram = 1.6
    static let waterGramsPerKilogram = 35.0
    static let fatCalorieFraction = 0.25
    static let proteinCaloriesPerGram = 4.0
    static let carbohydrateCaloriesPerGram = 4.0
    static let fatCaloriesPerGram = 9.0
    static let targetCacheDateKey = "nutrition.targets.date"
    static let calorieTargetCacheKey = "nutrition.targets.calories"
    static let proteinTargetCacheKey = "nutrition.targets.protein"
    static let carbohydrateTargetCacheKey = "nutrition.targets.carbohydrates"
    static let fatTargetCacheKey = "nutrition.targets.fat"
    static let waterTargetCacheKey = "nutrition.targets.water"
    static let trackedNutrients = [
        (name: "Protein", shortName: "protein"),
        (name: "Carbs", shortName: "carbs"),
        (name: "Fat", shortName: "fat"),
        (name: "Water", shortName: "water")
    ]
}
