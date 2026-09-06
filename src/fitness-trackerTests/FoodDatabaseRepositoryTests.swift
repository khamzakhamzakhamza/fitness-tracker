import Foundation
import Testing
@testable import fitness_tracker

struct FoodDatabaseRepositoryTests {
    @Test func readsFirstPageAndExactTotalFromBundledDatabase() async throws {
        let repository = FoodDatabaseRepository()

        let page = try await repository.searchFoods(
            query: "",
            limit: 100,
            offset: 0
        )

        #expect(page.totalMatches == 85_909)
        #expect(page.foods.count == 100)
        #expect(page.foods.first == StoredFood(
            id: 1,
            name: "Pinto bean",
            brand: "Central bean",
            imageURL: nil,
            quantity: 1,
            measurementUnitShortName: "item"
        ))
        #expect(page.foods.first?.subtitle == "Central bean · 1 item")
    }

    @Test func readsSelectedFoodStatsForItsServingSize() async throws {
        let repository = FoodDatabaseRepository()

        let food = try await repository.foodDetails(id: 22_411)

        #expect(food?.name == "Yorkshire pudding")
        #expect(food?.subtitle == "Aldi · 45 g")
        #expect(food?.sourceName == "Open Food Facts")
        #expect(abs((food?.calories ?? 0) - 131) < 0.001)
        #expect(food?.nutrients.map(\.shortName) == [
            "energy",
            "fat",
            "carbs",
            "protein"
        ])
        #expect(abs(
            (food?.nutrients.first { $0.shortName == "protein" }?.amount ?? 0)
            - 4.2
        ) < 0.001)
        #expect(abs(
            (food?.nutrients.first { $0.shortName == "carbs" }?.amount ?? 0)
            - 15.5
        ) < 0.001)
        #expect(abs(
            (food?.nutrients.first { $0.shortName == "fat" }?.amount ?? 0)
            - 5.7
        ) < 0.001)
    }

    @Test func searchesByPrefixAndPaginatesTheMatchedRows() async throws {
        let repository = FoodDatabaseRepository()

        let firstPage = try await repository.searchFoods(
            query: "yorkshire pudding",
            limit: 2,
            offset: 0
        )
        let secondPage = try await repository.searchFoods(
            query: "yorkshire pudding",
            limit: 2,
            offset: 2
        )

        #expect(firstPage.totalMatches == 55)
        #expect(secondPage.totalMatches == 55)
        #expect(firstPage.foods.count == 2)
        #expect(secondPage.foods.count == 2)
        #expect(firstPage.foods != secondPage.foods)
    }

    @Test func buildsSafePrefixExpressionFromTypedText() {
        #expect(
            FoodDatabaseRepository.ftsExpression(
                for: "  chicken-and rice! "
            ) == "\"chicken\"* \"and\"* \"rice\"*"
        )
        #expect(FoodDatabaseRepository.ftsExpression(for: "---") == nil)
    }

    @Test func readsFinalPartialPageAndStopsAtDatabaseEnd() async throws {
        let repository = FoodDatabaseRepository()

        let finalPage = try await repository.searchFoods(
            query: "",
            limit: 100,
            offset: 85_900
        )
        let afterLastPage = try await repository.searchFoods(
            query: "",
            limit: 100,
            offset: 85_909
        )

        #expect(finalPage.totalMatches == 85_909)
        #expect(finalPage.foods.count == 9)
        #expect(finalPage.foods.first?.name == "Yogurt, virtually fat free/diet, plain")
        #expect(finalPage.foods.last?.name == "Yorkshire pudding, made with whole milk")
        #expect(afterLastPage.foods.isEmpty)
        #expect(afterLastPage.totalMatches == 85_909)
    }
}
