# gastosai

AI-powered personal expense tracker. Natural-language queries translate to safe SQL via a pluggable LLM provider.

---

## Quick start

```bash
# 1. Start the database (port 5433)
docker compose up -d

# 2. Configure backend secrets (first time only)
copy backend\.env.example backend\.env   # fill in DB_URL, API keys

# 3. Launch everything interactively
.\scripts\start.ps1
```

Swagger UI: http://localhost:8080/swagger-ui.html  
Frontend:   http://localhost:5173

---

## Architecture

```
frontend/   React 19 + TypeScript + Vite + Tailwind + Recharts
    ↓ HTTP / Axios
backend/    Spring Boot 4 / Java 25
    ├── Controller → Service → Repository   (CRUD + reports)
    └── AiController → AiQueryService → SqlGenerator
                         → SqlGuard  ← SAFETY BOUNDARY
                         → JdbcTemplate
    ↓ JPA
PostgreSQL 17  (Docker local · Supabase prod)
    ↓ AI path only
OpenAI API  or  Anthropic Claude API
```

### Key packages (`com.teng.app.gastosai`)

| Package | Contents |
|---|---|
| `entity/` | `Expense` (BigDecimal amount, LocalDateTime date, description, FK Category), `Category` |
| `dto/` | `ExpenseRequest/Response`, `CategoryRequest/Response`, `AiQueryRequest/Response`, report items |
| `repository/` | JPA repos; JPQL aggregation for monthly + category reports |
| `service/` | Business logic; `CategoryService` auto-creates categories, reassigns to Uncategorized on delete |
| `controller/` | `ExpenseController`, `CategoryController`, `AiController` |
| `ai/` | `SqlGenerator` interface, `OpenAiSqlGenerator`, `ClaudeSqlGenerator`, `SqlGuard` |
| `config/` | `AIClientConfig`, CORS `WebConfig`, properties classes |
| `bootstrap/` | `CategoryDataLoader` (always runs, seeds 13 predefined categories), `AppDataLoader` (sample expenses) |
| `exception/` | `GlobalExceptionHandler` → structured JSON errors |

---

## Non-negotiable rules

1. **SqlGuard is the security boundary.** Never bypass, weaken, or route AI SQL around it.
2. **Generated SQL must be a single SELECT referencing the `expenses` table.** No mutations, no DDL, no system catalogs.
3. **Never expose JPA entities through controllers.** Always use DTOs.
4. **Use the Maven wrapper**, not local Maven: `mvnw.cmd` (Windows) / `./mvnw` (Unix).
5. **Currency is Philippine peso (₱).** All monetary values are `BigDecimal`.

---

## Git Workflow

Before making repository changes, follow:

* `ai/skills/git-best-practices.md`

For AI SQL-related changes, also follow:

* `ai/skills/ai-sql-safety.md`

---

## Agent skills and resources

| Type | Path | Purpose |
|---|---|---|
| Skill | `ai/skills/project-context.md` | Full domain model, data flow, env variables |
| Skill | `ai/skills/backend-review.md` | Backend code review checklist |
| Skill | `ai/skills/feature-builder.md` | How to add a feature end-to-end |
| Skill | `ai/skills/testing.md` | Test strategy and commands |
| Skill | `ai/skills/ai-sql-safety.md` | SqlGuard rules in detail |
| Skill | `ai/skills/java-spring-standards.md` | Java 25 + Spring Boot 4 conventions |
| Skill | `ai/skills/deployment.md` | Koyeb / Vercel / Supabase deployment |
| Skill | `ai/skills/feature-workflow.md` | Branch → develop → test → merge workflow |
| Skill | `ai/skills/git-best-practices.md` | Git safety rules for all repository changes |
| Prompt | `ai/prompts/add-feature.md` | Structured prompt for new features |
| Prompt | `ai/prompts/review-code.md` | Code review prompt |
| Prompt | `ai/prompts/debug.md` | Debug investigation prompt |
| Prompt | `ai/prompts/refactor.md` | Refactor prompt |
| Template | `ai/templates/pr-template.md` | Pull request description |
| Template | `ai/templates/api-design-template.md` | API endpoint design |
| Template | `ai/templates/architecture-decision-template.md` | ADR format |
