import SwiftUI

struct NutritionScreen: View {
    private static let pageSize = 500

    @State private var searchText = ""
    @State private var foodItems: [FoodListItemModel] = []
    @State private var databaseErrorMessage: String?
    @State private var isLoadingFoods = false
    @State private var hasMoreFoods = true
    @State private var nextOffset = 0
    private let databaseService = FoodDatabaseService()

    var body: some View {
        VStack(spacing: 20) {
            SearchBox(
                text: $searchText,
                placeholder: "Search foods"
            )

            if let databaseErrorMessage {
                Text(databaseErrorMessage)
                    .foregroundStyle(Color("SearchBoxSecondary"))
            } else {
                FoodList(
                    items: foodItems,
                    isLoadingMore: isLoadingFoods,
                    onLoadMore: loadMoreFoods
                )
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color("AppBackground"))
        .task {
            await loadMoreFoods()
        }
    }

    private func loadMoreFoods() async {
        guard !isLoadingFoods, hasMoreFoods else {
            return
        }

        isLoadingFoods = true
        defer { isLoadingFoods = false }

        do {
            let foods = try await databaseService.fetchFoods(
                limit: Self.pageSize,
                offset: nextOffset
            )
            let newItems = foods.map { food in
                FoodListItemModel(
                    title: food.name,
                    subtitle: food.brand ?? "",
                    amount: "100 kcal",
                    macrosBreakdown: "P 1 · C 20 · F 0 g",
                    imageURL: food.imageURL
                )
            }
            foodItems.append(contentsOf: newItems)
            nextOffset += foods.count
            hasMoreFoods = foods.count == Self.pageSize
        } catch {
            databaseErrorMessage = error.localizedDescription
        }
    }
}

#Preview {
    NutritionScreen()
}
