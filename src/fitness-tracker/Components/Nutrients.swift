import SwiftUI

struct Nutrients: View {
    let nutrients: [NutrientModel]

    private var displayedNutrients: [NutrientModel] {
        nutrients
            .enumerated()
            .filter {
                Self.roundedAmountForDisplay($0.element.amount) != nil
            }
            .sorted { left, right in
                let leftPriority = priority(for: left.element.shortName)
                let rightPriority = priority(for: right.element.shortName)

                if leftPriority == rightPriority {
                    return left.offset < right.offset
                }

                return leftPriority < rightPriority
            }
            .map(\.element)
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Array(displayedNutrients.enumerated()), id: \.element.id) {
                    index,
                    nutrient in
                    if index > 0 {
                        Text("·")
                            .foregroundStyle(Color("SearchBoxSecondary"))
                    }

                    HStack(spacing: 3) {
                        Text(nutrient.name)
                            .foregroundStyle(Color("SearchBoxSecondary"))

                        if let amount = Self.roundedAmountForDisplay(
                            nutrient.amount
                        ) {
                            Text("\(formatted(amount)) \(nutrient.unit)")
                                .foregroundStyle(
                                    color(for: nutrient.shortName)
                                )
                        }
                    }
                }
            }
            .font(.system(size: 12, weight: .bold))
            .lineLimit(1)
            .frame(minHeight: 48)
            .contentShape(Rectangle())
        }
        .frame(minHeight: 48)
        .contentShape(Rectangle())
    }

    nonisolated static func roundedAmountForDisplay(
        _ amount: Double?
    ) -> Double? {
        guard let amount else {
            return nil
        }

        let roundedAmount = (amount * 10).rounded() / 10
        return roundedAmount > 0 ? roundedAmount : nil
    }

    private func priority(for shortName: String) -> Int {
        switch shortName {
        case "carbs": 0
        case "protein": 1
        case "fat": 2
        default: 3
        }
    }

    private func color(for shortName: String) -> Color {
        switch shortName {
        case "protein": Color("NutrientProtein")
        case "carbs": Color("NutrientCarbohydrates")
        case "fat": Color("NutrientFat")
        case "sat_fat": Color("NutrientSaturatedFat")
        case "sugars": Color("NutrientSugars")
        case "fiber": Color("NutrientFiber")
        case "salt": Color("NutrientSalt")
        case "sodium": Color("NutrientSodium")
        case "water": Color("NutrientWater")
        case "caffeine": Color("NutrientCaffeine")
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
    Nutrients(
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
    .padding(20)
    .background(Color("AppBackground"))
}
