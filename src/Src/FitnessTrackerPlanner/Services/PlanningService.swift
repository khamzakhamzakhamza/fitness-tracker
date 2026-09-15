import Foundation

@MainActor
public protocol PlanningServiceProtocol {
    func hasUsers() throws -> Bool
    func hasMeasurements() throws -> Bool
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

    public func hasUsers() throws -> Bool {
        try repository.hasUsers()
    }

    public func hasMeasurements() throws -> Bool {
        try repository.hasMeasurements()
    }
}
