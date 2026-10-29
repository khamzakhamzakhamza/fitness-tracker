import Foundation

@MainActor
public protocol PlanningServiceProtocol {
    func createPlan(_ plan: PlanCreationRequest) -> Bool
    func hasActivePlan() throws -> Bool
    func fetchActivePlanProgress() throws -> PlanProgressValue?
    func fetchUser() throws -> User?
    func fetchMeasurements(amount: Int) throws -> [UserMeasurement]
    func fetchLatestDailyMeasurements(from startDate: Date) throws -> [UserMeasurement]
    func fetchLatestMeasurementFromLastWeek(referenceDate: Date) throws -> UserMeasurement?
    func deleteMeasurement(id: String) -> Bool
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

    public func fetchLatestDailyMeasurements(from startDate: Date) throws -> [UserMeasurement] {
        let calendar = Calendar.current
        let measurements = try repository.fetchMeasurements(from: startDate)
        var latestMeasurementByDay: [Date: UserMeasurement] = [:]

        for measurement in measurements {
            let day = calendar.startOfDay(for: measurement.dateAdded)

            if let currentLatest = latestMeasurementByDay[day],
               currentLatest.dateAdded >= measurement.dateAdded {
                continue
            }

            latestMeasurementByDay[day] = measurement
        }

        return latestMeasurementByDay.values.sorted {
            $0.dateAdded < $1.dateAdded
        }
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

    @discardableResult
    public func deleteMeasurement(id: String) -> Bool {
        do {
            try repository.deleteMeasurement(id: id)
            return true
        } catch {
            return false
        }
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
