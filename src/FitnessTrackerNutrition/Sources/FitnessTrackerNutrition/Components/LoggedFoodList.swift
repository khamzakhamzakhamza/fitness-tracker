import SwiftUI

struct LoggedFoodList: View {
    let items: [LoggedFoodListItemModel]
    var onRemove: (LoggedFoodListItemModel) -> Void = { _ in }

    var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            LazyVStack(spacing: 0) {
                ForEach(items) { item in
                    loggedFoodRow(item)

                    if item.id != items.last?.id {
                        Divider()
                    }
                }
            }
            .padding(.horizontal, 20)
        }
        .background(Color("AppBackground"))
        .accessibilityIdentifier("logged-food-list")
    }

    private func loggedFoodRow(
        _ item: LoggedFoodListItemModel
    ) -> some View {
        HStack(spacing: 14) {
            Button {
                onRemove(item)
            } label: {
                Image(systemName: "minus")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.primary)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(Color("SearchBoxSecondary").opacity(0.1))
                    )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Remove \(item.title)")

            Text(item.time)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(Color("SearchBoxSecondary"))
                .frame(width: 56, alignment: .leading)

            Text(item.title)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.primary)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(formatted(item.calories)) kcal")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Color("SearchBoxSecondary"))

                if !item.nutrientSummary.isEmpty {
                    Text(item.nutrientSummary)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Color("SearchBoxSecondary"))
                }
            }
            .lineLimit(1)
        }
        .frame(maxWidth: .infinity, minHeight: 80)
        .contentShape(Rectangle())
    }

    private func formatted(_ calories: Double) -> String {
        calories.formatted(
            .number.precision(.fractionLength(0))
        )
    }
}

#Preview {
    LoggedFoodList(
        items: [
            LoggedFoodListItemModel(
                id: 1,
                time: "07:40",
                title: "Porridge & banana",
                calories: 418,
                nutrientSummary: "P 13 · C 69 · F 10 g"
            ),
            LoggedFoodListItemModel(
                id: 2,
                time: "09:00",
                title: "Water bottle",
                calories: 0,
                nutrientSummary: "W 750 ml"
            ),
            LoggedFoodListItemModel(
                id: 3,
                time: "12:30",
                title: "Veggie pasta",
                calories: 586,
                nutrientSummary: "P 20 · C 95 · F 14 g"
            )
        ]
    )
    .background(Color("AppBackground"))
}
