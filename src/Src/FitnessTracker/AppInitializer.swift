import Foundation
import SQLite3

@MainActor
final class AppInitializer {
    private(set) var initializationError: Error?

    func initialize() {
        do {
            try LocalDatabaseInitializer().initialize()
        } catch {
            initializationError = error
        }
    }
}

private struct LocalDatabaseInitializer {
    private let activityLevels = [
        ActivityLevel(id: 1, name: "Sedentary", calorieMultiplier: 1.2, description: "desk job, no training"),
        ActivityLevel(id: 2, name: "Light", calorieMultiplier: 1.375, description: "1–3 sessions a week"),
        ActivityLevel(id: 3, name: "Moderate", calorieMultiplier: 1.55, description: "3–5 sessions a week"),
        ActivityLevel(id: 4, name: "Heavy", calorieMultiplier: 1.725, description: "6–7 sessions a week"),
        ActivityLevel(id: 5, name: "Athlete", calorieMultiplier: 1.9, description: "training twice a day")
    ]

    private let heightMeasurementUnits = [
        HeightMeasurementUnit(
            id: 1,
            name: "Centimetres",
            shortName: "cm",
            siConversionValue: 1,
            isDefault: true
        ),
        HeightMeasurementUnit(
            id: 2,
            name: "Feet",
            shortName: "ft",
            siConversionValue: 30.48,
            isDefault: false
        )
    ]

    private let weightMeasurementUnits = [
        WeightMeasurementUnit(
            id: 1,
            name: "Kilograms",
            shortName: "kg",
            siConversionValue: 1_000,
            isDefault: true
        ),
        WeightMeasurementUnit(
            id: 2,
            name: "Pounds",
            shortName: "lb",
            siConversionValue: 453.59237,
            isDefault: false
        )
    ]

    func initialize() throws {
        let databaseURL = try databaseURL()
        var database: OpaquePointer?

        guard sqlite3_open_v2(
            databaseURL.path,
            &database,
            SQLITE_OPEN_CREATE | SQLITE_OPEN_READWRITE | SQLITE_OPEN_FULLMUTEX,
            nil
        ) == SQLITE_OK, let database else {
            throw LocalDatabaseInitializationError.openFailed
        }
        defer { sqlite3_close(database) }

        let schema = """
            PRAGMA foreign_keys = ON;

            CREATE TABLE IF NOT EXISTS \(NutritionLog.tableName) (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                foodId TEXT NOT NULL,
                date TEXT NOT NULL,
                time TEXT NOT NULL
            );
            CREATE INDEX IF NOT EXISTS nutrition_logs_date_idx ON \(NutritionLog.tableName) (date);

            CREATE TABLE IF NOT EXISTS \(ActivityLevel.tableName) (
                id INTEGER PRIMARY KEY,
                name TEXT NOT NULL UNIQUE,
                calorieMultiplier REAL NOT NULL,
                description TEXT NOT NULL,
                dateAdded INTEGER NOT NULL
            );

            CREATE TABLE IF NOT EXISTS \(HeightMeasurementUnit.tableName) (
                id INTEGER PRIMARY KEY,
                name TEXT NOT NULL UNIQUE,
                shortName TEXT NOT NULL UNIQUE,
                siConversionValue REAL NOT NULL,
                isDefault INTEGER NOT NULL CHECK (isDefault IN (0, 1)),
                dateAdded INTEGER NOT NULL
            );

            CREATE TABLE IF NOT EXISTS \(WeightMeasurementUnit.tableName) (
                id INTEGER PRIMARY KEY,
                name TEXT NOT NULL UNIQUE,
                shortName TEXT NOT NULL UNIQUE,
                siConversionValue REAL NOT NULL,
                isDefault INTEGER NOT NULL CHECK (isDefault IN (0, 1)),
                dateAdded INTEGER NOT NULL
            );

            CREATE TABLE IF NOT EXISTS "\(User.tableName)" (
                id TEXT PRIMARY KEY,
                name TEXT,
                birthday INTEGER NOT NULL,
                dateAdded INTEGER NOT NULL
            );

            CREATE TABLE IF NOT EXISTS \(UserMeasurement.tableName) (
                id TEXT PRIMARY KEY,
                userId TEXT NOT NULL,
                weightSI REAL NOT NULL,
                heightSI REAL,
                leanMass REAL NOT NULL,
                activityLevelId INTEGER NOT NULL,
                FOREIGN KEY (userId) REFERENCES "\(User.tableName)" (id),
                FOREIGN KEY (activityLevelId) REFERENCES \(ActivityLevel.tableName) (id)
            );
            CREATE INDEX IF NOT EXISTS user_measurements_user_id_idx ON \(UserMeasurement.tableName) (userId);

            CREATE TABLE IF NOT EXISTS \(Plan.tableName) (
                id TEXT PRIMARY KEY,
                name TEXT NOT NULL,
                targetWeightSI REAL NOT NULL
            );

            CREATE TABLE IF NOT EXISTS \(ActivePlanMilestone.tableName) (
                id TEXT PRIMARY KEY,
                planId TEXT NOT NULL,
                date INTEGER NOT NULL,
                targetWeightSI REAL NOT NULL,
                isActive INTEGER NOT NULL CHECK (isActive IN (0, 1)),
                FOREIGN KEY (planId) REFERENCES \(Plan.tableName) (id)
            );
            CREATE INDEX IF NOT EXISTS active_plan_milestones_date_idx ON \(ActivePlanMilestone.tableName) (date);
            """

        guard sqlite3_exec(database, schema, nil, nil, nil) == SQLITE_OK else {
            throw LocalDatabaseInitializationError.schemaCreationFailed
        }

        try migrateUserMeasurementsIfNeeded(in: database)
        try removeLegacyMeasurementUnits(in: database)
        try seedLookupTables(in: database)
    }

