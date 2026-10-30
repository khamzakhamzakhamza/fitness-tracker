import SwiftUI
import FitnessTrackerShared

public struct NutritionScreen: View {
    @State private var dailySummary = DailyNutritionSummary.empty
    @State private var isShowingLogFood = false

    public init() {}

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ScreenTitle("Nutrition")
                .padding(.horizontal, 20)
                .padding(.top, 20)

            CaloriesCounter(summary: dailySummary)
                .padding(.top, 28)

            Spacer()

            PrimaryActionButton(title: "LOG MEAL") {
                isShowingLogFood = true
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color("AppBackground"))
        .navigationDestination(isPresented: $isShowingLogFood) {
            LogFoodScreen {
                isShowingLogFood = false
                Task {
                    await loadDailySummary()
                }
            }
        }
        .task {
            await loadDailySummary()
        }
    }

    private func loadDailySummary() async {
        dailySummary = (try? await NutritionService.shared
            .fetchDailyNutritionSummary()) ?? .empty
    }
}
