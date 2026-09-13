import Foundation
import SQLite3

enum LocalDatabaseError: LocalizedError {
    case applicationSupportUnavailable
    case directoryCreationFailed(String)
    case databaseOpenFailed(String)
    case schemaCreationFailed(String)
    case insertPreparationFailed(String)
    case insertBindingFailed(String)
    case insertFailed(String)
    case queryPreparationFailed(String)
    case queryBindingFailed(String)
    case queryFailed(String)
    case deletePreparationFailed(String)
    case deleteBindingFailed(String)
    case deleteFailed(String)

    var errorDescription: String? {
        switch self {
        case .applicationSupportUnavailable:
            "Could not find the app's local storage folder."
        case .directoryCreationFailed(let message):
            "Could not create the local storage folder: \(message)"
        case .databaseOpenFailed(let message):
            "Could not open the local database: \(message)"
        case .schemaCreationFailed(let message):
            "Could not create the nutrition log table: \(message)"
        case .insertPreparationFailed(let message):
            "Could not prepare the nutrition log: \(message)"
        case .insertBindingFailed(let message):
            "Could not bind the nutrition log values: \(message)"
        case .insertFailed(let message):
            "Could not save the nutrition log: \(message)"
        case .queryPreparationFailed(let message):
            "Could not prepare the nutrition logs query: \(message)"
        case .queryBindingFailed(let message):
            "Could not bind the nutrition logs query: \(message)"
        case .queryFailed(let message):
            "Could not read nutrition logs: \(message)"
        case .deletePreparationFailed(let message):
            "Could not prepare the nutrition log deletion: \(message)"
        case .deleteBindingFailed(let message):
            "Could not bind the nutrition log deletion: \(message)"
        case .deleteFailed(let message):
            "Could not delete the nutrition log: \(message)"
        }
    }
}

protocol LocalDatabaseRepositoryProtocol: Sendable {
    func initializeDatabase() async throws

    func addNutritionLog(
        foodID: String,
        date: String,
        time: String
    ) async throws -> NutritionLogItem

    func nutritionLogs(date: String) async throws -> [NutritionLogItem]

    func deleteNutritionLog(id: Int64) async throws
}

