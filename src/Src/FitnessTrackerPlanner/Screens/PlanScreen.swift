import SwiftUI
import FitnessTrackerShared

public struct PlanScreen: View {
    @State private var planProgress: PlanProgressValue?
    @State private var measurements: [UserMeasurement] = []
    @State private var isShowingLogMeasurement = false

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
                            milestones: planProgress.milestones
                        )
                        .frame(height: geometry.size.height / 2)
                    }

                    MeasurementList(measurements: measurements)
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
        .task {
            planProgress = try? PlanningService.shared.fetchActivePlanProgress()
            measurements = (try? PlanningService.shared.fetchMeasurements(
                amount: Constants.measurementFetchLimit
            )) ?? []
        }
    }
}

private enum Constants {
    static let title = "Plan"
    static let logMeasurementButtonTitle = "LOG MEASUREMENT"
    static let measurementFetchLimit = 100
}
