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
    private let gramsUnitID = 1
    private let centimetresUnitID = 2

    private let measurementUnits = [
        MeasurementUnit(id: 1, name: "gram", shortName: "g", pluralForm: "grams", siConversionValue: 1),
        MeasurementUnit(id: 2, name: "centimetre", shortName: "cm", pluralForm: "centimetres", siConversionValue: nil),
        MeasurementUnit(id: 3, name: "pound", shortName: "lb", pluralForm: "pounds", siConversionValue: 453.59237),
        MeasurementUnit(id: 4, name: "ounce", shortName: "oz", pluralForm: "ounces", siConversionValue: 28.349523125),
        MeasurementUnit(id: 5, name: "inch", shortName: "in", pluralForm: "inches", siConversionValue: 2.54),
        MeasurementUnit(id: 6, name: "foot", shortName: "ft", pluralForm: "feet", siConversionValue: 30.48)
    ]

    private let activityLevels = [
        ActivityLevel(id: 1, name: "Sedentary", calorieMultiplier: 1.2, description: "desk job, no training"),
        ActivityLevel(id: 2, name: "Light", calorieMultiplier: 1.375, description: "1–3 sessions a week"),
        ActivityLevel(id: 3, name: "Moderate", calorieMultiplier: 1.55, description: "3–5 sessions a week"),
        ActivityLevel(id: 4, name: "Heavy", calorieMultiplier: 1.725, description: "6–7 sessions a week"),
        ActivityLevel(id: 5, name: "Athlete", calorieMultiplier: 1.9, description: "training twice a day")
    ]

    private let planTypes = [
        PlanType(id: 1, name: "Maintenance"),
        PlanType(id: 2, name: "Progressive gain"),
        PlanType(id: 3, name: "Progressive loss"),
        PlanType(id: 4, name: "Custom")
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

            CREATE TABLE IF NOT EXISTS NutritionLogs (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                foodId TEXT NOT NULL,
                date TEXT NOT NULL,
                time TEXT NOT NULL
            );
            CREATE INDEX IF NOT EXISTS nutrition_logs_date_idx ON NutritionLogs (date);

            CREATE TABLE IF NOT EXISTS MeasurementUnits (
                id INTEGER PRIMARY KEY,
                name TEXT NOT NULL UNIQUE,
                shortName TEXT NOT NULL UNIQUE,
                pluralForm TEXT,
                siConversionValue REAL,
                dateAdded INTEGER NOT NULL
            );

            CREATE TABLE IF NOT EXISTS ActivityLevels (
                id INTEGER PRIMARY KEY,
                name TEXT NOT NULL UNIQUE,
                calorieMultiplier REAL NOT NULL,
                description TEXT NOT NULL,
                dateAdded INTEGER NOT NULL
            );

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
                weightMeasurementUnitId INTEGER NOT NULL DEFAULT \(gramsUnitID),
                height REAL,
                heightMeasurementUnitId INTEGER NOT NULL DEFAULT \(centimetresUnitID),
                leanMass REAL,
                activityLevelId INTEGER,
                FOREIGN KEY (userId) REFERENCES "User" (id),
                FOREIGN KEY (weightMeasurementUnitId) REFERENCES MeasurementUnits (id),
                FOREIGN KEY (heightMeasurementUnitId) REFERENCES MeasurementUnits (id),
                FOREIGN KEY (activityLevelId) REFERENCES ActivityLevels (id)
            );
            CREATE INDEX IF NOT EXISTS user_measurements_user_id_idx ON UserMeasurements (userId);

            CREATE TABLE IF NOT EXISTS PlanTypes (
                id INTEGER PRIMARY KEY,
                name TEXT NOT NULL UNIQUE
            );

            CREATE TABLE IF NOT EXISTS NutritionPlans (
                id TEXT PRIMARY KEY,
                planTypeId INTEGER NOT NULL,
                userMeasurementId TEXT NOT NULL,
                targetWeightSI REAL NOT NULL,
                FOREIGN KEY (planTypeId) REFERENCES PlanTypes (id),
                FOREIGN KEY (userMeasurementId) REFERENCES UserMeasurements (id)
            );

            CREATE TABLE IF NOT EXISTS NutritionPlanSpans (
                id TEXT PRIMARY KEY,
                nutritionPlanId TEXT NOT NULL,
                startDate INTEGER NOT NULL,
                endDate INTEGER NOT NULL,
                targetCaloriesSI REAL NOT NULL,
                FOREIGN KEY (nutritionPlanId) REFERENCES NutritionPlans (id)
            );
            CREATE INDEX IF NOT EXISTS nutrition_plan_spans_plan_id_idx ON NutritionPlanSpans (nutritionPlanId);
            """

        guard sqlite3_exec(database, schema, nil, nil, nil) == SQLITE_OK else {
            throw LocalDatabaseInitializationError.schemaCreationFailed
        }

        try seedLookupTables(in: database)
    }

    private func seedLookupTables(in database: OpaquePointer) throws {
        let dateAdded = Int(Date().timeIntervalSince1970)

        for unit in measurementUnits {
            try execute(
                """
                INSERT OR IGNORE INTO MeasurementUnits
                    (id, name, shortName, pluralForm, siConversionValue, dateAdded)
                VALUES
                    (\(unit.id), \(sqlString(unit.name)), \(sqlString(unit.shortName)), \(sqlString(unit.pluralForm)), \(unit.siConversionValue.map { String($0) } ?? "NULL"), \(dateAdded));
                """,
                in: database
            )
        }

        for level in activityLevels {
            try execute(
                """
                INSERT OR IGNORE INTO ActivityLevels
                    (id, name, calorieMultiplier, description, dateAdded)
                VALUES
                    (\(level.id), \(sqlString(level.name)), \(level.calorieMultiplier), \(sqlString(level.description)), \(dateAdded));
                """,
                in: database
            )
        }

        for planType in planTypes {
            try execute(
                """
                INSERT OR IGNORE INTO PlanTypes (id, name)
                VALUES (\(planType.id), \(sqlString(planType.name)));
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

private struct MeasurementUnit {
    let id: Int
    let name: String
    let shortName: String
    let pluralForm: String
    let siConversionValue: Double?
}

private struct ActivityLevel {
    let id: Int
    let name: String
    let calorieMultiplier: Double
    let description: String
}

private struct PlanType {
    let id: Int
    let name: String
}

private enum LocalDatabaseInitializationError: Error {
    case applicationSupportUnavailable
    case openFailed
    case schemaCreationFailed
    case lookupTableSeedingFailed
}
