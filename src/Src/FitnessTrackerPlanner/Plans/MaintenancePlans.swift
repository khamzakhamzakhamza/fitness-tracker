public extension PlanDefinition {
    static let maintenance12Weeks = maintenancePlan(
        id: "maintenance-12-weeks",
        lengthInWeeks: 12
    )

    static let maintenance24Weeks = maintenancePlan(
        id: "maintenance-24-weeks",
        lengthInWeeks: 24
    )

    static let maintenance48Weeks = maintenancePlan(
        id: "maintenance-48-weeks",
        lengthInWeeks: 48
    )

    static let maintenancePlans = [
        maintenance12Weeks,
        maintenance24Weeks,
        maintenance48Weeks
    ]

    private static func maintenancePlan(
        id: String,
        lengthInWeeks: Int
    ) -> PlanDefinition {
        PlanDefinition(
            id: id,
            name: "Maintenance",
            lengthInWeeks: lengthInWeeks,
            weeks: (1...lengthInWeeks).map {
                PlanWeekValue(
                    week: $0,
                    weightDeltaSI: 0
                )
            }
        )
    }
}
