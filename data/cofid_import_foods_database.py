#!/usr/bin/env python3

import csv
import math
from pathlib import Path
import sqlite3
import sys
import time

SCRIPT_DIRECTORY = Path(__file__).resolve().parent
DATABASE_PATH = SCRIPT_DIRECTORY / "uk_foods.sqlite"
COUNTRY_ISO_ALPHA2_CODE = "GB"
SCHEMA_VERSION = 1
QUANTITY_GRAMS = 100.0
SERVING_SIZE_GRAMS = 100.0
TOTAL_AMOUNT_GRAMS = 100.0

DATASETS = (
    (
        SCRIPT_DIRECTORY / "CoFID_oldFoods.csv",
        "CoFID old foods",
        1,
    ),
    (
        SCRIPT_DIRECTORY
        / "McCance_Widdowsons_Composition_of_Foods_Integrated_Dataset_2021..csv",
        "McCance and Widdowson's Composition of Foods 2021",
        2021,
    ),
)

NUTRIENT_COLUMNS = {
    "energy": "KCALS",
    "fat": "FAT",
    "sat_fat": "SATFOD",
    "carbs": "CHO",
    "sugars": "TOTSUG",
    "fiber": "AOACFIB",
    "protein": "PROT",
    "water": "WATER",
}

def clean_text(value: str | None) -> str | None:
    if value is None:
        return None
    cleaned = value.strip()
    return cleaned or None

def parse_non_negative_number(value: str | None) -> float | None:
    try:
        number = float(value) if value else None
    except (TypeError, ValueError):
        return None

    if number is None or not math.isfinite(number) or number < 0:
        return None
    return number

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

def get_or_create_source_id(
    database: sqlite3.Connection,
    source_name: str,
    generated_at: int,
) -> int:
    database.execute(
        """
        INSERT OR IGNORE INTO Sources (name, url, date_added)
        VALUES (?, NULL, ?)
        """,
        (source_name, generated_at),
    )
    return require_reference_id(
        database,
        "SELECT id FROM Sources WHERE name = ?",
        source_name,
        "Source",
    )


def validate_database(database: sqlite3.Connection) -> None:
    schema_version_row = database.execute(
        "SELECT schema_version FROM DatabaseMetadata WHERE id = 1"
    ).fetchone()
    if schema_version_row is None:
        raise ValueError("Database metadata row was not found")

    schema_version = schema_version_row[0]
    if schema_version != SCHEMA_VERSION:
        raise ValueError(
            "Database schema version does not match the importer: "
            f"expected {SCHEMA_VERSION}, found {schema_version}"
        )

def column_indexes(
    display_headers: list[str],
    nutrient_headers: list[str],
) -> tuple[int, int, dict[str, int]]:
    display_indexes = {
        header.strip().lstrip("\ufeff"): index
        for index, header in enumerate(display_headers)
        if header.strip()
    }
    nutrient_indexes = {
        header.strip(): index
        for index, header in enumerate(nutrient_headers)
        if header.strip()
    }

    missing_display_headers = {
        header
        for header in ("Food Code", "Food Name")
        if header not in display_indexes
    }
    missing_nutrient_headers = set(NUTRIENT_COLUMNS.values()).difference(
        nutrient_indexes
    )
    if missing_display_headers or missing_nutrient_headers:
        missing = sorted(missing_display_headers | missing_nutrient_headers)
        raise ValueError(
            "Input CSV is missing required columns: " + ", ".join(missing)
        )

    mapped_nutrients = {
        nutrient_short_name: nutrient_indexes[column_name]
        for nutrient_short_name, column_name in NUTRIENT_COLUMNS.items()
    }
    return (
        display_indexes["Food Code"],
        display_indexes["Food Name"],
        mapped_nutrients,
    )


def value_at(row: list[str], index: int) -> str | None:
    return row[index] if index < len(row) else None

def insert_food(
    database: sqlite3.Connection,
    source_id: int,
    country_id: int,
    gram_unit_id: int,
    origin_id: str,
    version: int,
    name: str,
    total_energy_cal: float | None,
    generated_at: int,
) -> int | None:
    cursor = database.execute(
        """
        INSERT OR IGNORE INTO Foods (
            source_id,
            country_id,
            origin_id,
            version,
            name,
            brand,
            barcode,
            small_image_url,
            image_url,
            quantity,
            measurement_unit_id,
            total_energy_cal,
            total_amount_grams,
            serving_size_grams,
            date_added,
            date_updated
        )
        VALUES (?, ?, ?, ?, ?, NULL, NULL, NULL, NULL, ?, ?, ?, ?, ?, ?, NULL)
        """,
        (
            source_id,
            country_id,
            origin_id,
            version,
            name,
            QUANTITY_GRAMS,
            gram_unit_id,
            total_energy_cal,
            TOTAL_AMOUNT_GRAMS,
            SERVING_SIZE_GRAMS,
            generated_at,
        ),
    )
    return cursor.lastrowid if cursor.rowcount > 0 else None

