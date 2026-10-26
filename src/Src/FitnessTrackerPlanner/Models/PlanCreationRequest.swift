public struct PlanCreationRequest {
    public let name: String
    public let milestones: [PlanMilestoneValue]

    public init(
        name: String,
        milestones: [PlanMilestoneValue]
    ) {
        self.name = name
        self.milestones = milestones
    }
}
