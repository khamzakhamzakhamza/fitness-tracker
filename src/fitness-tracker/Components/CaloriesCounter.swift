import SwiftUI

struct CaloriesCounter: View {
    let summary: DailyNutritionSummary

    private let goalMarkerPosition = 0.8

    var body: some View {
        VStack(spacing: 18) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(formatted(summary.caloriesConsumed))
                    .font(.system(size: 42, weight: .black))
                    .foregroundStyle(.primary)

                Text("of \(formatted(summary.calorieGoal)) kcal")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Color("SearchBoxSecondary"))

                Spacer(minLength: 8)

                Text(calorieDifferenceText)
                    .font(.system(size: 16, weight: .black))
                    .foregroundStyle(Color("NutrientCalories"))
            }

            calorieProgress

            VStack(spacing: 12) {
                ForEach(summary.nutrients) { nutrient in
                    nutrientProgress(nutrient)
                }
            }
        }
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity)
        .background(Color("AppBackground"))
        .accessibilityIdentifier("calories-counter")
    }

    private var calorieProgress: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color("SearchBoxSecondary").opacity(0.12))

                Capsule()
                    .fill(Color("NutrientCalories"))
                    .frame(
                        width: geometry.size.width
                            * calorieProgressFraction
                    )

                Rectangle()
                    .fill(Color.primary)
                    .frame(width: 3, height: 28)
                    .offset(
                        x: geometry.size.width * goalMarkerPosition
                    )
                    .overlay(alignment: .topTrailing) {
                        Text("Goal")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.primary)
                            .fixedSize()
                            .offset(x: -5, y: -20)
                    }
            }
        }
        .frame(height: 24)
    }

    private func nutrientProgress(
        _ nutrient: DailyNutrientProgress
    ) -> some View {
        HStack(spacing: 10) {
            Text(nutrient.name)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(Color("SearchBoxSecondary"))
                .frame(width: 74, alignment: .leading)

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color("SearchBoxSecondary").opacity(0.12))

                    Capsule()
                        .fill(color(for: nutrient.shortName))
                        .frame(
                            width: geometry.size.width
                                * progressFraction(
                                    consumed: nutrient.consumed,
                                    goal: nutrient.goal
                                )
                        )
                }
            }
            .frame(height: 16)

            Text(
                "\(formatted(nutrient.consumed)) / "
                    + "\(formatted(nutrient.goal)) \(nutrient.unit)"
            )
            .font(.system(size: 13, weight: .bold))
            .foregroundStyle(.primary)
            .frame(width: 94, alignment: .trailing)
        }
    }

    private var calorieDifferenceText: String {
        let difference = summary.calorieGoal - summary.caloriesConsumed
        if difference >= 0 {
            return "\(formatted(difference)) under"
        }
        return "\(formatted(abs(difference))) over"
    }

    private var calorieProgressFraction: Double {
        progressFraction(
            consumed: summary.caloriesConsumed,
            goal: summary.calorieGoal / goalMarkerPosition
        )
    }

    private func progressFraction(
        consumed: Double,
        goal: Double
    ) -> Double {
        guard goal > 0 else {
            return 0
        }
        return min(max(consumed / goal, 0), 1)
    }

    private func color(for shortName: String) -> Color {
        switch shortName {
        case "protein": Color("NutrientProtein")
        case "carbs": Color("NutrientCarbohydrates")
        case "fat": Color("NutrientFat")
        case "water": Color("NutrientWater")
        default: Color("SearchBoxSecondary")
        }
    }

    private func formatted(_ value: Double) -> String {
        value.formatted(
            .number.precision(.fractionLength(0...1))
        )
    }
}

#Preview {
    CaloriesCounter(
        summary: DailyNutritionSummary(
            caloriesConsumed: 1_842,
            calorieGoal: 3_000,
            nutrients: [
                DailyNutrientProgress(
                    name: "Protein",
                    shortName: "protein",
                    consumed: 93,
                    goal: 500,
                    unit: "g"
                ),
                DailyNutrientProgress(
                    name: "Carbs",
                    shortName: "carbs",
                    consumed: 246,
                    goal: 500,
                    unit: "g"
                ),
                DailyNutrientProgress(
                    name: "Fat",
                    shortName: "fat",
                    consumed: 54,
                    goal: 500,
                    unit: "g"
                ),
                DailyNutrientProgress(
                    name: "Water",
                    shortName: "water",
                    consumed: 300,
                    goal: 500,
                    unit: "g"
                )
            ]
        )
    )
    .padding(.vertical, 20)
    .background(Color("AppBackground"))
}