def insert_nutrients(
    database: sqlite3.Connection,
    row: list[str],
    nutrient_column_indexes: dict[str, int],
    food_id: int,
    nutrient_ids: dict[str, int],
    gram_unit_id: int,
    generated_at: int,
) -> int:
    nutrient_rows = []

    for nutrient_short_name, column_index in nutrient_column_indexes.items():
        amount = parse_non_negative_number(value_at(row, column_index))
        if amount is None:
            continue

        nutrient_rows.append(
            (
                food_id,
                nutrient_ids[nutrient_short_name],
                amount,
                TOTAL_AMOUNT_GRAMS,
                gram_unit_id,
                generated_at,
            )
        )

    database.executemany(
        """
        INSERT INTO FoodNutrients (
            food_id,
            nutrient_id,
            amount,
            basis_amount,
            basis_unit_id,
            date_added
        )
        VALUES (?, ?, ?, ?, ?, ?)
        """,
        nutrient_rows,
    )
    return len(nutrient_rows)

def import_dataset(
    database: sqlite3.Connection,
    csv_path: Path,
    source_name: str,
    version: int,
    country_id: int,
    gram_unit_id: int,
    nutrient_ids: dict[str, int],
    generated_at: int,
) -> tuple[int, int, int, int]:
    source_id = get_or_create_source_id(database, source_name, generated_at)
    rows_read = 0
    foods_inserted = 0
    duplicate_foods_skipped = 0
    nutrients_inserted = 0

    with csv_path.open("r", encoding="utf-8-sig", newline="") as source:
        reader = csv.reader(source)
        display_headers = next(reader)
        nutrient_headers = next(reader)
        next(reader)
        food_code_index, food_name_index, nutrient_column_indexes = (
            column_indexes(display_headers, nutrient_headers)
        )

        for row in reader:
            rows_read += 1
            origin_id = clean_text(value_at(row, food_code_index))
            name = clean_text(value_at(row, food_name_index))
            if origin_id is None or name is None:
                continue

            energy_column_index = nutrient_column_indexes["energy"]
            total_energy_cal = parse_non_negative_number(
                value_at(row, energy_column_index)
            )
            food_id = insert_food(
                database,
                source_id,
                country_id,
                gram_unit_id,
                origin_id,
                version,
                name,
                total_energy_cal,
                generated_at,
            )
            if food_id is None:
                duplicate_foods_skipped += 1
                continue

            foods_inserted += 1
            nutrients_inserted += insert_nutrients(
                database,
                row,
                nutrient_column_indexes,
                food_id,
                nutrient_ids,
                gram_unit_id,
                generated_at,
            )

    return (
        rows_read,
        foods_inserted,
        duplicate_foods_skipped,
        nutrients_inserted,
    )


def import_foods() -> None:
    if not DATABASE_PATH.is_file():
        raise FileNotFoundError(f"Database was not found: {DATABASE_PATH}")
    for csv_path, _, _ in DATASETS:
        if not csv_path.is_file():
            raise FileNotFoundError(f"Input CSV was not found: {csv_path}")

    generated_at = int(time.time())

    with sqlite3.connect(DATABASE_PATH) as database:
        database.execute("PRAGMA foreign_keys = ON")
        validate_database(database)

        country_id = require_reference_id(
            database,
            "SELECT id FROM Countries WHERE iso_alpha2_code = ?",
            COUNTRY_ISO_ALPHA2_CODE,
            "Country",
        )
        gram_unit_id = require_reference_id(
            database,
            "SELECT id FROM MeasurementUnits WHERE short_name = ?",
            "g",
            "Measurement unit",
        )
        nutrient_ids = dict(
            database.execute("SELECT short_name, id FROM Nutrients")
        )
        missing_nutrients = set(NUTRIENT_COLUMNS).difference(nutrient_ids)
        if missing_nutrients:
            missing = ", ".join(sorted(missing_nutrients))
            raise ValueError(f"Database is missing nutrients: {missing}")

        for csv_path, source_name, version in DATASETS:
            rows_read, foods_inserted, duplicates_skipped, nutrients_inserted = (
                import_dataset(
                    database,
                    csv_path,
                    source_name,
                    version,
                    country_id,
                    gram_unit_id,
                    nutrient_ids,
                    generated_at,
                )
            )
            print(f"{source_name}:")
            print(f"  Read {rows_read} rows")
            print(f"  Inserted {foods_inserted} foods")
            print(f"  Skipped {duplicates_skipped} duplicate foods")
            print(f"  Inserted {nutrients_inserted} nutrient values")

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

    print(f"Updated {DATABASE_PATH}")


def main() -> None:
    csv.field_size_limit(sys.maxsize)
    import_foods()


if __name__ == "__main__":
    main()
