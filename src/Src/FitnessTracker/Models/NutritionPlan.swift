struct NutritionPlan {
    static let tableName = "NutritionPlans"

    let id: String
    let planTypeID: Int
    let userMeasurementID: String
    let targetWeightSI: Double
}
