import Foundation

@MainActor
public protocol PlanningServiceProtocol {
    func createPlan(_ plan: PlanCreationRequest) -> Bool
    func hasActivePlan() throws -> Bool
    func fetchActivePlanProgress() throws -> PlanProgressValue?
    func fetchUser() throws -> User?
    func fetchMeasurements(amount: Int) throws -> [UserMeasurement]
    func fetchLatestMeasurementFromLastWeek(referenceDate: Date) throws -> UserMeasurement?
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

    public func fetchLatestMeasurementFromLastWeek(
        referenceDate: Date = .now
    ) throws -> UserMeasurement? {
        let calendar = Calendar.current

        guard let currentWeek = calendar.dateInterval(
            of: .weekOfYear,
            for: referenceDate
        ),
        let previousWeekStart = calendar.date(
            byAdding: .weekOfYear,
            value: -1,
            to: currentWeek.start
        ) else {
            return nil
        }

        return try repository.fetchLatestMeasurement(
            from: previousWeekStart,
            to: currentWeek.start
        )
    }

    public func hasActivePlan() throws -> Bool {
        try repository.hasActivePlan()
    }

    public func fetchActivePlanProgress() throws -> PlanProgressValue? {
        guard let plan = try repository.fetchActivePlan() else {
            return nil
        }

        return PlanProgressValue(
            plan: plan,
            milestones: try repository.fetchPlanMilestones(planID: plan.id)
        )
    }

    @discardableResult
    public func createPlan(_ plan: PlanCreationRequest) -> Bool {
        do {
            try repository.createPlan(plan)
            return true
        } catch {
            return false
        }
    }
}
