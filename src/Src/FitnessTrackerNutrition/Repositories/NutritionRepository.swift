import Foundation
import SQLite3

struct DailyNutritionValues: Sendable {
    let caloriesConsumed: Double
    let nutrientsByShortName: [String: Double]
}

protocol NutritionRepositoryProtocol: Sendable {
    func fetchDailyNutrition(date: String) async throws -> DailyNutritionValues
}

actor NutritionRepository: NutritionRepositoryProtocol {
    func fetchDailyNutrition(date: String) throws -> DailyNutritionValues {
        let foodIDs = try fetchLoggedFoodIDs(date: date)

        guard !foodIDs.isEmpty else {
            return DailyNutritionValues(
                caloriesConsumed: 0,
                nutrientsByShortName: [:]
            )
        }

        let foodsDatabase = try openFoodsDatabase()
        defer { sqlite3_close(foodsDatabase) }

        var caloriesConsumed = 0.0
        var nutrientsByShortName: [String: Double] = [:]

        for foodID in foodIDs {
            try Task.checkCancellation()

            let food = try fetchFoodNutrition(
                foodID: foodID,
                database: foodsDatabase
            )
            caloriesConsumed += food.caloriesConsumed

            for (shortName, amount) in food.nutrientsByShortName {
                nutrientsByShortName[shortName, default: 0] += amount
            }
        }

        return DailyNutritionValues(
            caloriesConsumed: caloriesConsumed,
            nutrientsByShortName: nutrientsByShortName
        )
    }

    private func fetchLoggedFoodIDs(date: String) throws -> [String] {
        let database = try openLocalDatabase()
        defer { sqlite3_close(database) }

        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(
            database,
            Constants.fetchDailyFoodIDsQuery,
            -1,
            &statement,
            nil
        ) == SQLITE_OK, let statement else {
            throw NutritionRepositoryError.queryFailed
        }
        defer { sqlite3_finalize(statement) }

        guard sqlite3_bind_text(
            statement,
            1,
            date,
            -1,
            sqliteTransient
        ) == SQLITE_OK else {
            throw NutritionRepositoryError.queryFailed
        }

        var foodIDs: [String] = []
        while true {
            switch sqlite3_step(statement) {
            case SQLITE_ROW:
                guard let foodIDText = sqlite3_column_text(statement, 0) else {
                    throw NutritionRepositoryError.queryFailed
                }
                foodIDs.append(String(cString: foodIDText))
            case SQLITE_DONE:
                return foodIDs
            default:
                throw NutritionRepositoryError.queryFailed
            }
        }
    }

    private func fetchFoodNutrition(
        foodID: String,
        database: OpaquePointer
    ) throws -> DailyNutritionValues {
        var foodStatement: OpaquePointer?
        guard sqlite3_prepare_v2(
            database,
            Constants.fetchFoodCaloriesQuery,
            -1,
            &foodStatement,
            nil
        ) == SQLITE_OK, let foodStatement else {
            throw NutritionRepositoryError.queryFailed
        }
        defer { sqlite3_finalize(foodStatement) }

        guard sqlite3_bind_text(
            foodStatement,
            1,
            foodID,
            -1,
            sqliteTransient
        ) == SQLITE_OK else {
            throw NutritionRepositoryError.queryFailed
        }

        guard sqlite3_step(foodStatement) == SQLITE_ROW else {
            return DailyNutritionValues(
                caloriesConsumed: 0,
                nutrientsByShortName: [:]
            )
        }

        let calories = sqlite3_column_type(foodStatement, 0) == SQLITE_NULL
            ? 0
            : sqlite3_column_double(foodStatement, 0)
        let servingAmount = sqlite3_column_double(foodStatement, 1)

        var nutrientStatement: OpaquePointer?
        guard sqlite3_prepare_v2(
            database,
            Constants.fetchFoodNutrientsQuery,
            -1,
            &nutrientStatement,
            nil
        ) == SQLITE_OK, let nutrientStatement else {
            throw NutritionRepositoryError.queryFailed
        }
        defer { sqlite3_finalize(nutrientStatement) }

        guard sqlite3_bind_double(
            nutrientStatement,
            1,
            servingAmount
        ) == SQLITE_OK,
        sqlite3_bind_text(
            nutrientStatement,
            2,
            foodID,
            -1,
            sqliteTransient
        ) == SQLITE_OK else {
            throw NutritionRepositoryError.queryFailed
        }

        var nutrientsByShortName: [String: Double] = [:]
        while true {
            switch sqlite3_step(nutrientStatement) {
            case SQLITE_ROW:
                guard let shortNameText = sqlite3_column_text(
                    nutrientStatement,
                    0
                ) else {
                    throw NutritionRepositoryError.queryFailed
                }

                nutrientsByShortName[String(cString: shortNameText)] =
                    sqlite3_column_double(nutrientStatement, 1)
            case SQLITE_DONE:
                return DailyNutritionValues(
                    caloriesConsumed: calories,
                    nutrientsByShortName: nutrientsByShortName
                )
            default:
                throw NutritionRepositoryError.queryFailed
            }
        }
    }

    private func openLocalDatabase() throws -> OpaquePointer {
        guard let applicationSupportURL = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first else {
            throw NutritionRepositoryError.localDatabaseUnavailable
        }

        let databaseURL = applicationSupportURL
            .appendingPathComponent(Constants.databaseDirectory, isDirectory: true)
            .appendingPathComponent(Constants.localDatabaseFileName)

        return try openDatabase(at: databaseURL)
    }

    private func openFoodsDatabase() throws -> OpaquePointer {
        guard let databaseURL = Bundle.main.url(
            forResource: Constants.foodsDatabaseName,
            withExtension: Constants.foodsDatabaseExtension
        ) else {
            throw NutritionRepositoryError.foodsDatabaseUnavailable
        }

        return try openDatabase(at: databaseURL)
    }

    private func openDatabase(at url: URL) throws -> OpaquePointer {
        var database: OpaquePointer?
        guard sqlite3_open_v2(
            url.path,
            &database,
            SQLITE_OPEN_READONLY | SQLITE_OPEN_FULLMUTEX,
            nil
        ) == SQLITE_OK, let database else {
            throw NutritionRepositoryError.databaseOpenFailed
        }
        return database
    }
}

