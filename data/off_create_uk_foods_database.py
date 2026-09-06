#!/usr/bin/env python3

import csv
from itertools import islice
import math
from pathlib import Path
import sqlite3
import sys
import time
import re


SCRIPT_DIRECTORY = Path(__file__).resolve().parent
INPUT_CSV_PATH = SCRIPT_DIRECTORY / "uk_products_updated_after_2023.csv"
OUTPUT_DATABASE_PATH = SCRIPT_DIRECTORY / "uk_foods.sqlite"
ROW_LIMIT = 10_000
SCHEMA_VERSION = 1
SOURCE_NAME = "Open Food Facts"
SOURCE_URL = "https://world.openfoodfacts.org/"
SOURCE_LICENCE = "Open Database Licence (ODbL) 1.0"
SOURCE_ATTRIBUTION = "Open Food Facts contributors"
COUNTRY_NAME = "United Kingdom"
COUNTRY_ISO_ALPHA2_CODE = "GB"
BASIS_AMOUNT = 100.0
BASIS_UNIT_SHORT_NAME = "g"
MEASUREMENT_UNITS = (
    ("Gram", "g", None, 1.0),
    ("Ounce", "oz", None, 28.349523125),
    ("Kilogram", "kg", None, 1_000.0),
    ("Tablet", "tablet", "tablets", None),
    ("Litre", "l", None, None),
    ("Millilitre", "ml", None, None),
    ("Capsule", "capsule", "capsules", None),
    ("Item", "item", "items", None),
    ("Cup", "cup", "cups", None),
    ("Kilocalorie", "kcal", None, None),
)

NUTRIENTS = (
    ("energy-kcal_100g", "Energy", "energy", "kcal"),
    ("fat_100g", "Fat", "fat", "g"),
    ("saturated-fat_100g", "Saturated fat", "sat_fat", "g"),
    ("carbohydrates_100g", "Carbohydrates", "carbs", "g"),
    ("sugars_100g", "Sugars", "sugars", "g"),
    ("fiber_100g", "Fiber", "fiber", "g"),
    ("proteins_100g", "Protein", "protein", "g"),
    ("salt_100g", "Salt", "salt", "g"),
    ("sodium_100g", "Sodium", "sodium", "g"),
    ("water_100g", "Water", "water", "g"),
    ("caffeine_100g", "Caffeine", "caffeine", "g"),
)

CREATE_SCHEMA_SQL = """
CREATE TABLE MeasurementUnits (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL UNIQUE,
    short_name TEXT NOT NULL UNIQUE,
    plural_form TEXT,
    gram_convertion_value REAL,
    date_added INTEGER NOT NULL
);

CREATE TABLE Sources (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL UNIQUE,
    url TEXT,
    date_added INTEGER NOT NULL
);

CREATE TABLE Countries (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL UNIQUE,
    iso_alpha2_code TEXT NOT NULL UNIQUE CHECK (length(iso_alpha2_code) = 2),
    date_added INTEGER NOT NULL
);

CREATE TABLE Foods (
    id INTEGER PRIMARY KEY,
    source_id INTEGER NOT NULL,
    country_id INTEGER NOT NULL,
    origin_id TEXT NOT NULL,
    version INTEGER NOT NULL,
    name TEXT NOT NULL,
    brand TEXT,
    barcode TEXT,
    small_image_url TEXT,
    image_url TEXT,
    quantity REAL,
    measurement_unit_id INTEGER NOT NULL,
    total_energy REAL,
    total_amount_grams REAL,
    serving_size_grams TEXT,
    date_added INTEGER NOT NULL,
    date_updated INTEGER,
    UNIQUE (source_id, country_id, origin_id, version),
    FOREIGN KEY (source_id) REFERENCES Sources(id) ON DELETE RESTRICT,
    FOREIGN KEY (country_id) REFERENCES Countries(id) ON DELETE RESTRICT
);

CREATE INDEX foods_barcode_idx ON Foods (barcode);
CREATE INDEX foods_country_id_idx ON Foods (country_id);

CREATE TABLE Nutrients (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL UNIQUE,
    short_name TEXT NOT NULL UNIQUE,
    measurement_unit_id INTEGER NOT NULL,
    date_added INTEGER NOT NULL,
    FOREIGN KEY (measurement_unit_id)
        REFERENCES MeasurementUnits(id) ON DELETE RESTRICT
);

CREATE TABLE FoodNutrients (
    food_id INTEGER NOT NULL,
    nutrient_id INTEGER NOT NULL,
    amount REAL NOT NULL CHECK (amount >= 0),
    basis_amount REAL NOT NULL CHECK (basis_amount > 0),
    basis_unit_id INTEGER NOT NULL,
    date_added INTEGER NOT NULL,
    PRIMARY KEY (food_id, nutrient_id),
    FOREIGN KEY (food_id) REFERENCES Foods(id) ON DELETE CASCADE,
    FOREIGN KEY (nutrient_id) REFERENCES Nutrients(id) ON DELETE RESTRICT,
    FOREIGN KEY (basis_unit_id)
        REFERENCES MeasurementUnits(id) ON DELETE RESTRICT
);

CREATE TABLE DatabaseMetadata (
    id INTEGER PRIMARY KEY CHECK (id = 1),
    schema_version INTEGER NOT NULL,
    dataset_version TEXT,
    generated_at INTEGER NOT NULL,
    source_licence TEXT NOT NULL,
    source_attribution TEXT NOT NULL
);

CREATE VIRTUAL TABLE FoodSearch USING fts5(
    name,
    brand,
    content = Foods,
    content_rowid = id
);
"""