actor LocalDatabaseRepository: LocalDatabaseRepositoryProtocol {
    private static let gramsMeasurementUnitID =
        "11111111-1111-1111-1111-111111111111"
    private static let centimetresMeasurementUnitID =
        "22222222-2222-2222-2222-222222222222"

    private let customDatabaseURL: URL?

    init(databaseURL: URL? = nil) {
        customDatabaseURL = databaseURL
    }

    func initializeDatabase() throws {
        let database = try openDatabase()
        defer { sqlite3_close(database) }
        try createSchema(in: database)
    }

    func addNutritionLog(
        foodID: String,
        date: String,
        time: String
    ) throws -> NutritionLogItem {
        let database = try openDatabase()
        defer { sqlite3_close(database) }
        try createSchema(in: database)

        let sql = """
            INSERT INTO NutritionLogs (foodId, date, time)
            VALUES (?, ?, ?)
            """
        var statement: OpaquePointer?

        guard sqlite3_prepare_v2(
            database,
            sql,
            -1,
            &statement,
            nil
        ) == SQLITE_OK else {
            throw LocalDatabaseError.insertPreparationFailed(
                databaseErrorMessage(database)
            )
        }
        defer { sqlite3_finalize(statement) }

        guard
            bindText(foodID, to: statement, index: 1) == SQLITE_OK,
            bindText(date, to: statement, index: 2) == SQLITE_OK,
            bindText(time, to: statement, index: 3) == SQLITE_OK
        else {
            throw LocalDatabaseError.insertBindingFailed(
                databaseErrorMessage(database)
            )
        }

        guard sqlite3_step(statement) == SQLITE_DONE else {
            throw LocalDatabaseError.insertFailed(
                databaseErrorMessage(database)
            )
        }

        return NutritionLogItem(
            id: sqlite3_last_insert_rowid(database),
            foodID: foodID,
            date: date,
            time: time
        )
    }

    func nutritionLogs(date: String) throws -> [NutritionLogItem] {
        let database = try openDatabase()
        defer { sqlite3_close(database) }
        try createSchema(in: database)

        let sql = """
            SELECT id, foodId, date, time
            FROM NutritionLogs
            WHERE date = ?
            ORDER BY time, id
            """
        var statement: OpaquePointer?

        guard sqlite3_prepare_v2(
            database,
            sql,
            -1,
            &statement,
            nil
        ) == SQLITE_OK else {
            throw LocalDatabaseError.queryPreparationFailed(
                databaseErrorMessage(database)
            )
        }
        defer { sqlite3_finalize(statement) }

        guard bindText(date, to: statement, index: 1) == SQLITE_OK else {
            throw LocalDatabaseError.queryBindingFailed(
                databaseErrorMessage(database)
            )
        }

        var logs: [NutritionLogItem] = []
        while true {
            switch sqlite3_step(statement) {
            case SQLITE_ROW:
                logs.append(
                    NutritionLogItem(
                        id: sqlite3_column_int64(statement, 0),
                        foodID: stringValue(in: statement, column: 1),
                        date: stringValue(in: statement, column: 2),
                        time: stringValue(in: statement, column: 3)
                    )
                )
            case SQLITE_DONE:
                return logs
            default:
                throw LocalDatabaseError.queryFailed(
                    databaseErrorMessage(database)
                )
            }
        }
    }

    func deleteNutritionLog(id: Int64) throws {
        let database = try openDatabase()
        defer { sqlite3_close(database) }
        try createSchema(in: database)

        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(
            database,
            "DELETE FROM NutritionLogs WHERE id = ?",
            -1,
            &statement,
            nil
        ) == SQLITE_OK else {
            throw LocalDatabaseError.deletePreparationFailed(
                databaseErrorMessage(database)
            )
        }
        defer { sqlite3_finalize(statement) }

        guard sqlite3_bind_int64(statement, 1, id) == SQLITE_OK else {
            throw LocalDatabaseError.deleteBindingFailed(
                databaseErrorMessage(database)
            )
        }

        guard sqlite3_step(statement) == SQLITE_DONE else {
            throw LocalDatabaseError.deleteFailed(
                databaseErrorMessage(database)
            )
        }
    }

    private func openDatabase() throws -> OpaquePointer {
        let databaseURL = try resolvedDatabaseURL()
        var database: OpaquePointer?
        let result = sqlite3_open_v2(
            databaseURL.path,
            &database,
            SQLITE_OPEN_CREATE | SQLITE_OPEN_READWRITE | SQLITE_OPEN_FULLMUTEX,
            nil
        )

        guard result == SQLITE_OK, let database else {
            let message = database.map(databaseErrorMessage)
                ?? "Unknown SQLite error"
            if let database {
                sqlite3_close(database)
            }
            throw LocalDatabaseError.databaseOpenFailed(message)
        }

        return database
    }

    private func resolvedDatabaseURL() throws -> URL {
        if let customDatabaseURL {
            return customDatabaseURL
        }

        guard let applicationSupportURL = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first else {
            throw LocalDatabaseError.applicationSupportUnavailable
        }

        let directoryURL = applicationSupportURL.appendingPathComponent(
            "FitnessTracker",
            isDirectory: true
        )

        do {
            try FileManager.default.createDirectory(
                at: directoryURL,
                withIntermediateDirectories: true
            )
        } catch {
            throw LocalDatabaseError.directoryCreationFailed(
                error.localizedDescription
            )
        }

        return directoryURL.appendingPathComponent("local.sqlite")
    }

    private func createSchema(in database: OpaquePointer) throws {
        try migrateLegacyMeasurementUnitsSchema(in: database)
        try migrateLegacyUserMeasurementsSchema(in: database)

        let sql = """
            PRAGMA foreign_keys = ON;

            CREATE TABLE IF NOT EXISTS NutritionLogs (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                foodId TEXT NOT NULL,
                date TEXT NOT NULL,
                time TEXT NOT NULL
            );
            CREATE INDEX IF NOT EXISTS nutrition_logs_date_idx
                ON NutritionLogs (date);

            CREATE TABLE IF NOT EXISTS MeasurementUnits (
                id TEXT PRIMARY KEY,
                name TEXT NOT NULL UNIQUE,
                shortName TEXT NOT NULL UNIQUE,
                pluralForm TEXT,
                siConversionValue REAL,
                dateAdded INTEGER NOT NULL
            );

            INSERT OR IGNORE INTO MeasurementUnits (
                id,
                name,
                shortName,
                pluralForm,
                siConversionValue,
                dateAdded
            ) VALUES
                ('\(Self.gramsMeasurementUnitID)', 'gram', 'g', 'grams', 1, strftime('%s', 'now')),
                ('\(Self.centimetresMeasurementUnitID)', 'centimetre', 'cm', 'centimetres', NULL, strftime('%s', 'now'));

            CREATE TABLE IF NOT EXISTS "User" (
                id TEXT PRIMARY KEY,
                name TEXT,
                birthday INTEGER NOT NULL,
                dateAdded INTEGER NOT NULL
            );

            CREATE TABLE IF NOT EXISTS UserMeasurements (
                id TEXT PRIMARY KEY,
                userId TEXT NOT NULL,
                weight REAL,
                weightMeasurementUnitId TEXT NOT NULL
                    DEFAULT '\(Self.gramsMeasurementUnitID)',
                height REAL,
                heightMeasurementUnitId TEXT NOT NULL
                    DEFAULT '\(Self.centimetresMeasurementUnitID)',
                leanMass REAL,
                FOREIGN KEY (userId) REFERENCES "User" (id),
                FOREIGN KEY (weightMeasurementUnitId) REFERENCES MeasurementUnits (id),
                FOREIGN KEY (heightMeasurementUnitId) REFERENCES MeasurementUnits (id)
            );
            CREATE INDEX IF NOT EXISTS user_measurements_user_id_idx
                ON UserMeasurements (userId);
            """

        guard sqlite3_exec(database, sql, nil, nil, nil) == SQLITE_OK else {
            throw LocalDatabaseError.schemaCreationFailed(
                databaseErrorMessage(database)
            )
        }
    }

    private func migrateLegacyMeasurementUnitsSchema(
        in database: OpaquePointer
    ) throws {
        let columnCheckSQL = """
            SELECT COUNT(*)
            FROM pragma_table_info('MeasurementUnits')
            WHERE name = 'gramConvertionValue'
            """
        var statement: OpaquePointer?

        guard sqlite3_prepare_v2(
            database,
            columnCheckSQL,
            -1,
            &statement,
            nil
        ) == SQLITE_OK else {
            throw LocalDatabaseError.schemaCreationFailed(
                databaseErrorMessage(database)
            )
        }
        defer { sqlite3_finalize(statement) }

        guard sqlite3_step(statement) == SQLITE_ROW else {
            throw LocalDatabaseError.schemaCreationFailed(
                databaseErrorMessage(database)
            )
        }

        guard sqlite3_column_int(statement, 0) > 0 else {
            return
        }

        let migrationSQL = """
            ALTER TABLE MeasurementUnits
            RENAME COLUMN gramConvertionValue TO siConversionValue
            """
        guard sqlite3_exec(database, migrationSQL, nil, nil, nil) == SQLITE_OK else {
            throw LocalDatabaseError.schemaCreationFailed(
                databaseErrorMessage(database)
            )
        }
    }

    private func migrateLegacyUserMeasurementsSchema(
        in database: OpaquePointer
    ) throws {
        let columnCheckSQL = """
            SELECT COUNT(*)
            FROM pragma_table_info('UserMeasurements')
            WHERE name = 'leanMassMeasurementUnitId'
            """
        var statement: OpaquePointer?

        guard sqlite3_prepare_v2(
            database,
            columnCheckSQL,
            -1,
            &statement,
            nil
        ) == SQLITE_OK else {
            throw LocalDatabaseError.schemaCreationFailed(
                databaseErrorMessage(database)
            )
        }
        defer { sqlite3_finalize(statement) }

        guard sqlite3_step(statement) == SQLITE_ROW else {
            throw LocalDatabaseError.schemaCreationFailed(
                databaseErrorMessage(database)
            )
        }

        guard sqlite3_column_int(statement, 0) > 0 else {
            return
        }

        let migrationSQL = """
            BEGIN TRANSACTION;
            CREATE TABLE UserMeasurementsReplacement (
                id TEXT PRIMARY KEY,
                userId TEXT NOT NULL,
                weight REAL,
                weightMeasurementUnitId TEXT NOT NULL
                    DEFAULT '\(Self.gramsMeasurementUnitID)',
                height REAL,
                heightMeasurementUnitId TEXT NOT NULL
                    DEFAULT '\(Self.centimetresMeasurementUnitID)',
                leanMass REAL,
                FOREIGN KEY (userId) REFERENCES "User" (id),
                FOREIGN KEY (weightMeasurementUnitId) REFERENCES MeasurementUnits (id),
                FOREIGN KEY (heightMeasurementUnitId) REFERENCES MeasurementUnits (id)
            );
            INSERT INTO UserMeasurementsReplacement (
                id,
                userId,
                weight,
                weightMeasurementUnitId,
                height,
                heightMeasurementUnitId,
                leanMass
            )
            SELECT
                id,
                userId,
                weight,
                weightMeasurementUnitId,
                height,
                heightMeasurementUnitId,
                leanMass
            FROM UserMeasurements;
            DROP TABLE UserMeasurements;
            ALTER TABLE UserMeasurementsReplacement RENAME TO UserMeasurements;
            CREATE INDEX user_measurements_user_id_idx
                ON UserMeasurements (userId);
            COMMIT;
            """
        guard sqlite3_exec(database, migrationSQL, nil, nil, nil) == SQLITE_OK else {
            throw LocalDatabaseError.schemaCreationFailed(
                databaseErrorMessage(database)
            )
        }
    }

    private func bindText(
        _ value: String,
        to statement: OpaquePointer?,
        index: Int32
    ) -> Int32 {
        let sqliteTransient = unsafeBitCast(
            -1,
            to: sqlite3_destructor_type.self
        )

        return value.withCString { pointer in
            sqlite3_bind_text(
                statement,
                index,
                pointer,
                -1,
                sqliteTransient
            )
        }
    }

    private func databaseErrorMessage(_ database: OpaquePointer) -> String {
        String(cString: sqlite3_errmsg(database))
    }

    private func stringValue(
        in statement: OpaquePointer?,
        column: Int32
    ) -> String {
        guard let value = sqlite3_column_text(statement, column) else {
            return ""
        }
        return String(cString: value)
    }
}
