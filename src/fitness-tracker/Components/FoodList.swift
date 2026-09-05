import SwiftUI

struct FoodList: View {
    let items: [FoodListItemModel]

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("RESULTS")
                Spacer()
                Text("\(items.count) MATCHES")
            }
            .font(.system(size: 13, weight: .bold))
            .tracking(0.7)
            .foregroundStyle(Color("SearchBoxSecondary"))
            .padding(.bottom, 8)

            Divider()

            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(items) { item in
                        FoodListItem(item: item)
                        Divider()
                    }
                }
            }
        }
        .background(Color("AppBackground"))
    }
}

#Preview {
    FoodList(
        items: [
            FoodListItemModel(
                title: "Chicken & rice bowl",
                subtitle: "Your foods · logged 6 times",
                amount: "586 kcal",
                macrosBreakdown: "P 55 · C 42 · F 22 g"
            ),
            FoodListItemModel(
                title: "Chicken breast, grilled",
                subtitle: "UK CoFID · per 100 g",
                amount: "164 kcal",
                macrosBreakdown: "P 32 · C 0 · F 4 g"
            )
        ]
    )
    .padding(20)
    .background(Color("AppBackground"))
}