enum NutritionRepositoryError: Error {
    case localDatabaseUnavailable
    case foodsDatabaseUnavailable
    case databaseOpenFailed
    case queryFailed
}

private let sqliteTransient = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

private enum Constants {
    static let databaseDirectory = "FitnessTracker"
    static let localDatabaseFileName = "local.sqlite"
    static let foodsDatabaseName = "uk_foods"
    static let foodsDatabaseExtension = "sqlite"
    static let fetchDailyFoodIDsQuery = """
        SELECT foodId
        FROM NutritionLogs
        WHERE date = ?
        ORDER BY time, id;
        """
    static let fetchFoodCaloriesQuery = """
        SELECT
            CASE
                WHEN total_energy_cal IS NULL THEN NULL
                WHEN total_amount_grams > 0 THEN
                    total_energy_cal
                    * COALESCE(
                        serving_size_grams,
                        total_amount_grams,
                        100.0
                    )
                    / total_amount_grams
                ELSE total_energy_cal
            END,
            COALESCE(serving_size_grams, total_amount_grams, 100.0)
        FROM Foods
        WHERE id = ?;
        """
    static let fetchFoodNutrientsQuery = """
        SELECT
            Nutrients.short_name,
            FoodNutrients.amount * ? / FoodNutrients.basis_amount
        FROM FoodNutrients
        JOIN Nutrients
            ON Nutrients.id = FoodNutrients.nutrient_id
        WHERE FoodNutrients.food_id = ?
          AND Nutrients.short_name IN ('protein', 'carbs', 'fat', 'water');
        """
}
