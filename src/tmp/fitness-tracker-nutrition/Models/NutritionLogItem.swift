import Foundation

struct NutritionLogItem: Identifiable, Equatable, Sendable {
    let id: Int64
    let foodID: String
    let date: String
    let time: String
}
