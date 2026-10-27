public struct PlanValue {
    public let id: String
    public let name: String
    public let targetWeightSI: Double
    public let isActive: Bool

    public init(
        id: String,
        name: String,
        targetWeightSI: Double,
        isActive: Bool
    ) {
        self.id = id
        self.name = name
        self.targetWeightSI = targetWeightSI
        self.isActive = isActive
    }
}
