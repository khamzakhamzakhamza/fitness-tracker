import Foundation

struct NutritionPlanSpan {
    static let tableName = "NutritionPlanSpans"

    let id: String
    let nutritionPlanID: String
    let startDate: Date
    let endDate: Date
    let targetCaloriesSI: Double
}
