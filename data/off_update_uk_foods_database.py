#!/usr/bin/env python3

import csv
from itertools import islice
import sqlite3
import sys
import time

from off_create_uk_foods_database import (
    COUNTRY_ISO_ALPHA2_CODE,
    INPUT_CSV_PATH,
    NUTRIENTS,
    OUTPUT_DATABASE_PATH,
    SCHEMA_VERSION,
    SOURCE_NAME,
    clean_text,
    insert_food,
    insert_food_nutrients,
    parse_timestamp,
)

DATABASE_PATH = OUTPUT_DATABASE_PATH
ROW_LIMIT: int | None = None

def require_reference_id(
    database: sqlite3.Connection,
    query: str,
    value: str,
    reference_name: str,
) -> int:
    row = database.execute(query, (value,)).fetchone()
    if row is None:
        raise ValueError(
            f"{reference_name} '{value}' was not found in {DATABASE_PATH}"
        )
    return int(row[0])


def validate_csv_columns(reader: csv.DictReader) -> None:
    required_columns = {
        "code",
        "product_name",
        "generic_name",
        "brands",
        "image_small_url",
        "image_url",
        "states",
        "quantity",
        "serving_quantity",
        "serving_size",
        "created_t",
        "last_modified_t",
        "product_quantity",
        *(column for column, _, _, _ in NUTRIENTS),
    }
    missing_columns = required_columns.difference(reader.fieldnames or [])
    if missing_columns:
        missing = ", ".join(sorted(missing_columns))
        raise ValueError(f"Input CSV is missing required columns: {missing}")


def validate_database(database: sqlite3.Connection) -> None:
    schema_version = database.execute("PRAGMA user_version").fetchone()[0]
    if schema_version != SCHEMA_VERSION:
        raise ValueError(
            "Database schema version does not match the importer: "
            f"expected {SCHEMA_VERSION}, found {schema_version}"
        )

    required_tables = {
        "Countries",
        "DatabaseMetadata",
        "FoodNutrients",
        "Foods",
        "FoodSearch",
        "MeasurementUnits",
        "Nutrients",
        "Sources",
    }
    existing_tables = {
        row[0]
        for row in database.execute(
            "SELECT name FROM sqlite_master WHERE type IN ('table', 'view')"
        )
    }
    missing_tables = required_tables.difference(existing_tables)
    if missing_tables:
        missing = ", ".join(sorted(missing_tables))
        raise ValueError(f"Database is missing required tables: {missing}")

    food_columns = {
        row[1]: row[2].upper()
        for row in database.execute("PRAGMA table_info(Foods)")
    }
    required_food_columns = {
        "total_energy_cal": "REAL",
        "serving_size_grams": "REAL",
    }
    invalid_food_columns = [
        f"{name} {column_type}"
        for name, column_type in required_food_columns.items()
        if food_columns.get(name) != column_type
    ]
    if invalid_food_columns:
        invalid = ", ".join(invalid_food_columns)
        raise ValueError(
            f"Database Foods table is missing updated columns: {invalid}"
        )


def update_database() -> None:
    if not INPUT_CSV_PATH.is_file():
        raise FileNotFoundError(f"Input CSV was not found: {INPUT_CSV_PATH}")
    if not DATABASE_PATH.is_file():
        raise FileNotFoundError(f"Database was not found: {DATABASE_PATH}")

    generated_at = int(time.time())
    rows_processed = 0
    new_foods_inserted = 0
    new_versions_inserted = 0
    unchanged_or_older_skipped = 0
    invalid_rows_skipped = 0
    nutrients_inserted = 0

    with INPUT_CSV_PATH.open("r", encoding="utf-8", newline="") as source:
        reader = csv.DictReader(source)
        validate_csv_columns(reader)

        products = reader if ROW_LIMIT is None else islice(reader, ROW_LIMIT)

        with sqlite3.connect(DATABASE_PATH) as database:
            database.execute("PRAGMA foreign_keys = ON")
            validate_database(database)

            source_id = require_reference_id(
                database,
                "SELECT id FROM Sources WHERE name = ?",
                SOURCE_NAME,
                "Source",
            )
            country_id = require_reference_id(
                database,
                "SELECT id FROM Countries WHERE iso_alpha2_code = ?",
                COUNTRY_ISO_ALPHA2_CODE,
                "Country",
            )
            unit_ids = dict(
                database.execute("SELECT short_name, id FROM MeasurementUnits")
            )
            nutrient_ids = dict(
                database.execute("SELECT short_name, id FROM Nutrients")
            )

            for product in products:
                rows_processed += 1
                origin_id = clean_text(product.get("code"))
                incoming_version = (
                    parse_timestamp(product.get("last_modified_t")) or 1
                )

                if origin_id is None:
                    invalid_rows_skipped += 1
                    continue

                latest_version_row = database.execute(
                    """
                    SELECT MAX(version)
                    FROM Foods
                    WHERE source_id = ?
                      AND country_id = ?
                      AND origin_id = ?
                    """,
                    (source_id, country_id, origin_id),
                ).fetchone()
                latest_version = latest_version_row[0]

                if (
                    latest_version is not None
                    and incoming_version <= latest_version
                ):
                    unchanged_or_older_skipped += 1
                    continue

                food_id = insert_food(
                    database,
                    product,
                    source_id,
                    country_id,
                    generated_at,
                )
                if food_id is None:
                    invalid_rows_skipped += 1
                    continue

                if latest_version is None:
                    new_foods_inserted += 1
                else:
                    new_versions_inserted += 1

                nutrients_inserted += insert_food_nutrients(
                    database,
                    product,
                    food_id,
                    unit_ids,
                    nutrient_ids,
                    generated_at,
                )

            database.execute(
                """
                UPDATE DatabaseMetadata
                SET generated_at = ?
                WHERE id = 1
                """,
                (generated_at,),
            )
            database.execute(
                "INSERT INTO FoodSearch(FoodSearch) VALUES ('rebuild')"
            )
            database.execute("PRAGMA optimize")

    print(f"Read {rows_processed} CSV rows")
    print(f"Inserted {new_foods_inserted} new foods")
    print(f"Inserted {new_versions_inserted} newer food versions")
    print(f"Skipped {unchanged_or_older_skipped} unchanged or older versions")
    print(f"Skipped {invalid_rows_skipped} invalid rows")
    print(f"Inserted {nutrients_inserted} food nutrient values")
    print(f"Updated {DATABASE_PATH}")


def main() -> None:
    if ROW_LIMIT is not None and ROW_LIMIT <= 0:
        raise ValueError("ROW_LIMIT must be greater than zero or None")

    csv.field_size_limit(sys.maxsize)
    update_database()


if __name__ == "__main__":
    main()
