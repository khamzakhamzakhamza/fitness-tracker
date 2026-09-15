import Foundation
import Testing
@testable import FitnessTrackerPlanner

@MainActor
struct PlanningInitialRoutingServiceTests {
    @Test
    func routesToIntroductionWhenThereIsNoUser() {
        let routingService = makeRoutingService(
            hasUsers: false,
            hasMeasurements: false
        )

        #expect(routingService.initialRoute() == .introduction)
    }

    @Test
    func routesToFirstMeasurementWhenUserHasNoMeasurements() {
        let routingService = makeRoutingService(
            hasUsers: true,
            hasMeasurements: false
        )

        #expect(routingService.initialRoute() == .firstMeasurement)
    }

    @Test
    func completesOnboardingWhenUserHasMeasurements() {
        let routingService = makeRoutingService(
            hasUsers: true,
            hasMeasurements: true
        )

        #expect(routingService.initialRoute() == .onboardingComplete)
    }

    private func makeRoutingService(
        hasUsers: Bool,
        hasMeasurements: Bool
    ) -> PlanningInitialRoutingService {
        let repository = PlanningRepositoryStub(
            hasUsers: hasUsers,
            hasMeasurements: hasMeasurements
        )
        let planningService = PlanningService(repository: repository)
        return PlanningInitialRoutingService(planningService: planningService)
    }
}

private final class PlanningRepositoryStub: PlanningRepositoryProtocol {
    private let userResult: Bool
    private let measurementResult: Bool

    init(hasUsers: Bool, hasMeasurements: Bool) {
        userResult = hasUsers
        measurementResult = hasMeasurements
    }

    func createUser(name: String, birthday: Date) throws {}

    func hasUsers() throws -> Bool {
        userResult
    }

    func hasMeasurements() throws -> Bool {
        measurementResult
    }
}
