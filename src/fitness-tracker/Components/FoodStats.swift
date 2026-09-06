import SwiftUI

struct FoodStats: View {
    let stats: FoodStatsModel

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\(formatted(stats.calories)) kcal")
                .font(.system(size: 20, weight: .black))
                .foregroundStyle(Color("NutrientCalories"))
                .lineLimit(1)

            Nutrients(nutrients: stats.nutrients)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 24)
        .overlay(alignment: .top) {
            Divider()
        }
        .overlay(alignment: .bottom) {
            Divider()
        }
    }

    private func formatted(_ value: Double?) -> String {
        guard let value else {
            return "—"
        }

        return value.formatted(
            .number.precision(.fractionLength(0...1))
        )
    }
}

#Preview {
    FoodStats(
        stats: FoodStatsModel(
            calories: 246,
            nutrients: [
                NutrientModel(
                    name: "Protein",
                    shortName: "protein",
                    amount: 48,
                    unit: "g"
                ),
                NutrientModel(
                    name: "Carbohydrates",
                    shortName: "carbs",
                    amount: 0,
                    unit: "g"
                ),
                NutrientModel(
                    name: "Fat",
                    shortName: "fat",
                    amount: 6,
                    unit: "g"
                )
            ]
        )
    )
    .padding(.horizontal, 20)
    .background(Color("AppBackground"))
}
