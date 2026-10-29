import SwiftUI
import FitnessTrackerShared

public struct LogMeasurementScreen: View {
    @Environment(\.dismiss) private var dismiss
    private let measurementDate: Date
    @State private var selectedWeight = 0.0
    @State private var weightUnit: MeasurementUnitOption?
    @State private var latestMeasurement: UserMeasurement?

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

            if let weightUnit {
                WeightSelector(
                    selectedWeight: $selectedWeight,
                    unit: weightUnit.shortName,
                    allowedRange: weightRange(for: weightUnit)
                )
                .padding(.horizontal, 20)
            }

            Spacer()

            PrimaryActionButton(
                title: Constants.saveButtonTitle,
                action: saveMeasurement
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .task {
            loadWeight()
        }
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

    private func loadWeight() {
        guard let measurementUnitService = PlanningDependencyContext.measurementUnitService else {
            return
        }

        do {
            guard let latestMeasurement = try PlanningService.shared
                .fetchMeasurements(amount: 1)
                .first else {
                return
            }

            let units = try measurementUnitService.fetchWeightMeasurementUnits()
            guard let preferredUnit = units.first(where: \.isDefault) ?? units.first,
                  preferredUnit.siConversionValue > 0 else {
                return
            }

            selectedWeight = latestMeasurement.weightSI / preferredUnit.siConversionValue
            self.latestMeasurement = latestMeasurement
            weightUnit = preferredUnit
        } catch {
            latestMeasurement = nil
            weightUnit = nil
        }
    }

    private func saveMeasurement() {
        guard let latestMeasurement,
              let heightSI = latestMeasurement.heightSI,
              let weightUnit else {
            return
        }

        let wasCreated = PlanningService.shared.createMeasurement(
            weightSI: selectedWeight * weightUnit.siConversionValue,
            heightSI: heightSI,
            leanMass: latestMeasurement.leanMass,
            activityLevelID: latestMeasurement.activityLevelID
        )

        if wasCreated {
            dismiss()
        }
    }

    private func weightRange(
        for unit: MeasurementUnitOption
    ) -> ClosedRange<Double> {
        let minimumWeight = Constants.minimumWeightSI / unit.siConversionValue
        let maximumWeight = Constants.maximumWeightSI / unit.siConversionValue

        return minimumWeight...maximumWeight
    }
}

private enum Constants {
    static let title = "What's your current weight"
    static let saveButtonTitle = "Save weight-in"
    static let minimumWeightSI = 20_000.0
    static let maximumWeightSI = 500_000.0
}
