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
    func routesToPlanCreationWhenUserHasMeasurements() {
        let routingService = makeRoutingService(
            hasUsers: true,
            hasMeasurements: true
        )

        #expect(routingService.initialRoute() == .planCreation)
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

    func createMeasurement(
        weightSI: Double,
        heightSI: Double,
        leanMass: Double,
        activityLevelID: Int
    ) throws {}

    func fetchUser() throws -> User? {
        guard userResult else {
            return nil
        }

        return User(
            id: "user-id",
            name: "Test User",
            birthday: Date(timeIntervalSince1970: 0),
            dateAdded: Date(timeIntervalSince1970: 0)
        )
    }

    func fetchMeasurements(amount: Int) throws -> [UserMeasurement] {
        guard measurementResult, amount > 0 else {
            return []
        }

        return [
            UserMeasurement(
                id: "measurement-id",
                userID: "user-id",
                weightSI: 77_000,
                heightSI: 180,
                leanMass: 79,
                activityLevelID: 1
            )
        ]
    }
}
