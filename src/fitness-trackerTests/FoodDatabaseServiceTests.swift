import Foundation
import Testing
@testable import fitness_tracker

struct FoodDatabaseServiceTests {
    @Test func readsFirstBatchFromBundledSQLiteDatabase() async throws {
        let service = FoodDatabaseService()

        let foods = try await service.fetchFoods(limit: 500, offset: 0)

        #expect(foods.count == 500)
        #expect(foods.first == StoredFood(
            name: "1up",
            brand: "Streawberry shortcake",
            imageURL: URL(
                string: "https://images.openfoodfacts.org/images/products/invalid/front_en.7.200.jpg"
            )
        ))
        #expect(foods.last?.name == "Egg & Spinach")
    }

    @Test func readsRemainingBatchAndStopsAtEndOfDatabase() async throws {
        let service = FoodDatabaseService()

        let secondBatch = try await service.fetchFoods(
            limit: 500,
            offset: 500
        )
        let afterLastBatch = try await service.fetchFoods(
            limit: 500,
            offset: 710
        )

        #expect(secondBatch.count == 210)
        #expect(secondBatch.first?.name == "Iced Tea Spanish Peach")
        #expect(
            secondBatch.last?.name
                == "GOOD HEALTH PLANT VARIETIES HIGH IN PROTEIN WAITRO"
        )
        #expect(afterLastBatch.isEmpty)
    }
}
