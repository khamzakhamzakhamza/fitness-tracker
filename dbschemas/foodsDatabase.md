# Foods Database Schema

## Relationships

```text
Sources             1 ──── * Foods
Countries           1 ──── * Foods
Foods               1 ──── * FoodNutrients
Nutrients           1 ──── * FoodNutrients
MeasurementUnits    1 ──── * Nutrients
MeasurementUnits    1 ──── * FoodNutrients
```

## Foods

| Column | SQLite type | Rules |
|---|---|---|
| `id` | `INTEGER` | Primary key |
| `source_id` | `INTEGER` | Not null, foreign key to `Sources.id` |
| `country_id` | `INTEGER` | Not null, foreign key to `Countries.id` |
| `origin_id` | `TEXT` | Not null |
| `version` | `INTEGER` | Not null |
| `name` | `TEXT` | Not null |
| `brand` | `TEXT` | Nullable |
| `barcode` | `TEXT` | Nullable |
| `small_image_url` | `TEXT` | Nullable |
| `image_url` | `TEXT` | Nullable |
| `quantity` | `REAL` | Nullable |
| `measurement_unit_id` | `INTEGER` | Not null |
| `total_energy_cal` | `REAL` | Nullable |
| `total_amount_grams` | `REAL` | Nullable |
| `serving_size_grams` | `REAL` | Nullable |
| `date_added` | `INTEGER` | Not null |
| `date_updated` | `INTEGER` | Nullable |

### Constraints and indexes

```sql
UNIQUE (source_id, country_id, origin_id, version)
CREATE INDEX foods_barcode_idx ON Foods (barcode);
CREATE INDEX foods_country_id_idx ON Foods (country_id);
```

## Nutrients

| Column | SQLite type | Rules |
|---|---|---|
| `id` | `INTEGER` | Primary key |
| `name` | `TEXT` | Not null, unique |
| `short_name` | `TEXT` | Not null, unique |
| `measurement_unit_id` | `INTEGER` | Not null, foreign key to `MeasurementUnits.id` |
| `date_added` | `INTEGER` | Not null |

## FoodNutrients

| Column | SQLite type | Rules |
|---|---|---|
| `food_id` | `INTEGER` | Not null, foreign key to `Foods.id` |
| `nutrient_id` | `INTEGER` | Not null, foreign key to `Nutrients.id` |
| `amount` | `REAL` | Not null, must be non-negative |
| `basis_amount` | `REAL` | Not null, must be greater than zero |
| `basis_unit_id` | `INTEGER` | Not null, foreign key to `MeasurementUnits.id` |
| `date_added` | `INTEGER` | Not null |

### Constraints and indexes

```sql
PRIMARY KEY (food_id, nutrient_id)
CHECK (amount >= 0)
CHECK (basis_amount > 0)
```

## MeasurementUnits

| Column | SQLite type | Rules |
|---|---|---|
| `id` | `INTEGER` | Primary key |
| `name` | `TEXT` | Not null, unique |
| `short_name` | `TEXT` | Not null, unique |
| `plural_form` | `TEXT` | Nullable |
| `gram_convertion_value` | `REAL` | Nullable |
| `date_added` | `INTEGER` | Not null |

## Sources

| Column | SQLite type | Rules |
|---|---|---|
| `id` | `INTEGER` | Primary key |
| `name` | `TEXT` | Not null, unique |
| `url` | `TEXT` | Nullable |
| `date_added` | `INTEGER` | Not null |

## Countries

| Column | SQLite type | Rules |
|---|---|---|
| `id` | `INTEGER` | Primary key |
| `name` | `TEXT` | Not null, unique |
| `iso_alpha2_code` | `TEXT` | Not null, unique, exactly two characters |
| `date_added` | `INTEGER` | Not null |

## DatabaseMetadata

| Column | SQLite type | Rules |
|---|---|---|
| `id` | `INTEGER` | Primary key, must equal `1` |
| `schema_version` | `INTEGER` | Not null |
| `dataset_version` | `TEXT` | Nullable |
| `generated_at` | `INTEGER` | Not null |
| `source_licence` | `TEXT` | Not null |
| `source_attribution` | `TEXT` | Not null |

## Food full-text search

SQLite FTS5 indexes food names and brands for responsive type-in search.

```sql
CREATE VIRTUAL TABLE FoodSearch USING fts5(
    name,
    brand,
    content = Foods,
    content_rowid = id
);
```

## Database rules

- Enable SQLite foreign-key enforcement when building and opening the database.
- Store timestamps consistently as Unix timestamps. SQLite has no dedicated datetime storage class.
- Use `ON DELETE CASCADE` from `Foods` to `FoodNutrients`.
- Use restrictive deletion for referenced `Sources`, `Countries`, `Nutrients`, and `MeasurementUnits`.
- Treat each published database version as immutable. Generate and upload a replacement rather than editing a downloaded release in place.
