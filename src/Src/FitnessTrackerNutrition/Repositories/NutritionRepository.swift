import Foundation
import SQLite3

struct DailyNutritionValues: Sendable {
    let caloriesConsumed: Double
    let nutrientsByShortName: [String: Double]
}

struct DailyCalorieTargetInputs: Sendable {
    let weightSI: Double
    let heightCentimetres: Double
    let leanMassPercentage: Double
    let birthday: Date
    let activityMultiplier: Double
    let milestoneDate: Date
    let milestoneTargetWeightSI: Double
}

protocol NutritionRepositoryProtocol: Sendable {
    func fetchDailyNutrition(date: String) async throws -> DailyNutritionValues
    func addNutritionLog(
        foodID: String,
        date: String,
        time: String
    ) async throws
    func fetchDailyCalorieTargetInputs(
        milestoneStartDate: Date,
        milestoneEndDate: Date
    ) async throws -> DailyCalorieTargetInputs?
}

actor NutritionRepository: NutritionRepositoryProtocol {
    func fetchDailyCalorieTargetInputs(
        milestoneStartDate: Date,
        milestoneEndDate: Date
    ) throws -> DailyCalorieTargetInputs? {
        let database = try openLocalDatabase()
        defer { sqlite3_close(database) }

        var measurementStatement: OpaquePointer?
        guard sqlite3_prepare_v2(
            database,
            Constants.fetchLatestMeasurementQuery,
            -1,
            &measurementStatement,
            nil
        ) == SQLITE_OK, let measurementStatement else {
            throw NutritionRepositoryError.queryFailed
        }
        defer { sqlite3_finalize(measurementStatement) }

        guard sqlite3_step(measurementStatement) == SQLITE_ROW,
              sqlite3_column_type(measurementStatement, 1) != SQLITE_NULL else {
            return nil
        }

        let weightSI = sqlite3_column_double(measurementStatement, 0)
        let heightCentimetres = sqlite3_column_double(measurementStatement, 1)
        let leanMassPercentage = sqlite3_column_double(measurementStatement, 2)
        let birthday = Date(
            timeIntervalSince1970: Double(
                sqlite3_column_int64(measurementStatement, 3)
            )
        )
        let activityMultiplier = sqlite3_column_double(measurementStatement, 4)

        var milestoneStatement: OpaquePointer?
        guard sqlite3_prepare_v2(
            database,
            Constants.fetchCurrentWeekMilestoneQuery,
            -1,
            &milestoneStatement,
            nil
        ) == SQLITE_OK, let milestoneStatement else {
            throw NutritionRepositoryError.queryFailed
        }
        defer { sqlite3_finalize(milestoneStatement) }

        guard sqlite3_bind_int64(
            milestoneStatement,
            1,
            Int64(milestoneStartDate.timeIntervalSince1970)
        ) == SQLITE_OK,
        sqlite3_bind_int64(
            milestoneStatement,
            2,
            Int64(milestoneEndDate.timeIntervalSince1970)
        ) == SQLITE_OK else {
            throw NutritionRepositoryError.queryFailed
        }

        guard sqlite3_step(milestoneStatement) == SQLITE_ROW else {
            return nil
        }

        return DailyCalorieTargetInputs(
            weightSI: weightSI,
            heightCentimetres: heightCentimetres,
            leanMassPercentage: leanMassPercentage,
            birthday: birthday,
            activityMultiplier: activityMultiplier,
            milestoneDate: Date(
                timeIntervalSince1970: Double(
                    sqlite3_column_int64(milestoneStatement, 0)
                )
            ),
            milestoneTargetWeightSI: sqlite3_column_double(
                milestoneStatement,
                1
            )
        )
    }

    func addNutritionLog(
        foodID: String,
        date: String,
        time: String
    ) throws {
        let database = try openLocalDatabase(readOnly: false)
        defer { sqlite3_close(database) }

        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(
            database,
            Constants.addNutritionLogQuery,
            -1,
            &statement,
            nil
        ) == SQLITE_OK, let statement else {
            throw NutritionRepositoryError.queryFailed
        }
        defer { sqlite3_finalize(statement) }

        guard sqlite3_bind_text(statement, 1, foodID, -1, sqliteTransient) == SQLITE_OK,
              sqlite3_bind_text(statement, 2, date, -1, sqliteTransient) == SQLITE_OK,
              sqlite3_bind_text(statement, 3, time, -1, sqliteTransient) == SQLITE_OK,
              sqlite3_step(statement) == SQLITE_DONE else {
            throw NutritionRepositoryError.queryFailed
        }
    }

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

    private func openLocalDatabase(readOnly: Bool = true) throws -> OpaquePointer {
        guard let applicationSupportURL = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first else {
            throw NutritionRepositoryError.localDatabaseUnavailable
        }

        let databaseURL = applicationSupportURL
            .appendingPathComponent(Constants.databaseDirectory, isDirectory: true)
            .appendingPathComponent(Constants.localDatabaseFileName)

        return try openDatabase(at: databaseURL, readOnly: readOnly)
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

    private func openDatabase(
        at url: URL,
        readOnly: Bool = true
    ) throws -> OpaquePointer {
        var database: OpaquePointer?
        let accessMode = readOnly ? SQLITE_OPEN_READONLY : SQLITE_OPEN_READWRITE
        guard sqlite3_open_v2(
            url.path,
            &database,
            accessMode | SQLITE_OPEN_FULLMUTEX,
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
    static let addNutritionLogQuery = """
        INSERT INTO NutritionLogs (foodId, date, time)
        VALUES (?, ?, ?);
        """
    static let fetchLatestMeasurementQuery = """
        SELECT
            UserMeasurements.weightSI,
            UserMeasurements.heightSI,
            UserMeasurements.leanMass,
            "User".birthday,
            ActivityLevels.calorieMultiplier
        FROM UserMeasurements
        JOIN "User"
            ON "User".id = UserMeasurements.userId
        JOIN ActivityLevels
            ON ActivityLevels.id = UserMeasurements.activityLevelId
        ORDER BY UserMeasurements.dateAdded DESC, UserMeasurements.rowid DESC
        LIMIT 1;
        """
    static let fetchCurrentWeekMilestoneQuery = """
        SELECT PlanMilestones.date, PlanMilestones.targetWeightSI
        FROM PlanMilestones
        JOIN Plans ON Plans.id = PlanMilestones.planId
        WHERE Plans.isActive = 1
          AND PlanMilestones.date >= ?
          AND PlanMilestones.date < ?
        ORDER BY PlanMilestones.date ASC
        LIMIT 1;
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
