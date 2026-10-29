import SwiftUI
import FitnessTrackerShared

public struct PlanScreen: View {
    @State private var planProgress: PlanProgressValue?
    @State private var measurements: [UserMeasurement] = []
    @State private var planMeasurements: [UserMeasurement] = []
    @State private var isShowingLogMeasurement = false
    @State private var measurementPendingDeletion: UserMeasurement?
    @State private var isShowingDeletionWarning = false

    public init() {}

    public var body: some View {
        GeometryReader { geometry in
            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 20) {
                    Text(Constants.title)
                        .font(.system(size: 28, weight: .black))

                    if let planProgress {
                        PlanProgress(
                            plan: planProgress.plan,
                            milestones: planProgress.milestones,
                            measurements: planMeasurements
                        )
                        .frame(height: geometry.size.height / 2)
                    }

                    MeasurementList(
                        measurements: measurements,
                        onDeleteRequested: requestMeasurementDeletion
                    )
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .padding(.horizontal, 20)
                .padding(.top, 20)

                PrimaryActionButton(
                    title: Constants.logMeasurementButtonTitle,
                    action: {
                        isShowingLogMeasurement = true
                    }
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .navigationDestination(isPresented: $isShowingLogMeasurement) {
            LogMeasurementScreen()
        }
        .alert(
            Constants.deleteWarningTitle,
            isPresented: $isShowingDeletionWarning,
            presenting: measurementPendingDeletion
        ) { measurement in
            Button(Constants.cancelButtonTitle, role: .cancel) {
                measurementPendingDeletion = nil
            }

            Button(Constants.deleteButtonTitle, role: .destructive) {
                deleteMeasurement(measurement)
            }
        } message: { _ in
            Text(Constants.deleteWarningMessage)
        }
        .onAppear {
            loadPlanData()
        }
    }

    private func loadPlanData() {
        let loadedPlanProgress = try? PlanningService.shared.fetchActivePlanProgress()
        planProgress = loadedPlanProgress

        if let planStartDate = loadedPlanProgress?.milestones.min(by: {
            $0.date < $1.date
        })?.date {
            planMeasurements = (try? PlanningService.shared
                .fetchLatestDailyMeasurements(from: planStartDate)) ?? []
        } else {
            planMeasurements = []
        }

        measurements = (try? PlanningService.shared.fetchMeasurements(
            amount: Constants.measurementFetchLimit
        )) ?? []
    }

    private func requestMeasurementDeletion(_ measurement: UserMeasurement) {
        measurementPendingDeletion = measurement
        isShowingDeletionWarning = true
    }

    private func deleteMeasurement(_ measurement: UserMeasurement) {
        if PlanningService.shared.deleteMeasurement(id: measurement.id) {
            loadPlanData()
        }

        measurementPendingDeletion = nil
    }
}

private enum Constants {
    static let title = "Plan"
    static let logMeasurementButtonTitle = "LOG WEIGHT"
    static let measurementFetchLimit = 100
    static let deleteWarningTitle = "Delete measurement?"
    static let deleteWarningMessage = "This measurement will be permanently deleted."
    static let cancelButtonTitle = "Cancel"
    static let deleteButtonTitle = "Delete"
}
