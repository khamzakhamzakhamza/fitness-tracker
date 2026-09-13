import Foundation

struct FoodListItemModel: Identifiable, Sendable {
    let id: String
    let title: String
    let subtitle: String
    let imageURL: URL?
    let isTrusted: Bool

    init(
        id: String,
        title: String,
        subtitle: String,
        imageURL: URL? = nil,
        isTrusted: Bool = false
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.imageURL = imageURL
        self.isTrusted = isTrusted
    }
}
