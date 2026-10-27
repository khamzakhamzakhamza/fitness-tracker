import SwiftUI

public struct PlanScreen: View {
    @State private var planProgress: PlanProgressValue?

    public init() {}

    public var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Plan")
                .font(.system(size: 28, weight: .black))

            if let planProgress {
                PlanProgress(
                    plan: planProgress.plan,
                    milestones: planProgress.milestones
                )
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(20)
        .task {
            planProgress = try? PlanningService.shared.fetchActivePlanProgress()
        }
    }
}
