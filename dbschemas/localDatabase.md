# Local Database Schema

## Relationships

```text
Foods (foods database)    1 ──── * NutritionLogs
User                    1 ──── * UserMeasurements
MeasurementUnits        1 ──── * UserMeasurements (weight)
MeasurementUnits        1 ──── * UserMeasurements (height)
ActivityLevels          1 ──── * UserMeasurements
PlanTypes               1 ──── * NutritionPlans
UserMeasurements        1 ──── * NutritionPlans
NutritionPlans          1 ──── * NutritionPlanSpans
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
| `activityLevelId` | `TEXT` | Nullable, foreign key to `ActivityLevels.id` |

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

## ActivityLevels

| Column | SQLite type | Rules |
|---|---|---|
| `id` | `TEXT` | Primary key, UUID |
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

## PlanTypes

| Column | SQLite type | Rules |
|---|---|---|
| `id` | `TEXT` | Primary key, UUID |
| `name` | `TEXT` | Not null, unique |

The lookup table contains `Maintenance`, `Progressive gain`, `Progressive loss`, and `Custom`.

## NutritionPlans

| Column | SQLite type | Rules |
|---|---|---|
| `id` | `TEXT` | Primary key, UUID |
| `planTypeId` | `TEXT` | Not null, foreign key to `PlanTypes.id` |
| `userMeasurementId` | `TEXT` | Not null, foreign key to `UserMeasurements.id` |
| `targetWeightSI` | `REAL` | Not null |

## NutritionPlanSpans

| Column | SQLite type | Rules |
|---|---|---|
| `id` | `TEXT` | Primary key, UUID |
| `nutritionPlanId` | `TEXT` | Not null, foreign key to `NutritionPlans.id` |
| `startDate` | `INTEGER` | Not null, Unix timestamp |
| `endDate` | `INTEGER` | Not null, Unix timestamp |
| `targetCaloriesSI` | `REAL` | Not null |

### Indexes

```sql
CREATE INDEX nutrition_plan_spans_plan_id_idx
    ON NutritionPlanSpans (nutritionPlanId);
```

## Database rules

- The database is stored locally on the device at `Application Support/FitnessTracker/local.sqlite`.
- `foodId` stores the canonical lowercase UUID from the foods database.
- `date` and `time` are stored as text.
- `UserMeasurements` uses grams by default for weight and centimetres by default for height.
