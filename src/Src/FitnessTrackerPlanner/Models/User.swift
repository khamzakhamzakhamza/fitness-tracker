import Foundation

public struct User: Equatable {
    public let id: String
    public let name: String?
    public let birthday: Date
    public let dateAdded: Date

    public init(
        id: String,
        name: String?,
        birthday: Date,
        dateAdded: Date
    ) {
        self.id = id
        self.name = name
        self.birthday = birthday
        self.dateAdded = dateAdded
    }
}
