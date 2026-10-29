import Foundation

public struct UserMeasurement: Equatable {
    public let id: String
    public let userID: String
    public let weightSI: Double
    public let heightSI: Double?
    public let leanMass: Double
    public let activityLevelID: Int
    public let dateAdded: Date

    public init(
        id: String,
        userID: String,
        weightSI: Double,
        heightSI: Double?,
        leanMass: Double,
        activityLevelID: Int,
        dateAdded: Date
    ) {
        self.id = id
        self.userID = userID
        self.weightSI = weightSI
        self.heightSI = heightSI
        self.leanMass = leanMass
        self.activityLevelID = activityLevelID
        self.dateAdded = dateAdded
    }
}
