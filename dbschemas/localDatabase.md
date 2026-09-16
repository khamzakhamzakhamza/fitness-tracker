# Local Database Schema

## Relationships

```text
Foods (foods database)    1 ──── * NutritionLogs
User                    1 ──── * UserMeasurements
ActivityLevels          1 ──── * UserMeasurements
Plans                   1 ──── * ActivePlanMilestones
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
| `weightSI` | `REAL` | Not null, stored in grams |
| `heightSI` | `REAL` | Nullable, stored in centimetres |
| `leanMass` | `REAL` | Not null, percentage |
| `activityLevelId` | `INTEGER` | Not null, foreign key to `ActivityLevels.id` |

### Indexes

```sql
CREATE INDEX user_measurements_user_id_idx ON UserMeasurements (userId);
```

## ActivityLevels

| Column | SQLite type | Rules |
|---|---|---|
| `id` | `INTEGER` | Primary key |
| `name` | `TEXT` | Not null, unique |
| `calorieMultiplier` | `REAL` | Not null |
| `description` | `TEXT` | Not null |
| `dateAdded` | `INTEGER` | Not null, Unix timestamp |

The lookup table contains these five activity levels:

| Name | Calorie multiplier | Description |
|---|---|---|
| `Sedentary` | `1.2` | Desk job, no training |
| `Light` | `1.375` | 1–3 sessions a week |
| `Moderate` | `1.55` | 3–5 sessions a week |
| `Heavy` | `1.725` | 6–7 sessions a week |
| `Athlete` | `1.9` | Training twice a day |

## HeightMeasurementUnits

| Column | SQLite type | Rules |
|---|---|---|
| `id` | `INTEGER` | Primary key |
| `name` | `TEXT` | Not null, unique |
| `shortName` | `TEXT` | Not null, unique |
| `siConversionValue` | `REAL` | Not null, multiplier for conversion to centimetres |
| `isDefault` | `INTEGER` | Not null, boolean (`0` or `1`) |
| `dateAdded` | `INTEGER` | Not null, Unix timestamp |

The planning units are:

| Name | Short name | SI conversion value | Default |
|---|---|---:|---|
| `Centimetres` | `cm` | `1` | Yes |
| `Feet` | `ft` | `30.48` | No |

## WeightMeasurementUnits

| Column | SQLite type | Rules |
|---|---|---|
| `id` | `INTEGER` | Primary key |
| `name` | `TEXT` | Not null, unique |
| `shortName` | `TEXT` | Not null, unique |
| `siConversionValue` | `REAL` | Not null, multiplier for conversion to grams |
| `isDefault` | `INTEGER` | Not null, boolean (`0` or `1`) |
| `dateAdded` | `INTEGER` | Not null, Unix timestamp |

The planning units are:

| Name | Short name | SI conversion value | Default |
|---|---|---:|---|
| `Kilograms` | `kg` | `1000` | Yes |
| `Pounds` | `lb` | `453.59237` | No |

## Plans

| Column | SQLite type | Rules |
|---|---|---|
| `id` | `TEXT` | Primary key, UUID |
| `name` | `TEXT` | Not null |
| `targetWeightSI` | `REAL` | Not null |

## ActivePlanMilestones

| Column | SQLite type | Rules |
|---|---|---|
| `id` | `TEXT` | Primary key, UUID |
| `planId` | `TEXT` | Not null, foreign key to `Plans.id` |
| `date` | `INTEGER` | Not null, Unix timestamp |
| `targetWeightSI` | `REAL` | Not null |
| `isActive` | `INTEGER` | Not null, boolean (`0` or `1`) |

### Indexes

```sql
CREATE INDEX active_plan_milestones_date_idx
    ON ActivePlanMilestones (date);
```

## Database rules

- The database is stored locally on the device at `Application Support/FitnessTracker/local.sqlite`.
- `foodId` stores the canonical lowercase UUID from the foods database.
- `date` and `time` are stored as text.
- `UserMeasurements.weightSI` is stored in grams and `UserMeasurements.heightSI` in centimetres.
- Exactly one row in each measurement-unit table is selected as the default by the measurement service.
- Measurement-unit queries return the default unit first.