    private func removeLegacyMeasurementUnits(in database: OpaquePointer) throws {
        guard sqlite3_exec(database, "DROP TABLE IF EXISTS MeasurementUnits;", nil, nil, nil) == SQLITE_OK else {
            throw LocalDatabaseInitializationError.schemaMigrationFailed
        }
    }

    private func migrateUserMeasurementsIfNeeded(in database: OpaquePointer) throws {
        guard try tableHasColumn("weight", in: UserMeasurement.tableName, database: database),
              !(try tableHasColumn("weightSI", in: UserMeasurement.tableName, database: database)) else {
            return
        }

        let migration = """
            PRAGMA foreign_keys = OFF;
            BEGIN TRANSACTION;
            CREATE TABLE UserMeasurementsReplacement (
                id TEXT PRIMARY KEY,
                userId TEXT NOT NULL,
                weightSI REAL NOT NULL,
                heightSI REAL,
                leanMass REAL NOT NULL,
                activityLevelId INTEGER NOT NULL,
                FOREIGN KEY (userId) REFERENCES "\(User.tableName)" (id),
                FOREIGN KEY (activityLevelId) REFERENCES \(ActivityLevel.tableName) (id)
            );
            INSERT INTO UserMeasurementsReplacement (
                id,
                userId,
                weightSI,
                heightSI,
                leanMass,
                activityLevelId
            )
            SELECT
                id,
                userId,
                COALESCE(weight, 0),
                height,
                COALESCE(leanMass, 0),
                COALESCE(activityLevelId, 1)
            FROM \(UserMeasurement.tableName);
            DROP TABLE \(UserMeasurement.tableName);
            ALTER TABLE UserMeasurementsReplacement RENAME TO \(UserMeasurement.tableName);
            CREATE INDEX user_measurements_user_id_idx ON \(UserMeasurement.tableName) (userId);
            COMMIT;
            PRAGMA foreign_keys = ON;
            """

        guard sqlite3_exec(database, migration, nil, nil, nil) == SQLITE_OK else {
            throw LocalDatabaseInitializationError.schemaMigrationFailed
        }
    }

    private func tableHasColumn(
        _ columnName: String,
        in tableName: String,
        database: OpaquePointer
    ) throws -> Bool {
        var statement: OpaquePointer?
        let query = """
            SELECT EXISTS(
                SELECT 1 FROM pragma_table_info('\(tableName)')
                WHERE name = '\(columnName.replacingOccurrences(of: "'", with: "''"))'
                LIMIT 1
            );
            """

        guard sqlite3_prepare_v2(database, query, -1, &statement, nil) == SQLITE_OK,
              let statement else {
            throw LocalDatabaseInitializationError.schemaMigrationFailed
        }
        defer { sqlite3_finalize(statement) }

        guard sqlite3_step(statement) == SQLITE_ROW else {
            throw LocalDatabaseInitializationError.schemaMigrationFailed
        }

        return sqlite3_column_int(statement, 0) == 1
    }

    private func seedLookupTables(in database: OpaquePointer) throws {
        let dateAdded = Int(Date().timeIntervalSince1970)

        for level in activityLevels {
            try execute(
                """
                INSERT OR IGNORE INTO \(ActivityLevel.tableName)
                    (id, name, calorieMultiplier, description, dateAdded)
                VALUES
                    (\(level.id), \(sqlString(level.name)), \(level.calorieMultiplier), \(sqlString(level.description)), \(dateAdded));
                """,
                in: database
            )
        }

        for unit in heightMeasurementUnits {
            try execute(
                """
                INSERT OR IGNORE INTO \(HeightMeasurementUnit.tableName)
                    (id, name, shortName, siConversionValue, isDefault, dateAdded)
                VALUES
                    (\(unit.id), \(sqlString(unit.name)), \(sqlString(unit.shortName)), \(unit.siConversionValue), \(unit.isDefault ? 1 : 0), \(dateAdded));
                """,
                in: database
            )
        }

        for unit in weightMeasurementUnits {
            try execute(
                """
                INSERT OR IGNORE INTO \(WeightMeasurementUnit.tableName)
                    (id, name, shortName, siConversionValue, isDefault, dateAdded)
                VALUES
                    (\(unit.id), \(sqlString(unit.name)), \(sqlString(unit.shortName)), \(unit.siConversionValue), \(unit.isDefault ? 1 : 0), \(dateAdded));
                """,
                in: database
            )
        }

    }

    private func execute(_ sql: String, in database: OpaquePointer) throws {
        guard sqlite3_exec(database, sql, nil, nil, nil) == SQLITE_OK else {
            throw LocalDatabaseInitializationError.lookupTableSeedingFailed
        }
    }

    private func sqlString(_ value: String) -> String {
        "'\(value.replacingOccurrences(of: "'", with: "''"))'"
    }

    private func databaseURL() throws -> URL {
        guard let applicationSupportURL = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first else {
            throw LocalDatabaseInitializationError.applicationSupportUnavailable
        }

        let directoryURL = applicationSupportURL.appendingPathComponent(
            "FitnessTracker",
            isDirectory: true
        )
        try FileManager.default.createDirectory(
            at: directoryURL,
            withIntermediateDirectories: true
        )
        return directoryURL.appendingPathComponent("local.sqlite")
    }
}

private enum LocalDatabaseInitializationError: Error {
    case applicationSupportUnavailable
    case openFailed
    case schemaCreationFailed
    case schemaMigrationFailed
    case lookupTableSeedingFailed
}
