import Foundation
import SQLite3

enum FoodDatabaseError: LocalizedError {
    case databaseNotFound
    case databaseOpenFailed(String)
    case invalidPage
    case queryPreparationFailed(String)
    case queryBindingFailed(String)
    case queryFailed(String)

    var errorDescription: String? {
        switch self {
        case .databaseNotFound:
            "uk_foods.sqlite was not found in the app bundle."
        case .databaseOpenFailed(let message):
            "Could not open the foods database: \(message)"
        case .invalidPage:
            "Food search limit must be positive and offset cannot be negative."
        case .queryPreparationFailed(let message):
            "Could not prepare the foods query: \(message)"
        case .queryBindingFailed(let message):
            "Could not bind the foods query: \(message)"
        case .queryFailed(let message):
            "Could not read foods from the database: \(message)"
        }
    }
}

struct StoredFood: Equatable, Sendable {
    let id: Int64
    let name: String
    let brand: String?
    let imageURL: URL?
    let quantity: Double?
    let measurementUnitShortName: String?

    var subtitle: String {
        var parts: [String] = []

        if let brand, !brand.isEmpty {
            parts.append(brand)
        }

        if let quantity, let measurementUnitShortName {
            let formattedQuantity = quantity.formatted(
                .number.precision(.fractionLength(0...3))
            )
            parts.append("\(formattedQuantity) \(measurementUnitShortName)")
        }

        return parts.joined(separator: " · ")
    }
}

struct StoredNutrient: Equatable, Sendable {
    let name: String
    let shortName: String
    let amount: Double
    let unit: String
}

struct StoredFoodDetails: Equatable, Sendable {
    let id: Int64
    let name: String
    let brand: String?
    let imageURL: URL?
    let quantity: Double?
    let measurementUnitShortName: String?
    let servingSizeGrams: Double
    let totalAmountGrams: Double?
    let calories: Double?
    let sourceName: String
    let nutrients: [StoredNutrient]

    var subtitle: String {
        var parts: [String] = []

        if let brand, !brand.isEmpty {
            parts.append(brand)
        }

        if let quantity, let measurementUnitShortName {
            let formattedQuantity = quantity.formatted(
                .number.precision(.fractionLength(0...3))
            )
            parts.append("\(formattedQuantity) \(measurementUnitShortName)")
        }

        return parts.joined(separator: " · ")
    }
}

struct FoodDatabasePage: Equatable, Sendable {
    let foods: [StoredFood]
    let totalMatches: Int
}

protocol FoodDatabaseRepositoryProtocol: Sendable {
    func searchFoods(
        query: String,
        limit: Int,
        offset: Int
    ) async throws -> FoodDatabasePage

    func foodDetails(id: Int64) async throws -> StoredFoodDetails?
}

