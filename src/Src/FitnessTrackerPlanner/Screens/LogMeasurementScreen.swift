import SwiftUI
import FitnessTrackerShared

public struct LogMeasurementScreen: View {
    @Environment(\.dismiss) private var dismiss
    private let measurementDate: Date
    @State private var selectedWeightSI = 0.0
    @State private var weightUnit: MeasurementUnitOption?
    @State private var latestMeasurement: UserMeasurement?
    @State private var lastWeekMeasurement: UserMeasurement?

    public init(measurementDate: Date = .now) {
        self.measurementDate = measurementDate
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                Text("\(dateText) · \(timeText)")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.secondary)
            }
            .padding(20)

            InfoLabel(text: Constants.accuracyMessage)
                .padding(.horizontal, 20)
                .padding(.bottom, 20)

            if let weightUnit {
                WeightInput(
                    selectedWeightSI: $selectedWeightSI,
                    unit: weightUnit.shortName,
                    siConversionValue: weightUnit.siConversionValue,
                    allowedRangeSI: Constants.minimumWeightSI...Constants.maximumWeightSI
                )
                .padding(.horizontal, 20)

                if let lastWeekMeasurement {
                    WeeklyWeightChange(
                        currentWeightSI: selectedWeightSI,
                        previousMeasurement: lastWeekMeasurement,
                        unit: weightUnit
                    )
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
            }

            Spacer()

            PrimaryActionButton(
                title: Constants.saveButtonTitle,
                action: saveMeasurement
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle(Constants.title)
        .navigationBarTitleDisplayMode(.inline)
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

            selectedWeightSI = latestMeasurement.weightSI
            self.latestMeasurement = latestMeasurement
            lastWeekMeasurement = try PlanningService.shared
                .fetchLatestMeasurementFromLastWeek(
                    referenceDate: measurementDate
                )
            weightUnit = preferredUnit
        } catch {
            latestMeasurement = nil
            lastWeekMeasurement = nil
            weightUnit = nil
        }
    }

    private func saveMeasurement() {
        guard let latestMeasurement,
              let heightSI = latestMeasurement.heightSI,
              weightUnit != nil else {
            return
        }

        let wasCreated = PlanningService.shared.createMeasurement(
            weightSI: selectedWeightSI,
            heightSI: heightSI,
            leanMass: latestMeasurement.leanMass,
            activityLevelID: latestMeasurement.activityLevelID
        )

        if wasCreated {
            dismiss()
        }
    }

}

private enum Constants {
    static let title = "What's your current weight"
    static let accuracyMessage = "For the best accuracy, please try to take measurements at the same time each day while wearing the same clothes."
    static let saveButtonTitle = "Save weight-in"
    static let minimumWeightSI = 20_000.0
    static let maximumWeightSI = 500_000.0
}
