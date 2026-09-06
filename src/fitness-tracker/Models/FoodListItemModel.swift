import Foundation

struct FoodListItemModel: Identifiable, Sendable {
    let id: Int64
    let title: String
    let subtitle: String
    let imageURL: URL?

    init(
        id: Int64,
        title: String,
        subtitle: String,
        imageURL: URL? = nil
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.imageURL = imageURL
    }
}
