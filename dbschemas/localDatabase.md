# Local Database Schema

## Relationships

```text
Foods (foods database)    1 ──── * NutritionLogs
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

## Database rules

- The database is stored locally on the device at `Application Support/FitnessTracker/local.sqlite`.
- `foodId` stores the canonical lowercase UUID from the foods database.
- `date` and `time` are stored as text.
