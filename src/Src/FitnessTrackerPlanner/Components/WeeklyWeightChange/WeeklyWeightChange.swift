import SwiftUI

public struct WeeklyWeightChange: View {
    public let currentWeightSI: Double
    public let previousMeasurement: UserMeasurement
    public let unit: MeasurementUnitOption

    public init(
        currentWeightSI: Double,
        previousMeasurement: UserMeasurement,
        unit: MeasurementUnitOption
    ) {
        self.currentWeightSI = currentWeightSI
        self.previousMeasurement = previousMeasurement
        self.unit = unit
    }

    public var body: some View {
        if hasChange {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Text(changeText)
                    .font(.system(size: 24, weight: .black))
                    .foregroundStyle(Color.accentColor)

                Spacer()

                Text("since \(measurementDateText)")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .overlay(alignment: .top) {
                Divider()
            }
            .overlay(alignment: .bottom) {
                Divider()
            }
        }
    }

    private var hasChange: Bool {
        abs(currentWeightSI - previousMeasurement.weightSI)
            > Constants.comparisonTolerance
    }

    private var changeText: String {
        let changeSI = currentWeightSI - previousMeasurement.weightSI
        let convertedChange = abs(changeSI) / unit.siConversionValue
        let direction = changeSI > 0
            ? Constants.gainedText
            : Constants.lostText

        return "\(formatted(convertedChange)) \(unit.shortName) \(direction)"
    }

    private var measurementDateText: String {
        previousMeasurement.dateAdded.formatted(
            .dateTime
                .day(.twoDigits)
                .month(.abbreviated)
        )
    }

    private func formatted(_ value: Double) -> String {
        value.formatted(
            .number.precision(.fractionLength(0...2))
        )
    }
}

private enum Constants {
    static let comparisonTolerance = 0.001
    static let gainedText = "gained"
    static let lostText = "lost"
}
