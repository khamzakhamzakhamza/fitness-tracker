import Foundation

public enum PlanningInitialRoute: Equatable {
    case introduction
    case firstMeasurement
    case planCreation
}

@MainActor
public final class PlanningInitialRoutingService {
    public static let shared = PlanningInitialRoutingService()

    private let planningService: any PlanningServiceProtocol

    public init(planningService: any PlanningServiceProtocol = PlanningService.shared) {
        self.planningService = planningService
    }

    public func initialRoute() -> PlanningInitialRoute {
        do {
            guard try planningService.fetchUser() != nil else {
                return .introduction
            }

            guard !(try planningService.fetchMeasurements(amount: 1)).isEmpty else {
                return .firstMeasurement
            }

            return .planCreation
        } catch {
            return .introduction
        }
    }
}
