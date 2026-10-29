import SwiftUI
import FitnessTrackerShared

public struct LogMeasurementScreen: View {
    private let measurementDate: Date

    public init(measurementDate: Date = .now) {
        self.measurementDate = measurementDate
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                Text(Constants.title)
                    .font(.system(size: 28, weight: .black))

                Text("\(dateText) · \(timeText)")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.secondary)
            }
            .padding(20)

            Spacer()

            PrimaryActionButton(
                title: Constants.saveButtonTitle,
                action: {}
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var dateText: String {
        measurementDate.formatted(
            .dateTime
                .day(.twoDigits)
                .month(.twoDigits)
                .year()
        )
    }

    private var timeText: String {
        measurementDate.formatted(
            .dateTime
                .hour(.twoDigits(amPM: .omitted))
                .minute(.twoDigits)
        )
    }
}

private enum Constants {
    static let title = "What's your current weight"
    static let saveButtonTitle = "Save weight-in"
}
