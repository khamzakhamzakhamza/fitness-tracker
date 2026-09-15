import Foundation
import SQLite3

public protocol PlanningRepositoryProtocol {
    func createUser(name: String, birthday: Date) throws
    func hasUsers() throws -> Bool
    func hasMeasurements() throws -> Bool
}

public final class PlanningRepository: PlanningRepositoryProtocol {
    public static let shared = PlanningRepository()

    public init() {}

    public func createUser(name: String, birthday: Date) throws {
        let databaseURL = try localDatabaseURL()
        var database: OpaquePointer?

        guard sqlite3_open_v2(
            databaseURL.path,
            &database,
            SQLITE_OPEN_READWRITE | SQLITE_OPEN_FULLMUTEX,
            nil
        ) == SQLITE_OK, let database else {
            throw PlanningRepositoryError.databaseOpenFailed
        }
        defer { sqlite3_close(database) }

        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(database, Constants.createUserQuery, -1, &statement, nil) == SQLITE_OK,
              let statement else {
            throw PlanningRepositoryError.userCreationFailed
        }
        defer { sqlite3_finalize(statement) }

        let userID = UUID().uuidString.lowercased()
        let birthdayTimestamp = Int64(birthday.timeIntervalSince1970)
        let dateAddedTimestamp = Int64(Date().timeIntervalSince1970)

        guard sqlite3_bind_text(statement, 1, userID, -1, sqliteTransient) == SQLITE_OK,
              sqlite3_bind_text(statement, 2, name, -1, sqliteTransient) == SQLITE_OK,
              sqlite3_bind_int64(statement, 3, birthdayTimestamp) == SQLITE_OK,
              sqlite3_bind_int64(statement, 4, dateAddedTimestamp) == SQLITE_OK,
              sqlite3_step(statement) == SQLITE_DONE else {
            throw PlanningRepositoryError.userCreationFailed
        }
    }

    public func hasUsers() throws -> Bool {
        try containsRecord(matching: Constants.hasUsersQuery)
    }

    public func hasMeasurements() throws -> Bool {
        try containsRecord(matching: Constants.hasMeasurementsQuery)
    }

    private func containsRecord(matching query: String) throws -> Bool {
        let databaseURL = try localDatabaseURL()
        var database: OpaquePointer?

        guard sqlite3_open_v2(
            databaseURL.path,
            &database,
            SQLITE_OPEN_READONLY | SQLITE_OPEN_FULLMUTEX,
            nil
        ) == SQLITE_OK, let database else {
            throw PlanningRepositoryError.databaseOpenFailed
        }
        defer { sqlite3_close(database) }

        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(database, query, -1, &statement, nil) == SQLITE_OK,
              let statement else {
            throw PlanningRepositoryError.stateCheckFailed
        }
        defer { sqlite3_finalize(statement) }

        guard sqlite3_step(statement) == SQLITE_ROW else {
            throw PlanningRepositoryError.stateCheckFailed
        }

        return sqlite3_column_int(statement, 0) == 1
    }

    private func localDatabaseURL() throws -> URL {
        guard let applicationSupportURL = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first else {
            throw PlanningRepositoryError.applicationSupportUnavailable
        }

        return applicationSupportURL
            .appendingPathComponent(Constants.databaseDirectory, isDirectory: true)
            .appendingPathComponent(Constants.databaseFileName)
    }
}

public enum PlanningRepositoryError: Error {
    case applicationSupportUnavailable
    case databaseOpenFailed
    case userCreationFailed
    case stateCheckFailed
}

private let sqliteTransient = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

private enum Constants {
    static let databaseDirectory = "FitnessTracker"
    static let databaseFileName = "local.sqlite"
    static let createUserQuery = """
        INSERT INTO \"User\" (id, name, birthday, dateAdded)
        VALUES (?, ?, ?, ?);
        """
    static let hasUsersQuery = "SELECT EXISTS(SELECT 1 FROM \"User\" LIMIT 1);"
    static let hasMeasurementsQuery = "SELECT EXISTS(SELECT 1 FROM UserMeasurements LIMIT 1);"
}
