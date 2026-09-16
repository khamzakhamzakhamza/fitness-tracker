public struct UserMeasurement: Equatable {
    public let id: String
    public let userID: String
    public let weightSI: Double
    public let heightSI: Double?
    public let leanMass: Double
    public let activityLevelID: Int

    public init(
        id: String,
        userID: String,
        weightSI: Double,
        heightSI: Double?,
        leanMass: Double,
        activityLevelID: Int
    ) {
        self.id = id
        self.userID = userID
        self.weightSI = weightSI
        self.heightSI = heightSI
        self.leanMass = leanMass
        self.activityLevelID = activityLevelID
    }
}
