import SwiftUI

struct Nutrients: View {
    private static let rowHeight: CGFloat = 32
    private static let visibleRowCount = 3

    let nutrients: [NutrientModel]
    @State private var scrollOffset: CGFloat = 0

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

    private var viewportHeight: CGFloat {
        CGFloat(min(displayedNutrients.count, Self.visibleRowCount))
            * Self.rowHeight
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            Grid(
                alignment: .leading,
                horizontalSpacing: 10,
                verticalSpacing: 0
            ) {
                ForEach(displayedNutrients) { nutrient in
                    GridRow {
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
                    .frame(minHeight: Self.rowHeight)
                    .contentShape(Rectangle())
                }
            }
            .padding(.horizontal, 20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                GeometryReader { geometry in
                    Color.clear.preference(
                        key: NutrientScrollOffsetPreferenceKey.self,
                        value: geometry.frame(
                            in: .named("nutrient-scroll")
                        ).minY
                    )
                }
            }
            .font(.system(size: 12, weight: .bold))
            .lineLimit(1)
        }
        .coordinateSpace(name: "nutrient-scroll")
        .onPreferenceChange(NutrientScrollOffsetPreferenceKey.self) {
            scrollOffset = $0
        }
        .frame(maxWidth: .infinity)
        .frame(height: viewportHeight)
        .overlay(alignment: .trailing) {
            persistentScrollIndicator
        }
        .contentShape(Rectangle())
    }

    private var persistentScrollIndicator: some View {
        GeometryReader { geometry in
            let contentHeight = CGFloat(displayedNutrients.count)
                * Self.rowHeight
            let thumbHeight = contentHeight > 0
                ? min(
                    geometry.size.height,
                    max(
                        24,
                        geometry.size.height * geometry.size.height
                            / contentHeight
                    )
                )
                : 0
            let maximumScrollOffset = max(
                contentHeight - geometry.size.height,
                0
            )
            let scrollProgress = maximumScrollOffset > 0
                ? min(max(-scrollOffset / maximumScrollOffset, 0), 1)
                : 0

            ZStack(alignment: .top) {
                Capsule()
                    .fill(Color("SearchBoxSecondary").opacity(0.12))

                Capsule()
                    .fill(Color("SearchBoxSecondary").opacity(0.65))
                    .frame(height: thumbHeight)
                    .offset(
                        y: scrollProgress
                            * (geometry.size.height - thumbHeight)
                    )
            }
            .frame(width: 4)
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .allowsHitTesting(false)
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

private struct NutrientScrollOffsetPreferenceKey: PreferenceKey {
    nonisolated(unsafe) static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
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
