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
# 1. Start the database
docker compose up -d

# 2. Configure and start the backend (see backend/README.md)
cd backend
copy .env.example .env   # then fill in your API key
.\mvnw.cmd spring-boot:run

# 3. Start the frontend (new terminal)
cd frontend
npm install
npm run dev
```

- Frontend: http://localhost:5173
- Backend API: http://localhost:8080
- Swagger UI: http://localhost:8080/swagger-ui.html

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

| Layer | Service | Notes |
|---|---|---|
| Backend | Koyeb | Free 512 MB tier; use `SPRING_PROFILES_ACTIVE=prod` |
| Frontend | Vercel | Auto-deploys on push; set `VITE_API_URL` to Koyeb URL |
| Database | Supabase | Free PostgreSQL; pauses after ~1 week idle |

See `gastosai-fullstack-guide.md` for the full deployment walkthrough.
