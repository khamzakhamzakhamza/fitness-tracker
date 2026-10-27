public struct PlanProgressValue {
    public let plan: PlanValue
    public let milestones: [PlanMilestoneValue]

    public init(
        plan: PlanValue,
        milestones: [PlanMilestoneValue]
    ) {
        self.plan = plan
        self.milestones = milestones
    }
}
