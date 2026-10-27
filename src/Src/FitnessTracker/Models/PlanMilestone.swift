import Foundation

struct PlanMilestone {
    static let tableName = "PlanMilestones"

    let id: String
    let planID: String
    let date: Date
    let targetWeightSI: Double
}
