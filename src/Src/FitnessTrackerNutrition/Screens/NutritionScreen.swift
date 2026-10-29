import SwiftUI

public struct NutritionScreen: View {
    @State private var dailySummary = DailyNutritionSummary.empty

    public init() {}

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Nutrition")
                .font(.system(size: 28, weight: .black))
                .padding(.horizontal, 20)
                .padding(.top, 20)

            CaloriesCounter(summary: dailySummary)
                .padding(.top, 28)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color("AppBackground"))
        .task {
            dailySummary = (try? await NutritionService.shared
                .fetchDailyNutritionSummary()) ?? .empty
        }
    }
}
