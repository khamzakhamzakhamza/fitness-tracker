import Foundation

struct FoodListItemModel: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let amount: String
    let macrosBreakdown: String
    let imageURL: URL?

    init(
        title: String,
        subtitle: String,
        amount: String,
        macrosBreakdown: String,
        imageURL: URL? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.amount = amount
        self.macrosBreakdown = macrosBreakdown
        self.imageURL = imageURL
    }
}
