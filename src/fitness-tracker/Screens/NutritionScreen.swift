import SwiftUI

struct NutritionScreen: View {
    @State private var searchText = ""
    private let foodItems = [
        FoodListItemModel(
            title: "Chicken & rice bowl",
            subtitle: "Your foods · logged 6 times",
            amount: "586 kcal",
            macrosBreakdown: "P 55 · C 42 · F 22 g",
            imageURL: URL(string: "https://picsum.photos/seed/chicken-rice/100")
        ),
        FoodListItemModel(
            title: "Chicken breast, grilled",
            subtitle: "UK CoFID · per 100 g",
            amount: "164 kcal",
            macrosBreakdown: "P 32 · C 0 · F 4 g",
            imageURL: URL(string: "https://picsum.photos/seed/chicken-breast/100")
        ),
        FoodListItemModel(
            title: "Chicken thigh, roasted",
            subtitle: "UK CoFID · per 100 g",
            amount: "203 kcal",
            macrosBreakdown: "P 26 · C 0 · F 11 g",
            imageURL: URL(string: "https://picsum.photos/seed/chicken-thigh/100")
        ),
        FoodListItemModel(
            title: "Chicken katsu curry",
            subtitle: "Wagamama · brand label",
            amount: "1,058 kcal",
            macrosBreakdown: "P 43 · C 118 · F 46 g",
            imageURL: URL(string: "https://picsum.photos/seed/katsu-curry/100")
        ),
        FoodListItemModel(
            title: "Chicken caesar wrap",
            subtitle: "Tesco · brand label",
            amount: "473 kcal",
            macrosBreakdown: "P 27 · C 44 · F 21 g",
            imageURL: URL(string: "https://picsum.photos/seed/caesar-wrap/100")
        ),
        FoodListItemModel(
            title: "Chicken tikka masala",
            subtitle: "Community · unchecked",
            amount: "510 kcal",
            macrosBreakdown: "P 38 · C 22 · F 30 g",
            imageURL: URL(string: "https://picsum.photos/seed/tikka-masala/100")
        ),
        FoodListItemModel(
            title: "Apple",
            subtitle: "UK CoFID · per 100 g",
            amount: "52 kcal",
            macrosBreakdown: "P 0 · C 14 · F 0 g",
            imageURL: URL(string: "https://picsum.photos/seed/apple/100")
        ),
        FoodListItemModel(
            title: "Banana",
            subtitle: "UK CoFID · per 100 g",
            amount: "89 kcal",
            macrosBreakdown: "P 1 · C 23 · F 0 g",
            imageURL: URL(string: "https://picsum.photos/seed/banana/100")
        ),
        FoodListItemModel(
            title: "Porridge oats",
            subtitle: "Your foods · logged 12 times",
            amount: "370 kcal",
            macrosBreakdown: "P 13 · C 60 · F 8 g",
            imageURL: URL(string: "https://picsum.photos/seed/porridge/100")
        ),
        FoodListItemModel(
            title: "Greek yoghurt",
            subtitle: "Tesco · brand label",
            amount: "120 kcal",
            macrosBreakdown: "P 10 · C 8 · F 5 g",
            imageURL: URL(string: "https://picsum.photos/seed/yoghurt/100")
        ),
        FoodListItemModel(
            title: "Salmon fillet",
            subtitle: "UK CoFID · per 100 g",
            amount: "208 kcal",
            macrosBreakdown: "P 20 · C 0 · F 13 g",
            imageURL: URL(string: "https://picsum.photos/seed/salmon/100")
        ),
        FoodListItemModel(
            title: "Wholemeal toast",
            subtitle: "Community · unchecked",
            amount: "247 kcal",
            macrosBreakdown: "P 13 · C 41 · F 4 g",
            imageURL: URL(string: "https://picsum.photos/seed/toast/100")
        )
    ]

    var body: some View {
        VStack(spacing: 20) {
            SearchBox(
                text: $searchText,
                placeholder: "Search foods"
            )

            FoodList(items: foodItems)
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color("AppBackground"))
    }
}

#Preview {
    NutritionScreen()
}
