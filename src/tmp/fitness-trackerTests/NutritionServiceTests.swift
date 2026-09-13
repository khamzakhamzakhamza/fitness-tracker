import Foundation
import Testing
@testable import FitnessTrackerNutrition

private actor StubFoodDatabaseRepository: FoodDatabaseRepositoryProtocol {
    let page: FoodDatabasePage
    let details: StoredFoodDetails?
    let detailsByID: [String: StoredFoodDetails]
    private var queryCount = 0

    init(
        page: FoodDatabasePage,
        details: StoredFoodDetails? = nil,
        detailsByID: [String: StoredFoodDetails] = [:]
    ) {
        self.page = page
        self.details = details
        self.detailsByID = detailsByID
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

    func foodDetails(id: String) -> StoredFoodDetails? {
        detailsByID[id] ?? details
    }
}

private actor StubLocalDatabaseRepository: LocalDatabaseRepositoryProtocol {
    private var isInitialized = false
    private var logs: [NutritionLogItem] = []

    func initializeDatabase() {
        isInitialized = true
    }

    func addNutritionLog(
        foodID: String,
        date: String,
        time: String
    ) -> NutritionLogItem {
        let log = NutritionLogItem(
            id: Int64(logs.count + 1),
            foodID: foodID,
            date: date,
            time: time
        )
        logs.append(log)
        return log
    }

    func nutritionLogs(date: String) -> [NutritionLogItem] {
        logs.filter { $0.date == date }
    }

    func deleteNutritionLog(id: Int64) {
        logs.removeAll { $0.id == id }
    }

    func initialized() -> Bool {
        isInitialized
    }
}

struct NutritionServiceTests {
    @Test func initializesDatabaseAndAddsTimestampedLog() async throws {
        let foodRepository = StubFoodDatabaseRepository(
            page: FoodDatabasePage(foods: [], totalMatches: 0)
        )
        let localRepository = StubLocalDatabaseRepository()
        let service = NutritionService(
            foodRepository: foodRepository,
            localDatabaseRepository: localRepository
        )

        try await service.initializeLocalDatabase()
        let log = try await service.addNutritionLog(
            foodID: "food-42",
            at: Date(timeIntervalSince1970: 0),
            timeZone: TimeZone(secondsFromGMT: 0)!
        )

        #expect(await localRepository.initialized())
        #expect(log == NutritionLogItem(
            id: 1,
            foodID: "food-42",
            date: "1970-01-01",
            time: "00:00:00"
        ))
    }

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

    @Test func totalsTodaysLoggedFoodAgainstHardcodedGoals() async throws {
        let apple = StoredFoodDetails(
            id: "food-7",
            name: "Apple",
            brand: nil,
            imageURL: nil,
            quantity: 100,
            measurementUnitShortName: "g",
            servingSizeGrams: 100,
            totalAmountGrams: 100,
            calories: 52,
            sourceName: "Test source",
            nutrients: [
                StoredNutrient(
                    name: "Protein",
                    shortName: "protein",
                    amount: 0.3,
                    unit: "g"
                ),
                StoredNutrient(
                    name: "Carbohydrates",
                    shortName: "carbs",
                    amount: 14,
                    unit: "g"
                ),
                StoredNutrient(
                    name: "Fat",
                    shortName: "fat",
                    amount: 0.2,
                    unit: "g"
                )
            ],
            isTrusted: false
        )
        let foodRepository = StubFoodDatabaseRepository(
            page: FoodDatabasePage(foods: [], totalMatches: 0),
            detailsByID: ["food-7": apple]
        )
        let localRepository = StubLocalDatabaseRepository()
        _ = try await localRepository.addNutritionLog(
            foodID: "food-7",
            date: "2026-09-07",
            time: "08:00:00"
        )
        _ = try await localRepository.addNutritionLog(
            foodID: "food-7",
            date: "2026-09-07",
            time: "09:00:00"
        )
        let service = NutritionService(
            foodRepository: foodRepository,
            localDatabaseRepository: localRepository
        )
        let timeZone = TimeZone(secondsFromGMT: 0)!
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let timestamp = try #require(
            calendar.date(
                from: DateComponents(
                    year: 2026,
                    month: 9,
                    day: 7
                )
            )
        )

        let dashboard = try await service.dailyNutritionDashboard(
            at: timestamp,
            timeZone: timeZone
        )
        let summary = dashboard.summary

        #expect(summary.calorieGoal == 3_000)
        #expect(summary.caloriesConsumed == 104)
        #expect(summary.nutrients.map(\.goal) == [500, 500, 500, 500])
        #expect(summary.nutrients.map(\.consumed) == [0.6, 28, 0.4, 0])
        #expect(dashboard.loggedFoods.count == 2)
        #expect(dashboard.loggedFoods.first == LoggedFoodListItemModel(
            id: 1,
            time: "08:00",
            title: "Apple",
            calories: 52,
            nutrientSummary: "P 0.3 · C 14 · F 0.2 g"
        ))

        try await service.deleteNutritionLog(id: 1)
        let remainingDashboard = try await service.dailyNutritionDashboard(
            at: timestamp,
            timeZone: timeZone
        )
        #expect(remainingDashboard.loggedFoods.map(\.id) == [2])
        #expect(remainingDashboard.summary.caloriesConsumed == 52)
    }

    @Test func mapsRepositoryPageToListItemsAndPreservesTotal() async throws {
        let repository = StubFoodDatabaseRepository(
            page: FoodDatabasePage(
                foods: [
                    StoredFood(
                        id: "food-7",
                        name: "Apple",
                        brand: "Test brand",
                        imageURL: URL(string: "https://example.com/apple.jpg"),
                        quantity: 100,
                        measurementUnitShortName: "g",
                        isTrusted: true
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
        #expect(page.items.first?.id == "food-7")
        #expect(page.items.first?.title == "Apple")
        #expect(page.items.first?.subtitle == "Test brand · 100 g")
        #expect(page.items.first?.isTrusted == true)
        #expect(
            page.items.first?.imageURL
                == URL(string: "https://example.com/apple.jpg")
        )
    }

    @Test func mapsSelectedFoodDetailsAndStats() async throws {
        let repository = StubFoodDatabaseRepository(
            page: FoodDatabasePage(foods: [], totalMatches: 0),
            details: StoredFoodDetails(
                id: "food-7",
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
                ],
                isTrusted: true
            )
        )
        let service = NutritionService(foodRepository: repository)

        let food = try await service.foodDetails(id: "food-7")

        #expect(food == AddFoodModel(
            id: "food-7",
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
            ),
            isTrusted: true
        ))
    }
}
