import SwiftUI

public struct PlanningRootView: View {
    @State private var route: PlanningInitialRoute?

    private let routingService: PlanningInitialRoutingService
    private let onOnboardingFinished: () -> Void

    public init(
        routingService: PlanningInitialRoutingService = .shared,
        onOnboardingFinished: @escaping () -> Void
    ) {
        self.routingService = routingService
        self.onOnboardingFinished = onOnboardingFinished
    }

    public var body: some View {
        Group {
            switch route {
            case .introduction:
                IntroductionScreen(onOnboardingFinished: onOnboardingFinished)
            case .firstMeasurement:
                NavigationStack {
                    MeasurementInputScreen(onOnboardingFinished: onOnboardingFinished)
                }
            case .planCreation:
                NavigationStack {
                    PlanCreationScreen(onOnboardingFinished: onOnboardingFinished)
                }
            case .main:
                ProgressView()
            case nil:
                ProgressView()
            }
        }
        .task {
            route = routingService.initialRoute()

            if route == .main {
                onOnboardingFinished()
            }
        }
    }
}
