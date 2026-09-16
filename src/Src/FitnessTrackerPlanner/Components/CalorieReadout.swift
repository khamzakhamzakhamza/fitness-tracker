import SwiftUI

public struct CalorieReadout: View {
    public let calories: Int?
    public let detail: String

    public init(calories: Int?, detail: String) {
        self.calories = calories
        self.detail = detail
    }

    public var body: some View {
        VStack(spacing: 0) {
            Divider()

            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text(calorieText)
                    .font(.system(size: 22, weight: .black))
                    .monospacedDigit()

                Spacer()

                Text(detail)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Color(Constants.secondaryTextColor))
                    .multilineTextAlignment(.trailing)
            }
            .padding(.top, 20)
            .padding(.bottom, 32)
        }
        .frame(maxWidth: .infinity)
    }

    private var calorieText: String {
        guard let calories else {
            return Constants.zeroCalories
        }

        return calories.formatted(.number.grouping(.automatic)) + Constants.calorieSuffix
    }
}

private enum Constants {
    static let calorieSuffix = " kcal"
    static let zeroCalories = "0 kcal"
    static let secondaryTextColor = "SearchBoxSecondary"
}

#Preview {
    CalorieReadout(
        calories: 3_060,
        detail: "a day to hold 82.4 kg"
    )
    .padding()
}
