import Foundation

@MainActor
public final class PlanningService {
    public static let shared = PlanningService()

    private let repository: PlanningRepository

    public init(repository: PlanningRepository = .shared) {
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
}
