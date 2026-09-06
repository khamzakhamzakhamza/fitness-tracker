import Foundation
import Testing
@testable import fitness_tracker

private actor StubFoodDatabaseRepository: FoodDatabaseRepositoryProtocol {
    let page: FoodDatabasePage
    let details: StoredFoodDetails?
    private var queryCount = 0

    init(
        page: FoodDatabasePage,
        details: StoredFoodDetails? = nil
    ) {
        self.page = page
        self.details = details
    }

    func searchFoods(
        query: String,
        limit: Int,
        offset: Int
    ) -> FoodDatabasePage {
        queryCount += 1
        return page
    }

    func receivedQueryCount() -> Int {
        queryCount
    }

    func foodDetails(id: Int64) -> StoredFoodDetails? {
        details
    }
}

struct NutritionServiceTests {
    @Test func skipsOnlyEmptySearchAndSearchesFromFirstCharacter() async throws {
        let repository = StubFoodDatabaseRepository(
            page: FoodDatabasePage(foods: [], totalMatches: 42)
        )
        let service = NutritionService(foodRepository: repository)

        let emptyPage = try await service.searchFoods(
            query: "",
            limit: 500,
            offset: 0
        )
        let firstCharacterPage = try await service.searchFoods(
            query: "a",
            limit: 500,
            offset: 0
        )
        let queryCount = await repository.receivedQueryCount()

        #expect(emptyPage.items.isEmpty)
        #expect(emptyPage.totalMatches == 0)
        #expect(firstCharacterPage.items.isEmpty)
        #expect(firstCharacterPage.totalMatches == 42)
        #expect(queryCount == 1)
    }

    @Test func mapsRepositoryPageToListItemsAndPreservesTotal() async throws {
        let repository = StubFoodDatabaseRepository(
            page: FoodDatabasePage(
                foods: [
                    StoredFood(
                        id: 7,
                        name: "Apple",
                        brand: "Test brand",
                        imageURL: URL(string: "https://example.com/apple.jpg"),
                        quantity: 100,
                        measurementUnitShortName: "g"
                    )
                ],
                totalMatches: 42
            )
        )
        let service = NutritionService(foodRepository: repository)

        let page = try await service.searchFoods(
            query: "app",
            limit: 1,
            offset: 0
        )

        #expect(page.totalMatches == 42)
        #expect(page.items.count == 1)
        #expect(page.items.first?.id == 7)
        #expect(page.items.first?.title == "Apple")
        #expect(page.items.first?.subtitle == "Test brand · 100 g")
        #expect(
            page.items.first?.imageURL
                == URL(string: "https://example.com/apple.jpg")
        )
    }

    @Test func mapsSelectedFoodDetailsAndStats() async throws {
        let repository = StubFoodDatabaseRepository(
            page: FoodDatabasePage(foods: [], totalMatches: 0),
            details: StoredFoodDetails(
                id: 7,
                name: "Apple",
                brand: "Test brand",
                imageURL: URL(string: "https://example.com/apple.jpg"),
                quantity: 100,
                measurementUnitShortName: "g",
                servingSizeGrams: 100,
                totalAmountGrams: 200,
                calories: 52,
                sourceName: "Test source",
                nutrients: [
                    StoredNutrient(
                        name: "Energy",
                        shortName: "energy",
                        amount: 52,
                        unit: "kcal"
                    ),
                    StoredNutrient(
                        name: "Fat",
                        shortName: "fat",
                        amount: 0.2,
                        unit: "g"
                    ),
                    StoredNutrient(
                        name: "Carbohydrates",
                        shortName: "carbs",
                        amount: 14,
                        unit: "g"
                    ),
                    StoredNutrient(
                        name: "Protein",
                        shortName: "protein",
                        amount: 0.3,
                        unit: "g"
                    )
                ]
            )
        )
        let service = NutritionService(foodRepository: repository)

        let food = try await service.foodDetails(id: 7)

        #expect(food == AddFoodModel(
            id: 7,
            title: "Apple",
            subtitle: "Test brand · 100 g",
            imageURL: URL(string: "https://example.com/apple.jpg"),
            servingSizeGrams: 100,
            totalAmountGrams: 200,
            sourceName: "Test source",
            stats: FoodStatsModel(
                calories: 52,
                nutrients: [
                    NutrientModel(
                        name: "Fat",
                        shortName: "fat",
                        amount: 0.2,
                        unit: "g"
                    ),
                    NutrientModel(
                        name: "Carbohydrates",
                        shortName: "carbs",
                        amount: 14,
                        unit: "g"
                    ),
                    NutrientModel(
                        name: "Protein",
                        shortName: "protein",
                        amount: 0.3,
                        unit: "g"
                    )
                ]
            )
        ))
    }
}