def clean_text(value: str | None) -> str | None:
    if value is None:
        return None
    cleaned = value.strip()
    return cleaned or None

def parse_timestamp(value: str | None) -> int | None:
    try:
        return int(float(value)) if value else None
    except (TypeError, ValueError):
        return None

def parse_non_negative_number(value: str | None) -> float | None:
    try:
        number = float(value) if value else None
    except (TypeError, ValueError):
        return None

    if number is None or not math.isfinite(number) or number < 0:
        return None
    return number

def parse_positive_number(value: str | None) -> float | None:
    number = parse_non_negative_number(value)
    return number if number is not None and number > 0 else None

def get_digits(value: str | None) -> float | None:
    match = re.search(r"[0-9]+(?:[.,][0-9]+)?", value or "")
    return float(match.group().replace(",", ".")) if match else None

def get_measurment_unit_id(quantity: float, quantity_txt: str) -> int:
    if 'kg' in quantity_txt:
        return 3
    elif 'oz' in quantity_txt:
        return 2
    elif 'tablet' in quantity_txt:
        return 4
    elif 'capsule' in quantity_txt:
        return 7
    elif 'ml' in quantity_txt:
        return 6
    elif 'l' in quantity_txt:
        return 5
    elif 'cup' in quantity_txt:
        return 9
    elif quantity < 5:
        return 8
    else:
        return 1
    
def create_reference_data(
    database: sqlite3.Connection,
    generated_at: int,
) -> tuple[int, int, dict[str, int], dict[str, int]]:
    source_cursor = database.execute(
        """
        INSERT INTO Sources (name, url, date_added)
        VALUES (?, ?, ?)
        """,
        (
            SOURCE_NAME,
            SOURCE_URL,
            generated_at,
        ),
    )
    source_id = source_cursor.lastrowid

    country_cursor = database.execute(
        """
        INSERT INTO Countries (name, iso_alpha2_code, date_added)
        VALUES (?, ?, ?)
        """,
        (COUNTRY_NAME, COUNTRY_ISO_ALPHA2_CODE, generated_at),
    )
    country_id = country_cursor.lastrowid

    database.executemany(
        """
        INSERT INTO MeasurementUnits (
            name,
            short_name,
            plural_form,
            gram_convertion_value,
            date_added
        )
        VALUES (?, ?, ?, ?, ?)
        """,
        (
            (
                name,
                short_name,
                plural_form,
                gram_convertion_value,
                generated_at,
            )
            for name, short_name, plural_form, gram_convertion_value
            in MEASUREMENT_UNITS
        ),
    )
    unit_ids = dict(
        database.execute("SELECT short_name, id FROM MeasurementUnits")
    )

    database.executemany(
        """
        INSERT INTO Nutrients (
            name,
            short_name,
            measurement_unit_id,
            date_added
        )
        VALUES (?, ?, ?, ?)
        """,
        (
            (name, short_name, unit_ids[unit], generated_at)
            for _, name, short_name, unit in NUTRIENTS
        ),
    )
    nutrient_ids = dict(database.execute("SELECT short_name, id FROM Nutrients"))

    database.execute(
        """
        INSERT INTO DatabaseMetadata (
            id,
            schema_version,
            dataset_version,
            generated_at,
            source_licence,
            source_attribution
        )
        VALUES (1, ?, ?, ?, ?, ?)
        """,
        (
            SCHEMA_VERSION,
            None,
            generated_at,
            SOURCE_LICENCE,
            SOURCE_ATTRIBUTION,
        ),
    )

    return source_id, country_id, unit_ids, nutrient_ids

def validate_food_has_nutrients(product: dict[str, str]) -> bool:
    cal = parse_non_negative_number(product.get("energy-kcal_100g"))
    fat = parse_non_negative_number(product.get("fat_100g"))
    carbs = parse_non_negative_number(product.get("carbohydrates_100g"))
    protein = parse_non_negative_number(product.get("proteins_100g"))
    water = parse_non_negative_number(product.get("water_100g"))

    return (cal and fat and carbs and protein) or water  

