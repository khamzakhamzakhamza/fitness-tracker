import Foundation
import SQLite3
import Testing
@testable import FitnessTrackerNutrition

struct LocalDatabaseRepositoryTests {
    @Test func createsNutritionLogsTableIndexAndInsertsLogs() async throws {
        let directoryURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(
            at: directoryURL,
            withIntermediateDirectories: true
        )
        defer { try? FileManager.default.removeItem(at: directoryURL) }

        let databaseURL = directoryURL.appendingPathComponent("local.sqlite")
        let repository = LocalDatabaseRepository(databaseURL: databaseURL)

        try await repository.initializeDatabase()
        let firstLog = try await repository.addNutritionLog(
            foodID: "food-7",
            date: "2026-09-07",
            time: "21:30:00"
        )
        let secondLog = try await repository.addNutritionLog(
            foodID: "food-8",
            date: "2026-09-08",
            time: "21:31:00"
        )
        let firstDayLogs = try await repository.nutritionLogs(
            date: "2026-09-07"
        )
        try await repository.deleteNutritionLog(id: firstLog.id)
        let firstDayLogsAfterDeletion = try await repository.nutritionLogs(
            date: "2026-09-07"
        )

        #expect(firstLog == NutritionLogItem(
            id: 1,
            foodID: "food-7",
            date: "2026-09-07",
            time: "21:30:00"
        ))
        #expect(secondLog.id == 2)
        #expect(firstDayLogs == [firstLog])
        #expect(firstDayLogsAfterDeletion.isEmpty)
        #expect(tableColumns(at: databaseURL) == [
            "id",
            "foodId",
            "date",
            "time"
        ])
        #expect(hasDateIndex(at: databaseURL))
    }

    private func tableColumns(at databaseURL: URL) -> [String] {
        var database: OpaquePointer?
        guard sqlite3_open_v2(
            databaseURL.path,
            &database,
            SQLITE_OPEN_READONLY,
            nil
        ) == SQLITE_OK, let database else {
            return []
        }
        defer { sqlite3_close(database) }

        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(
            database,
            "PRAGMA table_info(NutritionLogs)",
            -1,
            &statement,
            nil
        ) == SQLITE_OK else {
            return []
        }
        defer { sqlite3_finalize(statement) }

        var columns: [String] = []
        while sqlite3_step(statement) == SQLITE_ROW {
            if let value = sqlite3_column_text(statement, 1) {
                columns.append(String(cString: value))
            }
        }
        return columns
    }

    private func hasDateIndex(at databaseURL: URL) -> Bool {
        var database: OpaquePointer?
        guard sqlite3_open_v2(
            databaseURL.path,
            &database,
            SQLITE_OPEN_READONLY,
            nil
        ) == SQLITE_OK, let database else {
            return false
        }
        defer { sqlite3_close(database) }

        var statement: OpaquePointer?
        let sql = """
            SELECT 1
            FROM sqlite_master
            WHERE type = 'index'
                AND name = 'nutrition_logs_date_idx'
            """
        guard sqlite3_prepare_v2(
            database,
            sql,
            -1,
            &statement,
            nil
        ) == SQLITE_OK else {
            return false
        }
        defer { sqlite3_finalize(statement) }

        return sqlite3_step(statement) == SQLITE_ROW
    }
}
