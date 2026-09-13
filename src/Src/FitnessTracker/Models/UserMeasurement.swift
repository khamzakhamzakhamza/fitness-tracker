struct UserMeasurement {
    static let tableName = "UserMeasurements"

    let id: String
    let userID: String
    let weight: Double?
    let weightMeasurementUnitID: Int
    let height: Double?
    let heightMeasurementUnitID: Int
    let leanMass: Double?
    let activityLevelID: Int?
}
