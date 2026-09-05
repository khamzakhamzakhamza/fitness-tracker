import Foundation

struct FoodListItemModel: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let amount: String
    let macrosBreakdown: String
}
