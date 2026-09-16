import SwiftUI

public struct CalorieBreakdown: View {
    public let restingCalories: Int?
    public let restingCalculation: String
    public let activityDescription: String
    public let activityMultiplier: Double?

    public init(
        restingCalories: Int?,
        restingCalculation: String,
        activityDescription: String,
        activityMultiplier: Double?
    ) {
        self.restingCalories = restingCalories
        self.restingCalculation = restingCalculation
        self.activityDescription = activityDescription
        self.activityMultiplier = activityMultiplier
    }

    public var body: some View {
        VStack(spacing: 0) {
            Divider()
                .padding(.bottom, 6)

            calculationRow(
                label: Constants.restingLabel,
                explanation: restingCalculation,
                value: calorieText,
                emphasizesValue: true
            )

            calculationRow(
                label: Constants.activityLabel,
                explanation: activityDescription,
                value: multiplierText,
                emphasizesValue: false
            )
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
    }

    private var calorieText: String {
        guard let restingCalories else {
            return Constants.zeroCalories
        }

        return restingCalories.formatted(.number.grouping(.automatic)) + Constants.calorieSuffix
    }

    private var multiplierText: String {
        guard let activityMultiplier else {
            return Constants.zeroMultiplier
        }

        return Constants.multiplierPrefix
            + activityMultiplier.formatted(
                .number.precision(.fractionLength(0...3))
            )
    }

    private func calculationRow(
        label: String,
        explanation: String,
        value: String,
        emphasizesValue: Bool
    ) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(label)
                .frame(width: 62, alignment: .leading)

            Text(explanation)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(value)
                .font(
                    .system(
                        size: emphasizesValue ? 12 : 9,
                        weight: emphasizesValue ? .black : .bold
                    )
                )
                .foregroundStyle(Color.primary)
                .monospacedDigit()
        }
        .font(.system(size: 9, weight: .bold))
        .foregroundStyle(Color(Constants.secondaryTextColor))
        .padding(.vertical, 3)
    }
}

private enum Constants {
    static let restingLabel = "Resting"
    static let activityLabel = "Activity"
    static let calorieSuffix = " kcal"
    static let multiplierPrefix = "× "
    static let zeroCalories = "0 kcal"
    static let zeroMultiplier = "× 0"
    static let secondaryTextColor = "SearchBoxSecondary"
}

#Preview {
    CalorieBreakdown(
        restingCalories: 1_774,
        restingCalculation: "Mifflin-St Jeor",
        activityDescription: "6–7 sessions a week",
        activityMultiplier: 1.725
    )
    .padding()
}
