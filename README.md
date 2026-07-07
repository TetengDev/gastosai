# GastosAI

AI-powered personal expense tracker with natural-language query support.

Ask questions like *"How much did I spend on food last month?"* and get answers directly from your expense data — no SQL needed.

---

## Architecture

```
frontend/   React 19 + TypeScript + Vite + Tailwind + Recharts
    ↓ HTTP (Axios)
backend/    Spring Boot 4 / Java 25 REST API
    ↓ JPA
PostgreSQL 17 (Docker locally · Supabase in production)
    ↓ AI queries only
OpenAI API or Anthropic Claude API
```

## Sub-project READMEs

| | |
|---|---|
| [backend/README.md](backend/README.md) | Running, testing, environment variables, API reference |
| [frontend/README.md](frontend/README.md) | Running, building, pages, environment variables |
| [docs/capabilities.md](docs/capabilities.md) | Product scope, subscription tiers, AI quotas, limitations, roadmap |
| [docs/go-live-strategy.md](docs/go-live-strategy.md) | What must ship before charging money — payment blockers, provider pick, sequenced go-live path |

---

## Quick start (local)

Requires: **Java 25**, **Node.js LTS**, **Docker Desktop**. All commands are PowerShell, run from the repo root.

```powershell
# 1. Configure the backend (first time only)
copy backend\.env.example backend\.env   # then fill in DB + (optional) API key values

# 2. One-shot launcher (DB + backend + frontend)
.\scripts\start.ps1 -Mode all
```

### Manual run (3 terminals)

Prefer running each service yourself? Open three terminals:

```powershell
# Terminal 1 — database (PostgreSQL 17 on port 5433, data in a named volume)
docker compose up -d

# Terminal 2 — backend (Spring Boot on :8080)
cd backend
.\mvnw.cmd spring-boot:run        # Unix: ./mvnw spring-boot:run

# Terminal 3 — frontend (Vite dev server on :5173)
cd frontend
npm install                       # first time only
npm run dev
```

- Frontend: http://localhost:5173
- Backend API: http://localhost:8080
- Swagger UI: http://localhost:8080/swagger-ui.html

> First backend boot runs Flyway migrations and creates the schema. Data **persists** across restarts (it is not wiped). See [backend/README.md](backend/README.md) and [frontend/README.md](frontend/README.md) for details.

### Demo & admin accounts

- **Demo**: `demo@gastosai.dev` / `demo123` — seeded with sample data when `GASTOS_SEED_SAMPLE_DATA=true` (default in `backend/.env.example`).
- **Admin**: set `GASTOS_ADMIN_EMAIL` / `GASTOS_ADMIN_PASSWORD` in `backend/.env`; admin accounts have all features and are always seeded with sample data for easy testing.

### AI features — managed AI vs bring-your-own-key

AI (insights, chat, NL query, receipt scan) runs in one of two modes, controlled by the backend only — **no provider key is ever shipped to the browser**:

**BYOK (default).** Each user adds their own OpenAI key in **Settings → AI Provider Key** (stored encrypted, used only for their requests). Without a key those surfaces are disabled; everything else works. No quota is applied — the user's own key pays.

**Managed AI (flip on when you fund a shared key).** Set `AI_ALLOW_SHARED_KEY=true` + a funded `OPENAI_API_KEY` (or `CLAUDE_API_KEY`) in the backend env. Then users need no key — all AI calls bill to the shared key, **capped by a per-plan monthly quota** so cost is bounded. If managed is on but the active provider key is missing, the app **fails fast at startup** (no silent failure).

| | FREE | PREMIUM | TRIAL |
|---|---|---|---|
| AI requests / month | `AI_MONTHLY_FREE_QUOTA` (30) | `AI_MONTHLY_PREMIUM_QUOTA` (300) | `AI_MONTHLY_TRIAL_QUOTA` (50) |
| of which receipt scans | `AI_VISION_FREE_QUOTA` (5) | `AI_VISION_PREMIUM_QUOTA` (50) | `AI_VISION_TRIAL_QUOTA` (10) |

One "AI request" = one chat turn or one receipt upload. **Insights don't count** (cached). **ADMIN bypasses** quota. Over the cap → HTTP **429** with a friendly message. Per-user usage is metered in the `ai_usage` table (token counts + best-effort cost), and exposed at `GET /ai/usage`. Exceeding the cap or a failed provider call never leaks keys, and sensitive data (card/email/phone) is **redacted before any prompt** leaves the backend.

Other AI env vars: `AI_FEATURES_ENABLED` (default true), `AI_REQUEST_TIMEOUT_SECONDS` (30), `AI_MAX_PROMPT_CHARS` (8000), `GASTOS_AI_PROVIDER` (`openai`|`claude`), `OPENAI_MODEL`/`CLAUDE_MODEL`. Pricing rationale: `docs/pricing/pricing-memo-2026-06-19.md`. **Never commit a real key** — all defaults are placeholders.

---

## Scripts

Interactive PowerShell scripts in `scripts/` for day-to-day development.

### `scripts\start.ps1` — launch services

