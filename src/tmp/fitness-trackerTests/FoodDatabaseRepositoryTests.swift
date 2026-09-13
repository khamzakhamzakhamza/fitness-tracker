import Foundation
import Testing
@testable import FitnessTrackerNutrition

struct FoodDatabaseRepositoryTests {
    @Test func readsFirstPageFromBundledDatabase() async throws {
        let repository = FoodDatabaseRepository()

        let page = try await repository.searchFoods(
            query: "",
            limit: 100,
            offset: 0
        )

        #expect(page.totalMatches > 100)
        #expect(page.foods.count == 100)
        #expect(page.foods.first?.id.isEmpty == false)
        #expect(page.foods.first?.name.isEmpty == false)
    }

    @Test func readsSelectedFoodDetailsByUUID() async throws {
        let repository = FoodDatabaseRepository()
        let page = try await repository.searchFoods(query: "", limit: 1, offset: 0)
        let id = try #require(page.foods.first?.id)
        let food = try await repository.foodDetails(id: id)

        #expect(food?.id == id)
        #expect(food?.name.isEmpty == false)
    }

    @Test func searchesByPrefixAndPaginatesTheMatchedRows() async throws {
        let repository = FoodDatabaseRepository()

        let firstPage = try await repository.searchFoods(
            query: "apple",
            limit: 2,
            offset: 0
        )
        let secondPage = try await repository.searchFoods(
            query: "apple",
            limit: 2,
            offset: 2
        )

        #expect(firstPage.totalMatches >= 2)
        #expect(secondPage.totalMatches == firstPage.totalMatches)
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
        let page = try await repository.searchFoods(
            query: "",
            limit: 1,
            offset: 0
        )

        let finalPage = try await repository.searchFoods(
            query: "",
            limit: 100,
            offset: page.totalMatches - 1
        )
        let afterLastPage = try await repository.searchFoods(
            query: "",
            limit: 100,
            offset: page.totalMatches
        )

        #expect(finalPage.totalMatches == page.totalMatches)
        #expect(finalPage.foods.count == 1)
        #expect(afterLastPage.foods.isEmpty)
        #expect(afterLastPage.totalMatches == page.totalMatches)
    }
}
