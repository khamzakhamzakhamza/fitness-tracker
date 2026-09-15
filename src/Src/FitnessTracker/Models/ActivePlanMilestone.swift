import Foundation

struct ActivePlanMilestone {
    static let tableName = "ActivePlanMilestones"

    let id: String
    let planID: String
    let date: Date
    let targetWeightSI: Double
    let isActive: Bool
}
