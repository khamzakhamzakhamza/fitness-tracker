import Foundation

struct NutritionSearchPage: Sendable {
    let items: [FoodListItemModel]
    let totalMatches: Int
}

actor NutritionService {
    private let foodRepository: any FoodDatabaseRepositoryProtocol

    init(
        foodRepository: any FoodDatabaseRepositoryProtocol = FoodDatabaseRepository()
    ) {
        self.foodRepository = foodRepository
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
                imageURL: food.imageURL
            )
        }

        return NutritionSearchPage(
            items: items,
            totalMatches: databasePage.totalMatches
        )
    }

    func foodDetails(id: Int64) async throws -> AddFoodModel? {
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
            )
        )
    }
}
