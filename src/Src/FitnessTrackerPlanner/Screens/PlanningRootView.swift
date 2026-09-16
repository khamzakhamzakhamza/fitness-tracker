import SwiftUI

public struct PlanningRootView: View {
    @State private var route: PlanningInitialRoute?

    private let routingService: PlanningInitialRoutingService

    public init(routingService: PlanningInitialRoutingService = .shared) {
        self.routingService = routingService
    }

    public var body: some View {
        Group {
            switch route {
            case .introduction:
                IntroductionScreen()
            case .firstMeasurement:
                NavigationStack {
                    MeasurementInputScreen()
                }
            case .onboardingComplete:
                EmptyView()
            case nil:
                ProgressView()
            }
        }
        .task {
            route = routingService.initialRoute()
        }
    }
}
