@MainActor
public final class OnboardingRoutingService {
    public static let shared = OnboardingRoutingService()

    private let planningService: any PlanningServiceProtocol

    public init(planningService: any PlanningServiceProtocol = PlanningService.shared) {
        self.planningService = planningService
    }

    public func shouldShowOnboarding() -> Bool {
        do {
            return try !planningService.hasActivePlan()
        } catch {
            return true
        }
    }
}
