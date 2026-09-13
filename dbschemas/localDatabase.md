# Local Database Schema

## Relationships

```text
Foods (foods database)    1 ──── * NutritionLogs
User                    1 ──── * UserMeasurements
MeasurementUnits        1 ──── * UserMeasurements (weight)
MeasurementUnits        1 ──── * UserMeasurements (height)
```

`NutritionLogs.foodId` is an application-level reference to `Foods.id` in the
separate foods database; it is not a SQLite foreign key.

## NutritionLogs

| Column | SQLite type | Rules |
|---|---|---|
| `id` | `INTEGER` | Primary key, autoincrement |
| `foodId` | `TEXT` | Not null, UUID reference to `Foods.id` |
| `date` | `TEXT` | Not null |
| `time` | `TEXT` | Not null |

### Indexes

```sql
CREATE INDEX nutrition_logs_date_idx ON NutritionLogs (date);
```

## User

| Column | SQLite type | Rules |
|---|---|---|
| `id` | `TEXT` | Primary key, UUID |
| `name` | `TEXT` | Nullable |
| `birthday` | `INTEGER` | Not null, Unix timestamp |
| `dateAdded` | `INTEGER` | Not null, Unix timestamp |

## UserMeasurements

| Column | SQLite type | Rules |
|---|---|---|
| `id` | `TEXT` | Primary key, UUID |
| `userId` | `TEXT` | Not null, foreign key to `User.id` |
| `weight` | `REAL` | Nullable |
| `weightMeasurementUnitId` | `TEXT` | Not null, foreign key to `MeasurementUnits.id`, defaults to grams |
| `height` | `REAL` | Nullable |
| `heightMeasurementUnitId` | `TEXT` | Not null, foreign key to `MeasurementUnits.id`, defaults to centimetres |
| `leanMass` | `REAL` | Nullable, percentage |

### Indexes

```sql
CREATE INDEX user_measurements_user_id_idx ON UserMeasurements (userId);
```

## MeasurementUnits

| Column | SQLite type | Rules |
|---|---|---|
| `id` | `TEXT` | Primary key, UUID |
| `name` | `TEXT` | Not null, unique |
| `shortName` | `TEXT` | Not null, unique |
| `pluralForm` | `TEXT` | Nullable |
| `siConversionValue` | `REAL` | Nullable |
| `dateAdded` | `INTEGER` | Not null, Unix timestamp |

## Database rules

- The database is stored locally on the device at `Application Support/FitnessTracker/local.sqlite`.
- `foodId` stores the canonical lowercase UUID from the foods database.
- `date` and `time` are stored as text.
- `UserMeasurements` uses grams by default for weight and centimetres by default for height.
