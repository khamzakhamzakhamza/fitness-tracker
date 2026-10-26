import Foundation

public struct PlanMilestoneValue {
    public let date: Date
    public let targetWeightSI: Double

    public init(
        date: Date,
        targetWeightSI: Double
    ) {
        self.date = date
        self.targetWeightSI = targetWeightSI
    }
}