```powershell
.\scripts\start.ps1                    # interactive menu
.\scripts\start.ps1 -Mode all         # start DB + backend + frontend
.\scripts\start.ps1 -Mode db          # database only
.\scripts\start.ps1 -Mode backend     # backend only
.\scripts\start.ps1 -Mode frontend    # frontend only
.\scripts\start.ps1 -Mode reset       # wipe DB volume, reseed, start all
.\scripts\start.ps1 -Mode all -ClearLogs   # clear logs then start
.\scripts\start.ps1 -Mode all -SkipChecks  # skip prerequisite check
```

**Interactive menu options:**

| Choice | Action                                                   |
|--------|----------------------------------------------------------|
| 1      | All services (DB → Backend → Frontend)                   |
| 2      | Database only                                            |
| 3      | Backend only                                             |
| 4      | Frontend only                                            |
| 5      | Reset + start all *(wipes DB volume — all data deleted)* |
| 0      | Exit                                                     |

After selecting, you are asked whether to clear log files before starting.

### `scripts\teardown.ps1` — stop and clean up

```powershell
.\scripts\teardown.ps1                 # interactive multi-select menu
.\scripts\teardown.ps1 -All -Force    # full teardown, no prompts
.\scripts\teardown.ps1 -StopBackend -StopFrontend
.\scripts\teardown.ps1 -DeleteLogs
.\scripts\teardown.ps1 -WipeDb -Force
```

**Interactive menu options** (comma-separated, e.g. `1,3,5`):

| Choice | Action                                                              |
|--------|---------------------------------------------------------------------|
| 1      | Stop backend (port 8080 + java processes)                           |
| 2      | Stop frontend (port 5173)                                           |
| 3      | Stop database — container stopped, data preserved                   |
| 4      | Wipe database volume *(docker compose down -v — all data deleted)*  |
| 5      | Delete log files                                                    |
| 6      | Full teardown (1 + 2 + 4 + 5)                                       |
| 0      | Cancel                                                              |

Destructive operations (option 4 / `-WipeDb`) require typing `YES` to confirm unless `-Force` is passed.

---

## Rerunning / resetting

### Normal restart

Stop the backend and frontend (see below), then start them again in the same order as Quick start. The schema is managed by **Flyway migrations** (`hibernate.ddl-auto=validate`), so **data persists across restarts** — restarting does not wipe anything. Sample data is seeded only when the table is empty (demo) or for admin accounts; existing data is left untouched.

### Stopping the services

**Backend** — find and stop the Java process:
```powershell
# Stop by port (recommended — targets only the backend)
$pid = (netstat -ano | Select-String ":8080.*LISTENING").ToString().Trim().Split()[-1]
Stop-Process -Id $pid -Force

# Or stop all java processes (use only if nothing else is running)
Get-Process java -ErrorAction SilentlyContinue | Stop-Process -Force
```

**Frontend** — find and stop the Node process:
```powershell
$pid = (netstat -ano | Select-String ":5173.*LISTENING").ToString().Trim().Split()[-1]
Stop-Process -Id $pid -Force
```

**Database** — stop the Docker container:
```powershell
docker compose down
```

### Full data reset (wipe all database data)

```powershell
# Stop the database and delete its volume — all data is permanently erased
docker compose down -v

# Start fresh
docker compose up -d
# Then restart the backend — Flyway recreates the schema and (if enabled) reseeds sample data
```

### Skip sample data

Set `GASTOS_SEED_SAMPLE_DATA=false` in `backend/.env` to keep a clean database (no demo seed). Admin accounts are still seeded with sample data regardless, for testing.

---

## Repository layout

```
gastosai/
├── backend/                Spring Boot API
│   ├── logs/               Runtime log output (git-ignored)
│   └── README.md
├── frontend/               React SPA
│   ├── logs/               Runtime log output (git-ignored)
│   └── README.md
├── docker-compose.yaml     Local PostgreSQL 17 on port 5433
├── .github/
│   └── workflows/          GitHub Actions — CI (tests, gate) + auto-release
└── README.md               ← you are here
```

---

## Deployment targets

| Layer    | Service  | Notes                                                     |
|----------|----------|-----------------------------------------------------------|
| Backend  | Oracle Cloud Always Free | Always-on ARM VM; `backend/compose.prod.yml` + Caddy (auto-HTTPS). See `docs/deploy-oracle.md`. (Render `render.yaml` kept as a no-card fallback.) |
| Frontend | Vercel   | Auto-deploys on push; set `VITE_API_URL` to the backend URL |
| Database | Supabase | Free PostgreSQL; pauses after ~1 week idle                |

See `docs/deploy-testing-guide.md` for the step-by-step free-tier deploy walkthrough, and `ai/skills/deployment.md` for deeper notes. Production logging (structured JSON + correlation ids) and how to ship logs to a free aggregator are documented in `docs/observability.md`.

---

## License

**Proprietary — all rights reserved.** Copyright © 2026 Lester Bryan Ilao (TetengDev). The source is public for transparency and review only; it is **not** open source. No permission is granted to use, run, copy, modify, or distribute it without written consent. See [`LICENSE`](LICENSE) for the full terms.
