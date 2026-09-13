import Foundation

struct LoggedFoodListItemModel: Identifiable, Equatable, Sendable {
    let id: Int64
    let time: String
    let title: String
    let calories: Double
    let nutrientSummary: String
}
