#!/usr/bin/env python3

import csv
from pathlib import Path
import re
import sys


SCRIPT_DIRECTORY = Path(__file__).resolve().parent
INPUT_CSV_PATH = SCRIPT_DIRECTORY / "en.openfoodfacts.org.products.csv"
MINIMUM_YEAR = 2023
COUNTRY_NAMES = {
    "uk",
    "gb",
    "unitedkingdom",
    "greatbritain",
    "britain",
    "unitedkingdomofgreatbritainandnorthernireland",
    "england",
    "scotland",
    "wales",
    "northernireland",
}
OUTPUT_CSV_PATH = (
    SCRIPT_DIRECTORY
    / f"uk_products_updated_after_{MINIMUM_YEAR}.csv"
)


def is_uk_country(countries: str) -> bool:
    for country in re.split(r"[,;|]", countries):
        country_without_language_prefix = re.sub(
            r"^[a-z]{2,3}:",
            "",
            country.casefold().strip(),
        )
        normalized_country = re.sub(
            r"[^a-z]",
            "",
            country_without_language_prefix,
        )
        if normalized_country in COUNTRY_NAMES:
            return True
    return False


def was_updated_after_2023(last_modified_datetime: str) -> bool:
    year_match = re.match(r"\s*(\d{4})", last_modified_datetime)
    return year_match is not None and int(year_match.group(1)) > MINIMUM_YEAR


def main() -> None:
    csv.field_size_limit(sys.maxsize)

    with INPUT_CSV_PATH.open("r", encoding="utf-8", newline="") as source:
        with OUTPUT_CSV_PATH.open("w", encoding="utf-8", newline="") as destination:
            reader = csv.DictReader(source, delimiter="\t")
            required_columns = {
                "brands",
                "countries_en",
                "last_modified_datetime",
            }
            missing_columns = required_columns.difference(reader.fieldnames or [])
            if missing_columns:
                missing = ", ".join(sorted(missing_columns))
                raise ValueError(f"Input file is missing required columns: {missing}")

            writer = csv.DictWriter(
                destination,
                fieldnames=reader.fieldnames,
                delimiter=",",
                lineterminator="\n",
            )
            writer.writeheader()

            products_written = 0
            for product in reader:
                if not product.get("brands", "").strip():
                    continue
                if not is_uk_country(product.get("countries_en", "")):
                    continue
                if not was_updated_after_2023(
                    product.get("last_modified_datetime", "")
                ):
                    continue

                writer.writerow(product)
                products_written += 1

    print(f"Wrote {products_written} products to {OUTPUT_CSV_PATH}")


if __name__ == "__main__":
    main()
