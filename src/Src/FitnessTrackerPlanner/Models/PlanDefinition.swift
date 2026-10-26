public struct PlanDefinition {
    public let id: String
    public let name: String
    public let lengthInWeeks: Int
    public let weeks: [PlanWeekValue]

    public init(
        id: String,
        name: String,
        lengthInWeeks: Int,
        weeks: [PlanWeekValue]
    ) {
        self.id = id
        self.name = name
        self.lengthInWeeks = lengthInWeeks
        self.weeks = weeks
    }
}

public struct PlanWeekValue {
    public let week: Int
    public let weightDeltaSI: Double
    public let locked: Bool

    public init(
        week: Int,
        weightDeltaSI: Double,
        locked: Bool
    ) {
        self.week = week
        self.weightDeltaSI = weightDeltaSI
        self.locked = locked
    }
}
