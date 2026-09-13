import SwiftUI

struct NutritionScreen: View {
    @State private var isShowingLogFood = false
    @State private var dailySummary = DailyNutritionSummary.empty
    @State private var loggedFoods: [LoggedFoodListItemModel] = []
    @State private var pendingDeletion: LoggedFoodListItemModel?
    private let nutritionService = NutritionService()

    var body: some View {
        VStack(spacing: 0) {
            ScreenTitle("Progress is built on the plate.")
                .padding(.horizontal, 20)
                .padding(.top, 28)

            CaloriesCounter(summary: dailySummary)
                .padding(.top, 28)

            LoggedFoodList(items: loggedFoods) { item in
                pendingDeletion = item
            }
            .padding(.top, 20)

            LogMealButton {
                isShowingLogFood = true
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color("AppBackground"))
        .navigationDestination(isPresented: $isShowingLogFood) {
            LogFoodScreen {
                isShowingLogFood = false
                Task {
                    await loadDashboard()
                }
            }
        }
        .task {
            try? await nutritionService.initializeLocalDatabase()
            await loadDashboard()
        }
        .alert(
            "Remove this entry?",
            isPresented: Binding(
                get: { pendingDeletion != nil },
                set: { isPresented in
                    if !isPresented {
                        pendingDeletion = nil
                    }
                }
            ),
            presenting: pendingDeletion
        ) { item in
            Button("KEEP", role: .cancel) {
                pendingDeletion = nil
            }
            Button("REMOVE", role: .destructive) {
                pendingDeletion = nil
                Task {
                    await deleteLog(item)
                }
            }
        }
    }

    private func loadDashboard() async {
        do {
            let dashboard = try await nutritionService
                .dailyNutritionDashboard()
            dailySummary = dashboard.summary
            loggedFoods = dashboard.loggedFoods
        } catch is CancellationError {
            return
        } catch {
            return
        }
    }

    private func deleteLog(_ item: LoggedFoodListItemModel) async {
        do {
            try await nutritionService.deleteNutritionLog(id: item.id)
            await loadDashboard()
        } catch is CancellationError {
            return
        } catch {
            return
        }
    }
}

#Preview {
    NavigationStack {
        NutritionScreen()
    }
}
