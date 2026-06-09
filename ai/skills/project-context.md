# Skill: Project Context

Full reference for the gastosai domain model, data flow, and runtime configuration.

---

## Domain model

### Expense
| Field | Type | Notes |
|---|---|---|
| `id` | `Long` | Auto-generated PK |
| `amount` | `BigDecimal(19,4)` | Philippine peso; display at scale 2 |
| `category` | `@ManyToOne Category` | FK; nullable in DB but always set by service |
| `date` | `LocalDateTime` | Defaults to `now()` if omitted on create |
| `description` | `String` (text) | Required; formerly `note` |

### Category
| Field | Type | Notes |
|---|---|---|
| `id` | `Long` | Auto-generated PK |
| `name` | `String(50)` | Unique; trimmed before save |

**Predefined categories** (seeded by `CategoryDataLoader` on every startup):
Cleaning Essentials, Date, Extras, Family Contributions, Hygiene Essentials,
Meal Plan, Monthly Personal, Monthly Utilities, Training/Upskilling,
Transaction Fees, Transporation, Uncategorized, Vacation

---

## DTO contracts

```
ExpenseRequest   amount (required, >0), category (optional → "Uncategorized"), date (optional → now), description (required)
ExpenseResponse  id, amount, category (name string), date, description
CategoryRequest  name (required, max 50)
CategoryResponse id, name
AiQueryRequest   question (string)
AiQueryResponse  columns (list), rows (list of lists), rawSql, summary
MonthlyReportItem  month (YYYY-MM), total
CategoryReportItem category, total
```

---

## Request flow

### CRUD path
```
HTTP request
  → @RestController (input validation via @Valid)
  → @Service (@Transactional, business logic)
  → JpaRepository (JPQL or derived queries)
  → PostgreSQL
  → DTO response
```

### AI query path
```
POST /ai/query  { question: "..." }
  → AiController
  → AiQueryService.query()
      → SqlGenerator.generateSql(question)     # calls OpenAI or Claude API
      → SqlGuard.validate(sql)                  # THROWS if unsafe
      → JdbcTemplate.queryForList(sql)
      → format result as AiQueryResponse
```

---

## Environment variables

| Variable | Default | Description |
|---|---|---|
| `DB_URL` | `jdbc:postgresql://localhost:5433/gastos` | JDBC URL |
| `DB_USERNAME` | `postgres` | |
| `DB_PASSWORD` | `dev` | |
| `GASTOS_AI_PROVIDER` | `openai` | `openai` or `claude` |
| `OPENAI_API_KEY` | — | Required for OpenAI |
| `OPENAI_MODEL` | `gpt-4o-mini` | |
| `CLAUDE_API_KEY` | — | Required for Claude |
| `CLAUDE_MODEL` | `claude-3-5-sonnet-20241022` | |
| `GASTOS_SEED_SAMPLE_DATA` | `true` | Seeds 15 expenses on empty DB |
| `SPRING_PROFILES_ACTIVE` | — | Set `prod` on Koyeb |

---

## Key service behaviors

- **`CategoryService.getOrCreateByName(name)`** — used by `ExpenseService` whenever an expense is saved; never call `categoryRepository.save()` directly from outside `CategoryService`.
- **`CategoryService.delete(id)`** — reassigns all affected expenses to `Uncategorized` before deleting; does not block deletion.
- **`CategoryService.update(id, request)`** — renaming a category automatically reflects in all expense reports because expenses FK to category by ID.
- **`ExpenseService.create/update`** — blank or null category defaults to `"Uncategorized"`.

---

## Database notes

- DDL strategy: `create-drop` in dev — schema wiped on every backend restart.
- Tests: H2 in-memory, schema recreated per test run.
- Flyway is on the classpath but has no migrations yet; it runs on startup.
- Prod: Supabase (free PostgreSQL); set `spring.jpa.hibernate.ddl-auto=validate` and use Flyway migrations before going to production.

---

## Frontend structure

```
frontend/src/
  api/          client.ts (Axios), expenses.ts, categories.ts, ai.ts, types.ts
  components/   Navbar.tsx, ExpenseModal.tsx
  hooks/        useExpenses.ts
  lib/          formatters.ts (formatCurrency, formatDate, toDateTimeLocal)
  pages/        Dashboard.tsx, Expenses.tsx, Categories.tsx, Ask.tsx
```

Routes: `/` (Dashboard), `/expenses`, `/categories`, `/ask`
