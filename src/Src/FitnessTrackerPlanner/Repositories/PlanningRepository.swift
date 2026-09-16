import Foundation
import SQLite3

public protocol PlanningRepositoryProtocol {
    func createUser(name: String, birthday: Date) throws
    func createMeasurement(
        weightSI: Double,
        heightSI: Double,
        leanMass: Double,
        activityLevelID: Int
    ) throws
    func fetchUser() throws -> User?
    func fetchMeasurements(amount: Int) throws -> [UserMeasurement]
}

public final class PlanningRepository: PlanningRepositoryProtocol {
    public static let shared = PlanningRepository()

    public init() {}

    public func createUser(name: String, birthday: Date) throws {
        try withDatabase(readOnly: false) { database in
            try withStatement(Constants.createUserQuery, in: database) { statement in
                let userID = UUID().uuidString.lowercased()
                let birthdayTimestamp = Int64(birthday.timeIntervalSince1970)
                let dateAddedTimestamp = Int64(Date().timeIntervalSince1970)

                guard sqlite3_bind_text(statement, 1, userID, -1, sqliteTransient) == SQLITE_OK,
                      sqlite3_bind_text(statement, 2, name, -1, sqliteTransient) == SQLITE_OK,
                      sqlite3_bind_int64(statement, 3, birthdayTimestamp) == SQLITE_OK,
                      sqlite3_bind_int64(statement, 4, dateAddedTimestamp) == SQLITE_OK,
                      sqlite3_step(statement) == SQLITE_DONE else {
                    throw PlanningRepositoryError.databaseOperationFailed
                }
            }
        }
    }

    public func createMeasurement(
        weightSI: Double,
        heightSI: Double,
        leanMass: Double,
        activityLevelID: Int
    ) throws {
        try withDatabase(readOnly: false) { database in
            try withStatement(Constants.createMeasurementQuery, in: database) { statement in
                let measurementID = UUID().uuidString.lowercased()

                guard sqlite3_bind_text(statement, 1, measurementID, -1, sqliteTransient) == SQLITE_OK,
                      sqlite3_bind_double(statement, 2, weightSI) == SQLITE_OK,
                      sqlite3_bind_double(statement, 3, heightSI) == SQLITE_OK,
                      sqlite3_bind_double(statement, 4, leanMass) == SQLITE_OK,
                      sqlite3_bind_int(statement, 5, Int32(activityLevelID)) == SQLITE_OK,
                      sqlite3_step(statement) == SQLITE_DONE,
                      sqlite3_changes(database) == 1 else {
                    throw PlanningRepositoryError.databaseOperationFailed
                }
            }
        }
    }

    public func fetchUser() throws -> User? {
        return try withDatabase(readOnly: true) { database in
            try withStatement(Constants.fetchUserQuery, in: database) { statement in
                switch sqlite3_step(statement) {
                case SQLITE_ROW:
                    return User(
                        id: String(cString: sqlite3_column_text(statement, 0)),
                        name: String(cString: sqlite3_column_text(statement, 1)),
                        birthday: Date(timeIntervalSince1970: Double(sqlite3_column_int64(statement, 2))),
                        dateAdded: Date(timeIntervalSince1970: Double(sqlite3_column_int64(statement, 3)))
                    )
                case SQLITE_DONE:
                    return nil
                default:
                    throw PlanningRepositoryError.databaseOperationFailed
                }
            }
        }
    }

    public func fetchMeasurements(amount: Int) throws -> [UserMeasurement] {
        guard amount > 0 else {
            return []
        }

        return try withDatabase(readOnly: true) { database in
            try withStatement(Constants.fetchMeasurementsQuery, in: database) { statement in
                guard sqlite3_bind_int64(statement, 1, Int64(amount)) == SQLITE_OK else {
                    throw PlanningRepositoryError.databaseOperationFailed
                }

                var measurements: [UserMeasurement] = []

                while true {
                    switch sqlite3_step(statement) {
                    case SQLITE_ROW:
                        guard let idText = sqlite3_column_text(statement, 0),
                              let userIDText = sqlite3_column_text(statement, 1) else {
                            throw PlanningRepositoryError.databaseOperationFailed
                        }

                        let heightSI = sqlite3_column_type(statement, 3) == SQLITE_NULL
                            ? nil
                            : sqlite3_column_double(statement, 3)

                        measurements.append(
                            UserMeasurement(
                                id: String(cString: idText),
                                userID: String(cString: userIDText),
                                weightSI: sqlite3_column_double(statement, 2),
                                heightSI: heightSI,
                                leanMass: sqlite3_column_double(statement, 4),
                                activityLevelID: Int(sqlite3_column_int(statement, 5))
                            )
                        )
                    case SQLITE_DONE:
                        return measurements
                    default:
                        throw PlanningRepositoryError.databaseOperationFailed
                    }
                }
            }
        }
    }

    private func withDatabase<Result>(
        readOnly: Bool,
        operation: (OpaquePointer) throws -> Result
    ) throws -> Result {
        let databaseURL = try localDatabaseURL()
        var database: OpaquePointer?
        let accessMode = readOnly ? SQLITE_OPEN_READONLY : SQLITE_OPEN_READWRITE

        guard sqlite3_open_v2(
            databaseURL.path,
            &database,
            accessMode | SQLITE_OPEN_FULLMUTEX,
            nil
        ) == SQLITE_OK, let database else {
            throw PlanningRepositoryError.databaseOpenFailed
        }
        defer { sqlite3_close(database) }

        return try operation(database)
    }

    private func withStatement<Result>(
        _ query: String,
        in database: OpaquePointer,
        operation: (OpaquePointer) throws -> Result
    ) throws -> Result {
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(database, query, -1, &statement, nil) == SQLITE_OK,
              let statement else {
            throw PlanningRepositoryError.databaseOperationFailed
        }
        defer { sqlite3_finalize(statement) }

        return try operation(statement)
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
    case databaseOperationFailed
}

private let sqliteTransient = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

private enum Constants {
    static let databaseDirectory = "FitnessTracker"
    static let databaseFileName = "local.sqlite"
    static let createUserQuery = """
        INSERT INTO \"User\" (id, name, birthday, dateAdded)
        VALUES (?, ?, ?, ?);
        """
    static let fetchMeasurementsQuery = """
        SELECT id, userId, weightSI, heightSI, leanMass, activityLevelId
        FROM UserMeasurements
        ORDER BY rowid DESC
        LIMIT ?;
        """
    static let createMeasurementQuery = """
        INSERT INTO UserMeasurements (
            id,
            userId,
            weightSI,
            heightSI,
            leanMass,
            activityLevelId
        )
        SELECT ?, id, ?, ?, ?, ?
        FROM "User"
        ORDER BY dateAdded DESC
        LIMIT 1;
        """
    static let fetchUserQuery = """
        SELECT id, name, birthday, dateAdded
        FROM \"User\"
        ORDER BY dateAdded DESC
        LIMIT 1;
        """
}
