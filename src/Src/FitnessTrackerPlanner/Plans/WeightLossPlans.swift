public extension PlanDefinition {
    static let weightLoss12Weeks = weightLossPlan(
        id: "weight-loss-12-weeks",
        lengthInWeeks: 12
    )

    static let weightLoss24Weeks = weightLossPlan(
        id: "weight-loss-24-weeks",
        lengthInWeeks: 24
    )

    static let weightLoss48Weeks = weightLossPlan(
        id: "weight-loss-48-weeks",
        lengthInWeeks: 48
    )

    static let weightLossPlans = [
        weightLoss12Weeks,
        weightLoss24Weeks,
        weightLoss48Weeks
    ]

    private static func weightLossPlan(
        id: String,
        lengthInWeeks: Int
    ) -> PlanDefinition {
        PlanDefinition(
            id: id,
            name: "Weight Loss",
            lengthInWeeks: lengthInWeeks,
            weeks: (1...lengthInWeeks).map { week in
                PlanWeekValue(
                    week: week,
                    weightDeltaSI: Double(week) * -500,
                    locked: false
                )
            }
        )
    }
}
