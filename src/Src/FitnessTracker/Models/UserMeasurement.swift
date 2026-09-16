struct UserMeasurement {
    static let tableName = "UserMeasurements"

    let id: String
    let userID: String
    let weightSI: Double
    let heightSI: Double?
    let leanMass: Double
    let activityLevelID: Int
}
