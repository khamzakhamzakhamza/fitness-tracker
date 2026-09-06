import SwiftUI

struct FoodListItem: View {
    let item: FoodListItemModel
    let isInternetAvailable: Bool

    init(
        item: FoodListItemModel,
        isInternetAvailable: Bool
    ) {
        self.item = item
        self.isInternetAvailable = isInternetAvailable
    }

    var body: some View {
        HStack(spacing: 15) {
            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Text(item.subtitle)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color("SearchBoxSecondary"))
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            if FoodItemImage.shouldLoadImage(
                imageURL: item.imageURL,
                isInternetAvailable: isInternetAvailable
            ) {
                FoodItemImage(
                    imageURL: item.imageURL,
                    isInternetAvailable: isInternetAvailable
                )
            }
        }
        .padding(.vertical, 12)
        .padding(.trailing, 12)
        .frame(maxWidth: .infinity)
        .background(Color("AppBackground"))
    }
}

#Preview {
    FoodListItem(
        item: FoodListItemModel(
            id: 1,
            title: "Chicken & rice bowl",
            subtitle: "Your foods · logged 6 times",
            imageURL: URL(string: "https://picsum.photos/seed/chicken-rice/100")
        ),
        isInternetAvailable: true
    )
    .padding(.horizontal, 20)
    .background(Color("AppBackground"))
}
