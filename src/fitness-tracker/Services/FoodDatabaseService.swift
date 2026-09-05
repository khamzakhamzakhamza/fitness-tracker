import Foundation
import SQLite3

enum FoodDatabaseError: LocalizedError {
    case databaseNotFound
    case databaseOpenFailed(String)
    case queryPreparationFailed(String)
    case queryBindingFailed(String)
    case queryFailed(String)

    var errorDescription: String? {
        switch self {
        case .databaseNotFound:
            "uk_foods_first_1000.sqlite was not found in the app bundle."
        case .databaseOpenFailed(let message):
            "Could not open the foods database: \(message)"
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
    let name: String
    let brand: String?
    let imageURL: URL?
}

actor FoodDatabaseService {
    private let databaseURL: URL?

    init(databaseURL: URL? = nil) {
        self.databaseURL = databaseURL
    }

    func fetchFoods(limit: Int, offset: Int) throws -> [StoredFood] {
        guard let databaseURL = databaseURL ?? Bundle.main.url(
            forResource: "uk_foods_first_1000",
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
            let message = database.map(databaseErrorMessage) ?? "Unknown SQLite error"
            if let database {
                sqlite3_close(database)
            }
            throw FoodDatabaseError.databaseOpenFailed(message)
        }
        defer { sqlite3_close(database) }

        var statement: OpaquePointer?
        let prepareResult = sqlite3_prepare_v2(
            database,
            """
            SELECT
                name,
                brand,
                COALESCE(NULLIF(small_image_url, ''), NULLIF(image_url, ''))
            FROM Foods
            ORDER BY id
            LIMIT ? OFFSET ?
            """,
            -1,
            &statement,
            nil
        )

        guard prepareResult == SQLITE_OK else {
            throw FoodDatabaseError.queryPreparationFailed(
                databaseErrorMessage(database)
            )
        }
        defer { sqlite3_finalize(statement) }

        guard
            sqlite3_bind_int64(statement, 1, Int64(limit)) == SQLITE_OK,
            sqlite3_bind_int64(statement, 2, Int64(offset)) == SQLITE_OK
        else {
            throw FoodDatabaseError.queryBindingFailed(
                databaseErrorMessage(database)
            )
        }

        var foods: [StoredFood] = []

        while true {
            switch sqlite3_step(statement) {
            case SQLITE_ROW:
                guard let name = stringValue(in: statement, column: 0) else {
                    continue
                }
                let brand = stringValue(in: statement, column: 1)
                let imageURL = stringValue(in: statement, column: 2)
                    .flatMap(URL.init(string:))

                foods.append(
                    StoredFood(
                        name: name,
                        brand: brand,
                        imageURL: imageURL
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
}