actor FoodDatabaseRepository: FoodDatabaseRepositoryProtocol {
    private let databaseURL: URL?

    init(databaseURL: URL? = nil) {
        self.databaseURL = databaseURL
    }

    func searchFoods(
        query: String,
        limit: Int,
        offset: Int
    ) throws -> FoodDatabasePage {
        guard limit > 0, offset >= 0 else {
            throw FoodDatabaseError.invalidPage
        }

        let trimmedQuery = query.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        let usesSearch = !trimmedQuery.isEmpty
        let searchExpression = Self.ftsExpression(for: trimmedQuery)

        if usesSearch && searchExpression == nil {
            return FoodDatabasePage(foods: [], totalMatches: 0)
        }

        guard let databaseURL = databaseURL ?? Bundle.main.url(
            forResource: "uk_foods",
            withExtension: "sqlite"
        ) else {
            throw FoodDatabaseError.databaseNotFound
        }

        var database: OpaquePointer?
        let openResult = sqlite3_open_v2(
            databaseURL.path,
            &database,
            SQLITE_OPEN_READONLY,
            nil
        )

        guard openResult == SQLITE_OK, let database else {
            let message = database.map(databaseErrorMessage)
                ?? "Unknown SQLite error"
            if let database {
                sqlite3_close(database)
            }
            throw FoodDatabaseError.databaseOpenFailed(message)
        }
        defer { sqlite3_close(database) }

        let totalMatches = try countFoods(
            in: database,
            searchExpression: searchExpression,
            usesSearch: usesSearch
        )
        try Task.checkCancellation()

        let foods = try readFoods(
            from: database,
            searchExpression: searchExpression,
            usesSearch: usesSearch,
            limit: limit,
            offset: offset
        )
        try Task.checkCancellation()

        return FoodDatabasePage(
            foods: foods,
            totalMatches: totalMatches
        )
    }

    func foodDetails(id: Int64) throws -> StoredFoodDetails? {
        guard let databaseURL = databaseURL ?? Bundle.main.url(
            forResource: "uk_foods",
            withExtension: "sqlite"
        ) else {
            throw FoodDatabaseError.databaseNotFound
        }

        var database: OpaquePointer?
        let openResult = sqlite3_open_v2(
            databaseURL.path,
            &database,
            SQLITE_OPEN_READONLY,
            nil
        )

        guard openResult == SQLITE_OK, let database else {
            let message = database.map(databaseErrorMessage)
                ?? "Unknown SQLite error"
            if let database {
                sqlite3_close(database)
            }
            throw FoodDatabaseError.databaseOpenFailed(message)
        }
        defer { sqlite3_close(database) }

        let sql = """
            WITH SelectedFood AS (
                SELECT
                    Foods.*,
                    COALESCE(
                        Foods.serving_size_grams,
                        Foods.total_amount_grams,
                        100.0
                    ) AS selected_amount_grams
                FROM Foods
                WHERE Foods.id = ?
            )
            SELECT
                SelectedFood.id,
                SelectedFood.name,
                SelectedFood.brand,
                COALESCE(
                    NULLIF(SelectedFood.image_url, ''),
                    NULLIF(SelectedFood.small_image_url, '')
                ),
                SelectedFood.quantity,
                MeasurementUnits.short_name,
                CASE
                    WHEN SelectedFood.total_energy_cal IS NULL THEN NULL
                    WHEN SelectedFood.total_amount_grams > 0 THEN
                        SelectedFood.total_energy_cal
                        * SelectedFood.selected_amount_grams
                        / SelectedFood.total_amount_grams
                    ELSE SelectedFood.total_energy_cal
                END,
                SelectedFood.selected_amount_grams,
                SelectedFood.total_amount_grams,
                Sources.name
            FROM SelectedFood
            JOIN MeasurementUnits
                ON MeasurementUnits.id = SelectedFood.measurement_unit_id
            JOIN Sources
                ON Sources.id = SelectedFood.source_id
            """
        var statement: OpaquePointer?

        guard sqlite3_prepare_v2(
            database,
            sql,
            -1,
            &statement,
            nil
        ) == SQLITE_OK else {
            throw FoodDatabaseError.queryPreparationFailed(
                databaseErrorMessage(database)
            )
        }
        defer { sqlite3_finalize(statement) }

        guard sqlite3_bind_int64(statement, 1, id) == SQLITE_OK else {
            throw FoodDatabaseError.queryBindingFailed(
                databaseErrorMessage(database)
            )
        }

        switch sqlite3_step(statement) {
        case SQLITE_ROW:
            guard let name = stringValue(in: statement, column: 1) else {
                throw FoodDatabaseError.queryFailed(
                    "The selected food has no name."
                )
            }

            let nutrients = try readNutrients(
                from: database,
                foodID: id,
                servingAmountGrams: sqlite3_column_double(statement, 7)
            )

            return StoredFoodDetails(
                id: sqlite3_column_int64(statement, 0),
                name: name,
                brand: stringValue(in: statement, column: 2),
                imageURL: stringValue(in: statement, column: 3)
                    .flatMap(URL.init(string:)),
                quantity: doubleValue(in: statement, column: 4),
                measurementUnitShortName: stringValue(
                    in: statement,
                    column: 5
                ),
                servingSizeGrams: sqlite3_column_double(statement, 7),
                totalAmountGrams: doubleValue(in: statement, column: 8),
                calories: doubleValue(in: statement, column: 6),
                sourceName: stringValue(in: statement, column: 9)
                    ?? "Unknown source",
                nutrients: nutrients
            )
        case SQLITE_DONE:
            return nil
        default:
            throw FoodDatabaseError.queryFailed(
                databaseErrorMessage(database)
            )
        }
    }

    private func readNutrients(
        from database: OpaquePointer,
        foodID: Int64,
        servingAmountGrams: Double
    ) throws -> [StoredNutrient] {
        let sql = """
            SELECT
                Nutrients.name,
                Nutrients.short_name,
                FoodNutrients.amount * ? / FoodNutrients.basis_amount,
                MeasurementUnits.short_name
            FROM FoodNutrients
            JOIN Nutrients
                ON Nutrients.id = FoodNutrients.nutrient_id
            JOIN MeasurementUnits
                ON MeasurementUnits.id = Nutrients.measurement_unit_id
            WHERE FoodNutrients.food_id = ?
            ORDER BY Nutrients.id
            """
        var statement: OpaquePointer?

        guard sqlite3_prepare_v2(
            database,
            sql,
            -1,
            &statement,
            nil
        ) == SQLITE_OK else {
            throw FoodDatabaseError.queryPreparationFailed(
                databaseErrorMessage(database)
            )
        }
        defer { sqlite3_finalize(statement) }

        guard
            sqlite3_bind_double(
                statement,
                1,
                servingAmountGrams
            ) == SQLITE_OK,
            sqlite3_bind_int64(statement, 2, foodID) == SQLITE_OK
        else {
            throw FoodDatabaseError.queryBindingFailed(
                databaseErrorMessage(database)
            )
        }

        var nutrients: [StoredNutrient] = []

        while true {
            switch sqlite3_step(statement) {
            case SQLITE_ROW:
                guard
                    let name = stringValue(in: statement, column: 0),
                    let shortName = stringValue(in: statement, column: 1),
                    let amount = doubleValue(in: statement, column: 2),
                    let unit = stringValue(in: statement, column: 3)
                else {
                    continue
                }

                nutrients.append(
                    StoredNutrient(
                        name: name,
                        shortName: shortName,
                        amount: amount,
                        unit: unit
                    )
                )
            case SQLITE_DONE:
                return nutrients
            default:
                throw FoodDatabaseError.queryFailed(
                    databaseErrorMessage(database)
                )
            }
        }
    }

    nonisolated static func ftsExpression(for query: String) -> String? {
        let terms = query.split { character in
            !character.isLetter && !character.isNumber
        }

        guard !terms.isEmpty else {
            return nil
        }

        return terms
            .map { "\"\($0)\"*" }
            .joined(separator: " ")
    }

    private func countFoods(
        in database: OpaquePointer,
        searchExpression: String?,
        usesSearch: Bool
    ) throws -> Int {
        let sql = usesSearch
            ? "SELECT COUNT(*) FROM FoodSearch WHERE FoodSearch MATCH ?"
            : "SELECT COUNT(*) FROM Foods"
        var statement: OpaquePointer?

        guard sqlite3_prepare_v2(
            database,
            sql,
            -1,
            &statement,
            nil
        ) == SQLITE_OK else {
            throw FoodDatabaseError.queryPreparationFailed(
                databaseErrorMessage(database)
            )
        }
        defer { sqlite3_finalize(statement) }

        if let searchExpression {
            try bindText(
                searchExpression,
                to: statement,
                index: 1,
                database: database
            )
        }

        guard sqlite3_step(statement) == SQLITE_ROW else {
            throw FoodDatabaseError.queryFailed(
                databaseErrorMessage(database)
            )
        }

        return Int(sqlite3_column_int64(statement, 0))
    }

    private func readFoods(
        from database: OpaquePointer,
        searchExpression: String?,
        usesSearch: Bool,
        limit: Int,
        offset: Int
    ) throws -> [StoredFood] {
        let sql = usesSearch
            ? """
              SELECT
                  Foods.id,
                  Foods.name,
                  Foods.brand,
                  COALESCE(
                      NULLIF(Foods.small_image_url, ''),
                      NULLIF(Foods.image_url, '')
                  ),
                  Foods.quantity,
                  MeasurementUnits.short_name
              FROM FoodSearch
              JOIN Foods ON Foods.id = FoodSearch.rowid
              JOIN MeasurementUnits
                  ON MeasurementUnits.id = Foods.measurement_unit_id
              WHERE FoodSearch MATCH ?
              ORDER BY bm25(FoodSearch), Foods.name COLLATE NOCASE, Foods.id
              LIMIT ? OFFSET ?
              """
            : """
              SELECT
                  Foods.id,
                  Foods.name,
                  Foods.brand,
                  COALESCE(
                      NULLIF(Foods.small_image_url, ''),
                      NULLIF(Foods.image_url, '')
                  ),
                  Foods.quantity,
                  MeasurementUnits.short_name
              FROM Foods
              JOIN MeasurementUnits
                  ON MeasurementUnits.id = Foods.measurement_unit_id
              ORDER BY Foods.id
              LIMIT ? OFFSET ?
              """
        var statement: OpaquePointer?

        guard sqlite3_prepare_v2(
            database,
            sql,
            -1,
            &statement,
            nil
        ) == SQLITE_OK else {
            throw FoodDatabaseError.queryPreparationFailed(
                databaseErrorMessage(database)
            )
        }
        defer { sqlite3_finalize(statement) }

        var bindingIndex: Int32 = 1
        if let searchExpression {
            try bindText(
                searchExpression,
                to: statement,
                index: bindingIndex,
                database: database
            )
            bindingIndex += 1
        }

        guard
            sqlite3_bind_int64(
                statement,
                bindingIndex,
                Int64(limit)
            ) == SQLITE_OK,
            sqlite3_bind_int64(
                statement,
                bindingIndex + 1,
                Int64(offset)
            ) == SQLITE_OK
        else {
            throw FoodDatabaseError.queryBindingFailed(
                databaseErrorMessage(database)
            )
        }

        var foods: [StoredFood] = []

        while true {
            switch sqlite3_step(statement) {
            case SQLITE_ROW:
                guard let name = stringValue(in: statement, column: 1) else {
                    continue
                }
                let brand = stringValue(in: statement, column: 2)
                let imageURL = stringValue(in: statement, column: 3)
                    .flatMap(URL.init(string:))
                let quantity = doubleValue(in: statement, column: 4)
                let measurementUnitShortName = stringValue(
                    in: statement,
                    column: 5
                )

                foods.append(
                    StoredFood(
                        id: sqlite3_column_int64(statement, 0),
                        name: name,
                        brand: brand,
                        imageURL: imageURL,
                        quantity: quantity,
                        measurementUnitShortName: measurementUnitShortName
                    )
                )
            case SQLITE_DONE:
                return foods
            default:
                throw FoodDatabaseError.queryFailed(
                    databaseErrorMessage(database)
                )
            }
        }
    }

    private func bindText(
        _ value: String,
        to statement: OpaquePointer?,
        index: Int32,
        database: OpaquePointer
    ) throws {
        let sqliteTransient = unsafeBitCast(
            -1,
            to: sqlite3_destructor_type.self
        )
        let result = value.withCString { pointer in
            sqlite3_bind_text(
                statement,
                index,
                pointer,
                -1,
                sqliteTransient
            )
        }

        guard result == SQLITE_OK else {
            throw FoodDatabaseError.queryBindingFailed(
                databaseErrorMessage(database)
            )
        }
    }

    private func databaseErrorMessage(_ database: OpaquePointer) -> String {
        String(cString: sqlite3_errmsg(database))
    }

    private func stringValue(
        in statement: OpaquePointer?,
        column: Int32
    ) -> String? {
        guard let text = sqlite3_column_text(statement, column) else {
            return nil
        }
        return String(cString: text)
    }

    private func doubleValue(
        in statement: OpaquePointer?,
        column: Int32
    ) -> Double? {
        guard sqlite3_column_type(statement, column) != SQLITE_NULL else {
            return nil
        }
        return sqlite3_column_double(statement, column)
    }
}
