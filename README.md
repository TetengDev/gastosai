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

---

## Quick start (local)

Requires: Java 25, Node.js LTS, Docker Desktop.

```powershell
# 1. Configure the backend (first time only)
copy backend\.env.example backend\.env   # then fill in your API key

# 2. Start everything with the launcher script
.\scripts\start.ps1
```

Or manually in three terminals — see [backend/README.md](backend/README.md) and [frontend/README.md](frontend/README.md).

- Frontend: http://localhost:5173
- Backend API: http://localhost:8080
- Swagger UI: http://localhost:8080/swagger-ui.html

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

Stop the backend and frontend (see below), then start them again in the same order as Quick start. Because the backend uses `hibernate.ddl-auto=create-drop`, **the database schema is dropped and recreated on every backend restart** — all data is wiped and the 15 sample expenses are reseeded automatically (controlled by `GASTOS_SEED_SAMPLE_DATA=true` in `backend/.env`).

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
# Then restart the backend — it will recreate the schema and reseed sample data
```

### Skip sample data on restart

Set `GASTOS_SEED_SAMPLE_DATA=false` in `backend/.env` before starting the backend if you want to keep a clean database without the 15 sample expenses.

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
│   └── workflows/ci.yml    GitHub Actions — runs backend tests on push
└── README.md               ← you are here
```

---

## Deployment targets

| Layer    | Service  | Notes                                                  |
|----------|----------|--------------------------------------------------------|
| Backend  | Koyeb    | Free 512 MB tier; use `SPRING_PROFILES_ACTIVE=prod`    |
| Frontend | Vercel   | Auto-deploys on push; set `VITE_API_URL` to Koyeb URL  |
| Database | Supabase | Free PostgreSQL; pauses after ~1 week idle             |

See `gastosai-fullstack-guide.md` for the full deployment walkthrough.
