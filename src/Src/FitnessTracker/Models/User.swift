import Foundation

struct User {
    static let tableName = "User"

    let id: String
    let name: String?
    let birthday: Date
    let dateAdded: Date
}
