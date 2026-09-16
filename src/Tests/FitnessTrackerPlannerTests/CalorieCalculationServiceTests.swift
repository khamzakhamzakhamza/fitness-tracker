import Foundation
import Testing
@testable import FitnessTrackerPlanner

struct CalorieCalculationServiceTests {
    @Test
    func calculatesRestingAndFullDailyCalories() throws {
        let calendar = Calendar(identifier: .gregorian)
        let birthday = try #require(calendar.date(from: DateComponents(year: 1990, month: 1, day: 1)))
        let referenceDate = try #require(calendar.date(from: DateComponents(year: 2026, month: 1, day: 1)))
        let service = CalorieCalculationService()

        let restingCalories = try service.calculateRestingCalories(
            weightKilograms: 82.4,
            heightCentimetres: 180,
            birthday: birthday,
            leanMassPercentage: 79,
            referenceDate: referenceDate
        )
        let fullDailyCalories = try service.calculateFullDailyCalories(
            restingCalories: restingCalories,
            activityMultiplier: 1.725
        )

        #expect(restingCalories == 1_774)
        #expect(abs(fullDailyCalories - 3_060.15) < 0.001)
    }
}