def insert_food(
    database: sqlite3.Connection,
    product: dict[str, str],
    source_id: int,
    country_id: int,
    generated_at: int,
) -> int | None:
    if not validate_food_has_nutrients(product):
        return None 
    
    name = clean_text(product.get("product_name")) or clean_text(product.get("generic_name")) 

    if not name:
        return None

    name = name.capitalize()

    serving_quantity = parse_non_negative_number(product.get("serving_quantity"))

    total_amount_grams = parse_positive_number(product.get("product_quantity")) or serving_quantity
    
    quantity_txt = clean_text(product.get("quantity"))
    quantity = get_digits(quantity_txt) if quantity_txt else serving_quantity

    if not quantity or not total_amount_grams:
        return None
    
    measurement_unit_id = get_measurment_unit_id(quantity, quantity_txt) if quantity_txt else 1

    if not total_amount_grams:
        return None
    
    origin_id = clean_text(product.get("code"))

    date_added = parse_timestamp(product.get("created_t")) or generated_at
    date_updated = parse_timestamp(product.get("last_modified_t"))
    version = date_updated or 1
    energy_per_100g = parse_non_negative_number(
        product.get("energy-kcal_100g")
    )
    total_energy = (
        energy_per_100g * total_amount_grams / BASIS_AMOUNT
        if energy_per_100g is not None and total_amount_grams is not None
        else None
    )

    photo = clean_text(product.get("image_url")) if 'photos-validated' in product.get("states") else None
    small_photo = clean_text(product.get("image_small_url")) if 'photos-validated' in product.get("states") else None

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
            total_energy,
            total_amount_grams,
            serving_size_grams,
            date_added,
            date_updated
        )
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """,
        (
            source_id,
            country_id,
            origin_id,
            version,
            name,
            clean_text(product.get("brands")).capitalize() if product.get("brands") else None,
            origin_id,
            small_photo,
            photo,
            quantity,
            measurement_unit_id,
            total_energy,
            total_amount_grams,
            clean_text(product.get("serving_size")),
            date_added,
            date_updated,
        ),
    )

    if cursor.rowcount == 0:
        return None
    return cursor.lastrowid

def insert_food_nutrients(
    database: sqlite3.Connection,
    product: dict[str, str],
    food_id: int,
    unit_ids: dict[str, int],
    nutrient_ids: dict[str, int],
    generated_at: int,
) -> int:
    nutrient_rows = []

    for csv_column, _, short_name, _ in NUTRIENTS:
        amount = parse_non_negative_number(product.get(csv_column))
        if amount is None:
            continue

        nutrient_rows.append(
            (
                food_id,
                nutrient_ids[short_name],
                amount,
                BASIS_AMOUNT,
                unit_ids[BASIS_UNIT_SHORT_NAME],
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

def build_database() -> None:
    generated_at = int(time.time())
    temporary_path = OUTPUT_DATABASE_PATH.with_name(
        f".{OUTPUT_DATABASE_PATH.name}.tmp"
    )
    temporary_path.unlink(missing_ok=True)

    rows_processed = 0
    foods_inserted = 0
    nutrients_inserted = 0

    try:
        with INPUT_CSV_PATH.open("r", encoding="utf-8", newline="") as source:
            reader = csv.DictReader(source)
            required_columns = {
                "code",
                "product_name",
                "generic_name",
                "brands",
                "image_small_url",
                "image_url",
                "created_t",
                "last_modified_t",
                "product_quantity",
                "serving_size",
                *(column for column, _, _, _ in NUTRIENTS),
            }
            missing_columns = required_columns.difference(reader.fieldnames or [])
            if missing_columns:
                missing = ", ".join(sorted(missing_columns))
                raise ValueError(f"Input CSV is missing required columns: {missing}")

            with sqlite3.connect(temporary_path) as database:
                database.execute("PRAGMA foreign_keys = ON")
                database.execute(f"PRAGMA user_version = {SCHEMA_VERSION}")
                database.executescript(CREATE_SCHEMA_SQL)

                source_id, country_id, unit_ids, nutrient_ids = (
                    create_reference_data(
                        database,
                        generated_at,
                    )
                )

                for product in islice(reader, ROW_LIMIT):
                    rows_processed += 1
                    food_id = insert_food(
                        database,
                        product,
                        source_id,
                        country_id,
                        generated_at,
                    )
                    if food_id is None:
                        continue

                    foods_inserted += 1
                    nutrients_inserted += insert_food_nutrients(
                        database,
                        product,
                        food_id,
                        unit_ids,
                        nutrient_ids,
                        generated_at,
                    )

                database.execute(
                    "INSERT INTO FoodSearch(FoodSearch) VALUES ('rebuild')"
                )
                database.execute("PRAGMA optimize")

        temporary_path.replace(OUTPUT_DATABASE_PATH)
    except Exception:
        temporary_path.unlink(missing_ok=True)
        raise

    print(f"Read {rows_processed} CSV rows")
    print(f"Inserted {foods_inserted} foods")
    print(f"Inserted {nutrients_inserted} food nutrient values")
    print(f"Created {OUTPUT_DATABASE_PATH}")


def main() -> None:
    if ROW_LIMIT <= 0:
        raise ValueError("ROW_LIMIT must be greater than zero")

    csv.field_size_limit(sys.maxsize)
    build_database()


if __name__ == "__main__":
    main()
