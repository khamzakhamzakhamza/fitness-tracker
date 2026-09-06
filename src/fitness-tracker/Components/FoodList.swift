import SwiftUI

struct FoodList: View {
    let items: [FoodListItemModel]
    let totalMatches: Int
    let isLoadingMore: Bool
    let onLoadMore: () async -> Void
    let onSelect: (FoodListItemModel) -> Void
    @StateObject private var networkMonitor = NetworkMonitor()

    init(
        items: [FoodListItemModel],
        totalMatches: Int? = nil,
        isLoadingMore: Bool = false,
        onLoadMore: @escaping () async -> Void = {},
        onSelect: @escaping (FoodListItemModel) -> Void = { _ in }
    ) {
        self.items = items
        self.totalMatches = totalMatches ?? items.count
        self.isLoadingMore = isLoadingMore
        self.onLoadMore = onLoadMore
        self.onSelect = onSelect
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("RESULTS")
                Spacer()
                Text("\(totalMatches) MATCHES")
                    .accessibilityIdentifier("food-match-count")
            }
            .font(.system(size: 13, weight: .bold))
            .tracking(0.7)
            .foregroundStyle(Color("SearchBoxSecondary"))
            .padding(.horizontal, 20)
            .padding(.bottom, 8)

            Divider()

            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(items) { item in
                        Button {
                            onSelect(item)
                        } label: {
                            FoodListItem(
                                item: item,
                                isInternetAvailable: networkMonitor.isConnected
                            )
                        }
                        .buttonStyle(.plain)
                        .padding(.leading, 20)
                        .task {
                            if item.id == items.last?.id {
                                await onLoadMore()
                            }
                        }
                        Divider()
                    }

                    if isLoadingMore && !items.isEmpty {
                        ProgressView()
                            .padding(.vertical, 16)
                    }
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .accessibilityIdentifier("food-list-scroll-view")
        }
        .background(Color("AppBackground"))
    }
}

#Preview {
    FoodList(
        items: [
            FoodListItemModel(
                id: 1,
                title: "Chicken & rice bowl",
                subtitle: "Your foods · logged 6 times"
            ),
            FoodListItemModel(
                id: 2,
                title: "Chicken breast, grilled",
                subtitle: "UK CoFID · per 100 g"
            )
        ]
    )
    .padding(20)
    .background(Color("AppBackground"))
}
