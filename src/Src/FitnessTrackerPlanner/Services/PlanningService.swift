import Foundation

@MainActor
public protocol PlanningServiceProtocol {
    func fetchUser() throws -> User?
    func fetchMeasurements(amount: Int) throws -> [UserMeasurement]
}

@MainActor
public final class PlanningService: PlanningServiceProtocol {
    public static let shared = PlanningService()

    private let repository: any PlanningRepositoryProtocol

    public init(repository: any PlanningRepositoryProtocol = PlanningRepository.shared) {
        self.repository = repository
    }

    @discardableResult
    public func createUser(name: String, birthday: Date) -> Bool {
        do {
            try repository.createUser(name: name, birthday: birthday)
            return true
        } catch {
            return false
        }
    }

    @discardableResult
    public func createMeasurement(
        weightSI: Double,
        heightSI: Double,
        leanMass: Double,
        activityLevelID: Int
    ) -> Bool {
        do {
            try repository.createMeasurement(
                weightSI: weightSI,
                heightSI: heightSI,
                leanMass: leanMass,
                activityLevelID: activityLevelID
            )
            return true
        } catch {
            return false
        }
    }

    public func fetchUser() throws -> User? {
        try repository.fetchUser()
    }

    public func fetchMeasurements(amount: Int) throws -> [UserMeasurement] {
        try repository.fetchMeasurements(amount: amount)
    }
}
