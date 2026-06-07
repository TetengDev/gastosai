# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

GastosAI is an AI-powered expense tracker with natural-language query support. Backend is a Spring Boot REST API; frontend is a React + TypeScript SPA (currently scaffolded, not yet implemented). The AI layer generates PostgreSQL SELECT statements from user questions via OpenAI or Claude, then executes them after safety validation.

## Commands

### Local database (required before running backend)
```bash
docker compose up -d      # start Postgres 17 on :5432
docker compose down       # stop
```

### Backend (run from `backend/`)
```bash
./mvnw spring-boot:run          # start API on :8080
./mvnw test                     # all tests (H2 in-memory)
./mvnw test -Dtest=ExpenseApiIT # single test class
./mvnw clean install -DskipTests
```
On Windows use `mvnw.cmd` instead of `./mvnw`.

### Frontend (run from `frontend/`)
```bash
npm run dev      # dev server on :5173
npm run build
npm run lint
```

## Environment Setup

Copy `backend/.env.example` to `backend/.env` and fill in values. The app auto-loads `.env` from the working directory or a `gastosai/` subdirectory at startup.

Required: `DB_URL`, `DB_USERNAME`, `DB_PASSWORD`, and either `OPENAI_API_KEY` or `CLAUDE_API_KEY`.

`GASTOS_AI_PROVIDER=openai|claude` selects the LLM backend (default: `openai`).  
`GASTOS_SEED_SAMPLE_DATA=true` seeds 15 sample expenses on first startup.

Frontend needs `VITE_API_URL=http://localhost:8080` in `frontend/.env.local`.

Swagger UI: `http://localhost:8080/swagger-ui.html`

## Architecture

```
frontend/ (React 19 + Vite + TypeScript + Tailwind + Recharts)
    ↓ HTTP (Axios)
backend/ (Spring Boot 4.0.5 / Java 25)
    ├── Controller → Service → Repository  (CRUD + reporting)
    └── AiController → AiQueryService → SqlGenerator
                         → SqlGuard (validation)
                         → JdbcTemplate (raw execution)
    ↓
PostgreSQL 17 (local via Docker; Supabase in prod)
    ↓ (for NL queries only)
OpenAI API or Anthropic API
```

**Backend packages** (`com.teng.app.gastosai`):
- `entity/` — `Expense` (amount `BigDecimal(19,4)`, date, note, FK to Category), `Category` (unique name)
- `repository/` — JPA repos with JPQL aggregation queries for monthly/category reports
- `service/` — business logic; `CategoryService` auto-creates categories on expense creation and blocks deletion if expenses remain
- `controller/` — `ExpenseController` (CRUD + `/report/monthly`, `/report/category`), `CategoryController`, `AiController` (`POST /ai/query`)
- `ai/` — `SqlGenerator` interface + `OpenAiSqlGenerator` / `ClaudeSqlGenerator` implementations using Spring `RestClient`; `SqlGuard` validates AI SQL before execution
- `config/` — `AIClientConfig` wires the correct `SqlGenerator` bean; `WebConfig` sets CORS (currently `*`, restrict to Vercel domain for prod)
- `bootstrap/` — seeds sample data on startup when enabled
- `exception/` — `GlobalExceptionHandler` maps domain exceptions to structured JSON error responses

**SqlGuard** is the AI safety boundary: blocks all mutating and DDL statements, requires `SELECT … FROM expenses`, rejects multi-statement input, and blocks system catalog access. Never relax these rules.

**Database DDL**: `hibernate.ddl-auto=create-drop` in dev (schema recreated on every start). Tests use H2 in-memory. Flyway is on the classpath but has no migrations yet.

**Currency**: Philippine peso (₱). All monetary values are `BigDecimal`.

## Deployment (production targets)

- Backend → Koyeb (512 MB free tier); tune JVM: `-Xmx320m -XX:+UseSerialGC`
- Frontend → Vercel (static); set `VITE_API_URL` to the Koyeb HTTPS URL
- Database → Supabase (free PostgreSQL; note: pauses after ~1 week idle)

See `gastosai-fullstack-guide.md` for the full deployment walkthrough including multi-stage Dockerfile and GitHub Actions CI.