#!/usr/bin/env python3

import csv
import gzip
from pathlib import Path
import re
import sys
from typing import TextIO


SCRIPT_DIRECTORY = Path(__file__).resolve().parent
INPUT_CSV_PATH = SCRIPT_DIRECTORY / "en.openfoodfacts.org.products.csv.gz"
MINIMUM_YEAR = 2023
OUTPUT_CSV_PATH = (
    SCRIPT_DIRECTORY
    / f"common_brand_products_updated_after_{MINIMUM_YEAR}.csv"
)

BRAND_FIELDS = (
    "brands",
    "brands_tags",
    "brands_en",
    "brand_owner",
)

BRAND_REGEXES = (
    r"\b7[\W_]*up\b",
    r"\bactivia\b",
    r"\bbabybel\b",
    r"\bbarilla\b",
    r"\bben(?:[\W_]*(?:and|n)[\W_]*)?[\W_]*jerry(?:['’]?s)?\b",
    r"\bbirds[\W_]*eye\b",
    r"\bbounty\b",
    r"\bcadbury\b",
    r"\bcarte[\W_]*d[\W_]*(?:or)?\b",
    r"\bcheetos\b",
    r"\bcoca[\W_]*cola\b",
    r"\bcosta\b",
    r"\bdanone\b",
    r"\bdoritos\b",
    r"\bdr[\W_]*pepper\b",
    r"\bfanta\b",
    r"\bferrero\b",
    r"\bgalaxy\b",
    r"\bh(?:a|ä)agen[\W_]*dazs\b",
    r"\bharibo\b",
    r"\bheinz\b",
    r"\bhellmann(?:['’]?s)?\b",
    r"\binnocent\b",
    r"\bkellogg(?:['’]?s)?\b",
    r"\bkettle\b",
    r"\bkinder\b",
    r"\bkit[\W_]*kat\b",
    r"\bknorr\b",
    r"\blay(?:['’]?s)?\b",
    r"\blindt\b",
    r"\blipton\b",
    r"\bm[\W_]*(?:and[\W_]*)?m(?:['’]?s)?\b",
    r"\bmaggi\b",
    r"\bmagnum\b",
    r"\bmars\b",
    r"\bmc[\W_]*vitie(?:['’]?s)?\b",
    r"\bmilka\b",
    r"\bmilky[\W_]*way\b",
    r"\bmonster[\W_]*energy\b",
    r"\bmountain[\W_]*dew\b",
    r"\bm(?:u|ü)ller\b",
    r"\bnescaf(?:e|é)\b",
    r"\bnestl(?:e|é)\b",
    r"\bnutella\b",
    r"\bold[\W_]*el[\W_]*paso\b",
    r"\boreo\b",
    r"\bpatak(?:['’]?s)?\b",
    r"\bpepsi\b",
    r"\bphiladelphia\b",
    r"\bpringles\b",
    r"\bquaker\b",
    r"\bred[\W_]*bull\b",
    r"\britz\b",
    r"\bschweppes\b",
    r"\bskittles\b",
    r"\bsnickers\b",
    r"\bsprite\b",
    r"\btoblerone\b",
    r"\btropicana\b",
    r"\btwix\b",
    r"\bwalkers\b",
    r"\bwrigley(?:['’]?s)?\b",
    r"\byakult\b",
    r"\byoplait\b",
    r"\bbaskin[\W_]*robbins\b",
    r"\bburger[\W_]*king\b",
    r"\bchipotle\b",
    r"\bcinnabon\b",
    r"\bdairy[\W_]*queen\b",
    r"\bdomino(?:['’]?s)?\b",
    r"\bdunkin(?:g)?(?:['’])?\b",
    r"\bfive[\W_]*guys\b",
    r"\bgreggs\b",
    r"\bkfc\b",
    r"\bkrispy[\W_]*kreme\b",
    r"\blittle[\W_]*caesars\b",
    r"\bmc[\W_]*donald(?:['’]?s)?\b",
    r"\bnando(?:['’]?s)?\b",
    r"\bpapa[\W_]*john(?:['’]?s)?\b",
    r"\bpizza[\W_]*hut\b",
    r"\bpizza[\W_]*express\b",
    r"\bpopeyes\b",
    r"\bpret(?:[\W_]*a)?[\W_]*manger\b",
    r"\bshake[\W_]*shack\b",
    r"\bstarbucks\b",
    r"\bsubway\b",
    r"\btaco[\W_]*bell\b",
    r"\btim[\W_]*hortons\b",
    r"\bwagamama\b",
    r"\bwendy(?:['’]?s)?\b",
)

BRAND_PATTERNS = tuple(
    re.compile(pattern, re.IGNORECASE)
    for pattern in BRAND_REGEXES
)


def brand_values(product: dict[str, str]) -> list[str]:
    values: list[str] = []
    for field in BRAND_FIELDS:
        for brand in re.split(r"[,;|]", product.get(field, "")):
            stripped_brand = brand.strip()
            if stripped_brand:
                values.append(stripped_brand)
    return values


def has_known_brand(product: dict[str, str]) -> bool:
    return any(
        pattern.search(brand)
        for brand in brand_values(product)
        for pattern in BRAND_PATTERNS
    )


def was_updated_after_2023(last_modified_datetime: str) -> bool:
    year_match = re.match(r"\s*(\d{4})", last_modified_datetime)
    return year_match is not None and int(year_match.group(1)) > MINIMUM_YEAR


def open_source(path: Path) -> TextIO:
    if path.suffix.casefold() == ".gz":
        return gzip.open(path, "rt", encoding="utf-8", newline="")
    return path.open("r", encoding="utf-8", newline="")


def main() -> None:
    csv.field_size_limit(sys.maxsize)

    with open_source(INPUT_CSV_PATH) as source:
        with OUTPUT_CSV_PATH.open(
            "w",
            encoding="utf-8",
            newline="",
        ) as destination:
            reader = csv.DictReader(source, delimiter="\t")
            required_columns = {
                *BRAND_FIELDS,
                "last_modified_datetime",
                "product_name",
            }
            missing_columns = required_columns.difference(
                reader.fieldnames or []
            )
            if missing_columns:
                missing = ", ".join(sorted(missing_columns))
                raise ValueError(
                    f"Input file is missing required columns: {missing}"
                )

            writer = csv.DictWriter(
                destination,
                fieldnames=reader.fieldnames,
                delimiter=",",
                lineterminator="\n",
            )
            writer.writeheader()

            products_written = 0
            for product in reader:
                if not product.get("product_name", "").strip():
                    continue
                if not has_known_brand(product):
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
