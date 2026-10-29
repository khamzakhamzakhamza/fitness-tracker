import SwiftUI

public struct MeasurementList: View {
    public let measurements: [UserMeasurement]

    public init(measurements: [UserMeasurement]) {
        self.measurements = measurements
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Divider()

            Text(Constants.title)
                .font(.system(size: 12, weight: .bold))
                .padding(.vertical, 10)

            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(measurements, id: \.id) { measurement in
                        MeasurementListRow(measurement: measurement)
                    }
                }
            }
        }
    }
}

private struct MeasurementListRow: View {
    let measurement: UserMeasurement

    var body: some View {
        HStack {
            Text("\(dateText) · \(timeText)")
            .foregroundStyle(.secondary)
            .font(.system(size: 11, weight: .bold))

            Spacer()

            Text("\(weightText) kg")
                .font(.system(size: 12, weight: .bold))
        }
        .padding(.vertical, 10)
        .overlay(alignment: .top) {
            Divider()
        }
    }

    private var weightText: String {
        (measurement.weightSI / Constants.gramsPerKilogram)
            .formatted(.number.precision(.fractionLength(0...1)))
    }

    private var dateText: String {
        measurement.dateAdded.formatted(
            .dateTime
                .day(.twoDigits)
                .month(.twoDigits)
        )
    }

    private var timeText: String {
        measurement.dateAdded.formatted(
            .dateTime
                .hour(.twoDigits(amPM: .omitted))
                .minute(.twoDigits)
        )
    }
}

private enum Constants {
    static let title = "Logged measurements"
    static let gramsPerKilogram = 1_000.0
}
