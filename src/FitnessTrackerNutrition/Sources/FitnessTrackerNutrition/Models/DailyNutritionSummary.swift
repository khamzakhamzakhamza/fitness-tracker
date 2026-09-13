import Foundation

struct DailyNutrientProgress: Identifiable, Equatable, Sendable {
    var id: String { shortName }

    let name: String
    let shortName: String
    let consumed: Double
    let goal: Double
    let unit: String
}

struct DailyNutritionSummary: Equatable, Sendable {
    let caloriesConsumed: Double
    let calorieGoal: Double
    let nutrients: [DailyNutrientProgress]

    static let empty = DailyNutritionSummary(
        caloriesConsumed: 0,
        calorieGoal: 3_000,
        nutrients: [
            DailyNutrientProgress(
                name: "Protein",
                shortName: "protein",
                consumed: 0,
                goal: 500,
                unit: "g"
            ),
            DailyNutrientProgress(
                name: "Carbs",
                shortName: "carbs",
                consumed: 0,
                goal: 500,
                unit: "g"
            ),
            DailyNutrientProgress(
                name: "Fat",
                shortName: "fat",
                consumed: 0,
                goal: 500,
                unit: "g"
            ),
            DailyNutrientProgress(
                name: "Water",
                shortName: "water",
                consumed: 0,
                goal: 500,
                unit: "g"
            )
        ]
    )
}

struct DailyNutritionDashboard: Equatable, Sendable {
    let summary: DailyNutritionSummary
    let loggedFoods: [LoggedFoodListItemModel]
}
