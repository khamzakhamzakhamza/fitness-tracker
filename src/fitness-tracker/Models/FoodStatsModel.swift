import Foundation

struct NutrientModel: Identifiable, Equatable, Sendable {
    var id: String { shortName }

    let name: String
    let shortName: String
    let amount: Double?
    let unit: String
}

struct FoodStatsModel: Equatable, Sendable {
    let calories: Double?
    let nutrients: [NutrientModel]
}

struct AddFoodModel: Equatable, Sendable {
    let id: Int64
    let title: String
    let subtitle: String
    let imageURL: URL?
    let servingSizeGrams: Double
    let totalAmountGrams: Double?
    let sourceName: String
    let stats: FoodStatsModel
}
