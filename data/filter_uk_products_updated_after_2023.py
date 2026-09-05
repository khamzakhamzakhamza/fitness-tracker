#!/usr/bin/env python3

import argparse
import csv
from pathlib import Path
import re
import sys


SCRIPT_DIRECTORY = Path(__file__).resolve().parent
DEFAULT_INPUT = SCRIPT_DIRECTORY / "data"
DEFAULT_OUTPUT = SCRIPT_DIRECTORY / "uk_products_updated_after_2023.csv"
MINIMUM_YEAR = 2023
UK_COUNTRY_NAMES = {
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


def parse_arguments() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Filter the Open Food Facts TSV export to UK products updated after 2023."
    )
    parser.add_argument("input", nargs="?", type=Path, default=DEFAULT_INPUT)
    parser.add_argument("output", nargs="?", type=Path, default=DEFAULT_OUTPUT)
    return parser.parse_args()


def is_uk_country(countries: str) -> bool:
    for country in re.split(r"[,;|]", countries):
        normalized_country = re.sub(r"[^a-z]", "", country.casefold())
        if normalized_country in UK_COUNTRY_NAMES:
            return True
    return False


def was_updated_after_2023(last_modified_datetime: str) -> bool:
    year_match = re.match(r"\s*(\d{4})", last_modified_datetime)
    return year_match is not None and int(year_match.group(1)) > MINIMUM_YEAR


def main() -> None:
    arguments = parse_arguments()
    csv.field_size_limit(sys.maxsize)

    with arguments.input.open("r", encoding="utf-8", newline="") as source:
        with arguments.output.open("w", encoding="utf-8", newline="") as destination:
            reader = csv.DictReader(source, delimiter="\t")
            required_columns = {"countries_en", "last_modified_datetime"}
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
                if not is_uk_country(product.get("countries_en", "")):
                    continue
                if not was_updated_after_2023(
                    product.get("last_modified_datetime", "")
                ):
                    continue

                writer.writerow(product)
                products_written += 1

    print(f"Wrote {products_written} products to {arguments.output}")


if __name__ == "__main__":
    main()
