import Foundation

struct NutritionSearchPage: Sendable {
    let items: [FoodListItemModel]
    let totalMatches: Int
}

actor NutritionService {
    private static let calorieGoal = 3_000.0
    private static let nutrientGoal = 500.0
    private static let trackedNutrients = [
        (name: "Protein", shortName: "protein"),
        (name: "Carbs", shortName: "carbs"),
        (name: "Fat", shortName: "fat"),
        (name: "Water", shortName: "water")
    ]

    private let foodRepository: any FoodDatabaseRepositoryProtocol
    private let localDatabaseRepository: any LocalDatabaseRepositoryProtocol

    init(
        foodRepository: any FoodDatabaseRepositoryProtocol = FoodDatabaseRepository(),
        localDatabaseRepository: any LocalDatabaseRepositoryProtocol
            = LocalDatabaseRepository()
    ) {
        self.foodRepository = foodRepository
        self.localDatabaseRepository = localDatabaseRepository
    }

    func initializeLocalDatabase() async throws {
        try await localDatabaseRepository.initializeDatabase()
    }

    func addNutritionLog(
        foodID: String,
        at timestamp: Date = Date(),
        timeZone: TimeZone = .current
    ) async throws -> NutritionLogItem {
        let dateFormatter = DateFormatter()
        dateFormatter.calendar = Calendar(identifier: .gregorian)
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = timeZone
        dateFormatter.dateFormat = "yyyy-MM-dd"

        let timeFormatter = DateFormatter()
        timeFormatter.calendar = Calendar(identifier: .gregorian)
        timeFormatter.locale = Locale(identifier: "en_US_POSIX")
        timeFormatter.timeZone = timeZone
        timeFormatter.dateFormat = "HH:mm:ss"

        return try await localDatabaseRepository.addNutritionLog(
            foodID: foodID,
            date: dateFormatter.string(from: timestamp),
            time: timeFormatter.string(from: timestamp)
        )
    }

    func dailyNutritionSummary(
        at timestamp: Date = Date(),
        timeZone: TimeZone = .current
    ) async throws -> DailyNutritionSummary {
        try await dailyNutritionDashboard(
            at: timestamp,
            timeZone: timeZone
        ).summary
    }

    func dailyNutritionDashboard(
        at timestamp: Date = Date(),
        timeZone: TimeZone = .current
    ) async throws -> DailyNutritionDashboard {
        let date = formattedDate(timestamp, timeZone: timeZone)
        let logs = try await localDatabaseRepository.nutritionLogs(
            date: date
        )
        var caloriesConsumed = 0.0
        var consumedByNutrient: [String: Double] = [:]
        var loggedFoods: [LoggedFoodListItemModel] = []

        for log in logs {
            try Task.checkCancellation()
            guard let food = try await foodRepository.foodDetails(
                id: log.foodID
            ) else {
                continue
            }

            let energy = food.nutrients.first { nutrient in
                nutrient.shortName == "energy"
            }
            let calories = food.calories ?? energy?.amount ?? 0
            caloriesConsumed += calories

            for nutrient in food.nutrients {
                guard Self.trackedNutrients.contains(where: {
                    $0.shortName == nutrient.shortName
                }) else {
                    continue
                }
                consumedByNutrient[nutrient.shortName, default: 0]
                    += nutrient.amount
            }

            loggedFoods.append(
                LoggedFoodListItemModel(
                    id: log.id,
                    time: displayTime(log.time),
                    title: food.name,
                    calories: calories,
                    nutrientSummary: nutrientSummary(for: food)
                )
            )
        }

        return DailyNutritionDashboard(
            summary: DailyNutritionSummary(
                caloriesConsumed: caloriesConsumed,
                calorieGoal: Self.calorieGoal,
                nutrients: Self.trackedNutrients.map { nutrient in
                    DailyNutrientProgress(
                        name: nutrient.name,
                        shortName: nutrient.shortName,
                        consumed: consumedByNutrient[
                            nutrient.shortName
                        ] ?? 0,
                        goal: Self.nutrientGoal,
                        unit: "g"
                    )
                }
            ),
            loggedFoods: loggedFoods
        )
    }

    func deleteNutritionLog(id: Int64) async throws {
        try await localDatabaseRepository.deleteNutritionLog(id: id)
    }

    func searchFoods(
        query: String,
        limit: Int,
        offset: Int
    ) async throws -> NutritionSearchPage {
        let trimmedQuery = query.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        if trimmedQuery.isEmpty {
            return NutritionSearchPage(items: [], totalMatches: 0)
        }

        let databasePage = try await foodRepository.searchFoods(
            query: trimmedQuery,
            limit: limit,
            offset: offset
        )
        try Task.checkCancellation()

        let items = databasePage.foods.map { food in
            FoodListItemModel(
                id: food.id,
                title: food.name,
                subtitle: food.subtitle,
                imageURL: food.imageURL,
                isTrusted: food.isTrusted
            )
        }

        return NutritionSearchPage(
            items: items,
            totalMatches: databasePage.totalMatches
        )
    }

    func foodDetails(id: String) async throws -> AddFoodModel? {
        guard let food = try await foodRepository.foodDetails(id: id) else {
            return nil
        }

        let energy = food.nutrients.first { nutrient in
            nutrient.shortName == "energy"
        }
        let nutrients = food.nutrients
            .filter { nutrient in
                nutrient.shortName != "energy"
            }
            .map { nutrient in
                NutrientModel(
                    name: nutrient.name,
                    shortName: nutrient.shortName,
                    amount: nutrient.amount,
                    unit: nutrient.unit
                )
            }

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
                nutrients: nutrients
            ),
            isTrusted: food.isTrusted
        )
    }

    private func formattedDate(
        _ timestamp: Date,
        timeZone: TimeZone
    ) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = timeZone
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: timestamp)
    }

    private func displayTime(_ storedTime: String) -> String {
        storedTime.split(separator: ":").prefix(2).joined(separator: ":")
    }

    private func nutrientSummary(for food: StoredFoodDetails) -> String {
        let macroLabels = [
            (shortName: "protein", label: "P"),
            (shortName: "carbs", label: "C"),
            (shortName: "fat", label: "F")
        ]
        let macros = macroLabels.compactMap { macro -> String? in
            guard let nutrient = food.nutrients.first(where: {
                $0.shortName == macro.shortName
            }) else {
                return nil
            }
            return "\(macro.label) \(formattedAmount(nutrient.amount))"
        }

        if !macros.isEmpty {
            return "\(macros.joined(separator: " · ")) g"
        }

        guard let water = food.nutrients.first(where: {
            $0.shortName == "water"
        }) else {
            return ""
        }
        return "W \(formattedAmount(water.amount)) \(water.unit)"
    }

    private func formattedAmount(_ value: Double) -> String {
        value.formatted(
            .number.precision(.fractionLength(0...1))
        )
    }
}
