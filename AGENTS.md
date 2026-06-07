# gastosai

AI expense tracker. Spring Boot 4 / Java 25 REST API with a natural-language
query feature backed by a pluggable LLM provider.

## Commands (use the Maven wrapper, not local Maven)
- Build (Windows):   mvnw.cmd clean install      | (Unix) ./mvnw clean install
- Run (needs .env):  mvnw.cmd spring-boot:run
- All tests:         mvnw.cmd test
- Single test class: mvnw.cmd test -Dtest=ExpenseApiIT
- Skip tests:        mvnw.cmd clean install -DskipTests

## Environment
- Copy .env.example -> .env: DB_URL, DB_USERNAME, DB_PASSWORD, OPENAI_API_KEY or CLAUDE_API_KEY.
- AI provider toggle: GASTOS_AI_PROVIDER=openai | claude.
- Seed sample data on startup: GASTOS_SEED_SAMPLE_DATA=true.
- API docs while running: http://localhost:8080/swagger-ui.html

## Architecture
- Spring Boot 4 / Java 25 REST API. Flow: Controller -> Service -> Repository.
- Persistence: JPA/Hibernate. Postgres in prod, H2 in tests. DDL created on startup.
- AI flow: AiController -> AiQueryService -> SqlGenerator (OpenAi/Claude) -> SqlGuard
  -> raw JDBC -> formatted response.
    - SqlGenerator is an interface; OpenAiSqlGenerator and ClaudeSqlGenerator implement it.
      AIClientConfig selects the active bean from GASTOS_AI_PROVIDER.

## Domain
- Two entities: Expense (BigDecimal amount, fixed scale/precision) and Category (unique name).
- CategoryService auto-creates categories when creating expenses, and blocks deleting a
  category that still has linked expenses.

## DTOs (API contract stays separate from entities)
ExpenseRequest/Response, CategoryRequest/Response, AiQueryRequest/Response,
MonthlyReportItem, CategoryReportItem. Never expose entities through controllers.

## Reporting
- JPQL aggregation queries live in ExpenseRepository, used by
  /expenses/report/monthly and /expenses/report/category.

## AI flow — SAFETY CRITICAL (read before changing anything in the AI path)
- ai/SqlGuard.java is the security boundary. It enforces: no mutating statements,
  must contain FROM expenses, single statement only, blocks system catalogs.
- Never execute AI-generated SQL that bypasses SqlGuard. Never loosen these rules.
- Both SqlGenerator implementations must instruct the model to return ONLY a bare
  SELECT (no prose) — the code and SqlGuard depend on exactly that.

## Files to consult first
- ai/SqlGuard.java — safety rules for AI SQL (critical)
- ai/SqlGenerator.java + OpenAiSqlGenerator.java + ClaudeSqlGenerator.java — prompts & wiring
- controller/*, service/*, repository/* — main request flow
- .env.example, sample-ai-request.json — runtime examples

## Conventions
- Currency: Philippine peso, BigDecimal amounts.
- Secrets come from .env / env vars — never commit them.

## Tests
- Integration tests exist (e.g., ExpenseApiIT); H2 backs the test profile.
- When iterating on one test: mvnw.cmd test -Dtest=<Class>.

## Workflow
- Build one vertical slice at a time; run tests before committing; small focused commits.
- When unsure about a design choice — especially anything in the AI path — ask first.