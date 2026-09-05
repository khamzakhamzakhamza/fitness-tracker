import SwiftUI

struct FoodListItem: View {
    let item: FoodListItemModel
    let isInternetAvailable: Bool

    var body: some View {
        HStack(spacing: 15) {
            FoodItemImage(
                imageURL: item.imageURL,
                isInternetAvailable: isInternetAvailable
            )

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

            VStack(alignment: .trailing, spacing: 2) {
                Text(item.amount)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Color("SearchBoxSecondary"))

                Text(item.macrosBreakdown)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color("SearchBoxSecondary"))
            }
            .fixedSize(horizontal: true, vertical: false)
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
            title: "Chicken & rice bowl",
            subtitle: "Your foods · logged 6 times",
            amount: "586 kcal",
            macrosBreakdown: "P 55 · C 42 · F 22 g",
            imageURL: URL(string: "https://picsum.photos/seed/chicken-rice/100")
        ),
        isInternetAvailable: true
    )
    .padding(.horizontal, 20)
    .background(Color("AppBackground"))
}
