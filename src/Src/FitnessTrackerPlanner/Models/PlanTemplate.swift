import Foundation

public struct PlanTemplate: Identifiable, Equatable, Hashable {
    public let name: String
    public let lengthInWeeks: Int
    public let targetBMI: Double?

    public var id: String {
        name
    }

    public init(name: String, lengthInWeeks: Int, targetBMI: Double?) {
        self.name = name
        self.lengthInWeeks = lengthInWeeks
        self.targetBMI = targetBMI
    }

    public static let maintenance = PlanTemplate(
        name: "Maintenance",
        lengthInWeeks: 24,
        targetBMI: nil
    )

    public static let buildMuscle = PlanTemplate(
        name: "Build Muscle",
        lengthInWeeks: 24,
        targetBMI: 24.9
    )

    public static let loseWeight = PlanTemplate(
        name: "Lose Weight",
        lengthInWeeks: 24,
        targetBMI: 18.5
    )

    public static let preMadePlans = [
        maintenance,
        buildMuscle,
        loseWeight
    ]
}
