import SwiftUI

struct FoodSearch: View {
    private static let pageSize = 500

    @State private var searchText = ""
    @State private var foodItems: [FoodListItemModel] = []
    @State private var totalMatches = 0
    @State private var databaseErrorMessage: String?
    @State private var isSearching = false
    @State private var isLoadingMore = false
    @State private var hasMoreFoods = true
    @State private var nextOffset = 0
    @State private var activeQuery = ""
    @State private var searchRequestID = UUID()
    @State private var selectedFoodID: Int64?
    private let nutritionService = NutritionService()

    var body: some View {
        VStack(spacing: 20) {
            SearchBox(
                text: $searchText,
                placeholder: "Search foods"
            )
            .padding(.horizontal, 20)

            if let databaseErrorMessage {
                Text(databaseErrorMessage)
                    .foregroundStyle(Color("SearchBoxSecondary"))
                    .padding(.horizontal, 20)
            } else {
                FoodList(
                    items: foodItems,
                    totalMatches: totalMatches,
                    isLoadingMore: isSearching || isLoadingMore,
                    onLoadMore: loadMoreFoods,
                    onSelect: { item in
                        selectedFoodID = item.id
                    }
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color("AppBackground"))
        .task(id: searchText) {
            await searchFoods(query: searchText)
        }
        .navigationDestination(item: $selectedFoodID) { foodID in
            AddFoodScreen(foodID: foodID)
        }
    }

    private func searchFoods(query: String) async {
        let requestID = UUID()
        searchRequestID = requestID
        isSearching = true
        isLoadingMore = false
        databaseErrorMessage = nil

        defer {
            if searchRequestID == requestID {
                isSearching = false
            }
        }

        do {
            let page = try await nutritionService.searchFoods(
                query: query,
                limit: Self.pageSize,
                offset: 0
            )
            try Task.checkCancellation()
            guard searchRequestID == requestID else {
                return
            }

            activeQuery = query
            foodItems = page.items
            totalMatches = page.totalMatches
            nextOffset = page.items.count
            hasMoreFoods = nextOffset < page.totalMatches
        } catch is CancellationError {
            return
        } catch {
            guard searchRequestID == requestID else {
                return
            }
            foodItems = []
            totalMatches = 0
            hasMoreFoods = false
            databaseErrorMessage = error.localizedDescription
        }
    }

    private func loadMoreFoods() async {
        guard !isSearching, !isLoadingMore, hasMoreFoods else {
            return
        }

        let query = activeQuery
        let requestID = searchRequestID
        let offset = nextOffset
        isLoadingMore = true
        defer {
            if searchRequestID == requestID {
                isLoadingMore = false
            }
        }

        do {
            let page = try await nutritionService.searchFoods(
                query: query,
                limit: Self.pageSize,
                offset: offset
            )
            try Task.checkCancellation()
            guard
                searchRequestID == requestID,
                activeQuery == query,
                nextOffset == offset
            else {
                return
            }

            foodItems.append(contentsOf: page.items)
            totalMatches = page.totalMatches
            nextOffset += page.items.count
            hasMoreFoods = nextOffset < page.totalMatches
        } catch is CancellationError {
            return
        } catch {
            guard searchRequestID == requestID else {
                return
            }
            databaseErrorMessage = error.localizedDescription
        }
    }
}

#Preview {
    FoodSearch()
}
