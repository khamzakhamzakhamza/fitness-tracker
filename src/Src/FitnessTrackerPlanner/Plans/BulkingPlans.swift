public extension PlanDefinition {
    static let bulking12Weeks = bulkingPlan(
        id: "bulking-12-weeks",
        lengthInWeeks: 12
    )

    static let bulking24Weeks = bulkingPlan(
        id: "bulking-24-weeks",
        lengthInWeeks: 24
    )

    static let bulking48Weeks = bulkingPlan(
        id: "bulking-48-weeks",
        lengthInWeeks: 48
    )

    static let bulkingPlans = [
        bulking12Weeks,
        bulking24Weeks,
        bulking48Weeks
    ]

    private static func bulkingPlan(
        id: String,
        lengthInWeeks: Int
    ) -> PlanDefinition {
        let gainingWeeks = lengthInWeeks * 2 / 3
        let peakWeightDeltaSI = Double(gainingWeeks) * 500

        return PlanDefinition(
            id: id,
            name: "Bulking",
            lengthInWeeks: lengthInWeeks,
            weeks: (1...lengthInWeeks).map { week in
                let weightDeltaSI = if week <= gainingWeeks {
                    Double(week) * 500
                } else {
                    peakWeightDeltaSI
                        - Double(week - gainingWeeks) * 1_000
                }

                return PlanWeekValue(
                    week: week,
                    weightDeltaSI: weightDeltaSI,
                    locked: week == gainingWeeks
                )
            }
        )
    }
}
