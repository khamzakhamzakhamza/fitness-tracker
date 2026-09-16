import Foundation
import SQLite3
import FitnessTrackerPlanner

final class MeasurementService: MeasurementUnitServiceProtocol {
    static let shared = MeasurementService()

    private init() {}

    func fetchHeightMeasurementUnits() throws -> [MeasurementUnitOption] {
        try fetchUnits(from: .height)
    }

    func fetchWeightMeasurementUnits() throws -> [MeasurementUnitOption] {
        try fetchUnits(from: .weight)
    }

    func setDefaultHeightMeasurementUnit(id: Int) throws {
        try setDefaultUnit(id: id, in: .height)
    }

    func setDefaultWeightMeasurementUnit(id: Int) throws {
        try setDefaultUnit(id: id, in: .weight)
    }

    private func fetchUnits(from table: MeasurementUnitTable) throws -> [MeasurementUnitOption] {
        let database = try openDatabase()
        defer { sqlite3_close(database) }

        var statement: OpaquePointer?
        let query = """
            SELECT id, name, shortName, siConversionValue, isDefault
            FROM \(table.name)
            ORDER BY isDefault DESC, id ASC;
            """

        guard sqlite3_prepare_v2(database, query, -1, &statement, nil) == SQLITE_OK,
              let statement else {
            throw MeasurementServiceError.queryPreparationFailed
        }
        defer { sqlite3_finalize(statement) }

        var units: [MeasurementUnitOption] = []
        while sqlite3_step(statement) == SQLITE_ROW {
            guard let nameText = sqlite3_column_text(statement, 1),
                  let shortNameText = sqlite3_column_text(statement, 2) else {
                throw MeasurementServiceError.invalidMeasurementUnit
            }

            units.append(
                MeasurementUnitOption(
                    id: Int(sqlite3_column_int(statement, 0)),
                    name: String(cString: nameText),
                    shortName: String(cString: shortNameText),
                    siConversionValue: sqlite3_column_double(statement, 3),
                    isDefault: sqlite3_column_int(statement, 4) == 1
                )
            )
        }

        return units
    }

    private func setDefaultUnit(id: Int, in table: MeasurementUnitTable) throws {
        let database = try openDatabase()
        defer { sqlite3_close(database) }

        var statement: OpaquePointer?
        let query = """
            UPDATE \(table.name)
            SET isDefault = CASE WHEN id = ? THEN 1 ELSE 0 END
            WHERE EXISTS (
                SELECT 1 FROM \(table.name) WHERE id = ?
            );
            """

        guard sqlite3_prepare_v2(database, query, -1, &statement, nil) == SQLITE_OK,
              let statement else {
            throw MeasurementServiceError.queryPreparationFailed
        }
        defer { sqlite3_finalize(statement) }

        guard sqlite3_bind_int(statement, 1, Int32(id)) == SQLITE_OK,
              sqlite3_bind_int(statement, 2, Int32(id)) == SQLITE_OK,
              sqlite3_step(statement) == SQLITE_DONE,
              sqlite3_changes(database) > 0 else {
            throw MeasurementServiceError.defaultUpdateFailed
        }
    }

    private func openDatabase() throws -> OpaquePointer {
        guard let applicationSupportURL = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first else {
            throw MeasurementServiceError.applicationSupportUnavailable
        }

        let databaseURL = applicationSupportURL
            .appendingPathComponent(Constants.databaseDirectory, isDirectory: true)
            .appendingPathComponent(Constants.databaseFileName)
        var database: OpaquePointer?

        guard sqlite3_open_v2(
            databaseURL.path,
            &database,
            SQLITE_OPEN_READWRITE | SQLITE_OPEN_FULLMUTEX,
            nil
        ) == SQLITE_OK, let database else {
            throw MeasurementServiceError.databaseOpenFailed
        }

        return database
    }
}

private enum MeasurementUnitTable {
    case height
    case weight

    var name: String {
        switch self {
        case .height:
            HeightMeasurementUnit.tableName
        case .weight:
            WeightMeasurementUnit.tableName
        }
    }
}

private enum MeasurementServiceError: Error {
    case applicationSupportUnavailable
    case databaseOpenFailed
    case queryPreparationFailed
    case invalidMeasurementUnit
    case defaultUpdateFailed
}

private enum Constants {
    static let databaseDirectory = "FitnessTracker"
    static let databaseFileName = "local.sqlite"
}
