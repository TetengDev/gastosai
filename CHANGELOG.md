# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/)
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]

---

## [0.5.2] - 2026-06-10

### Added
- Full Docker stack via `docker compose --profile app up -d --build` — backend and frontend now containerised alongside the existing DB service
- `scripts/start.ps1` option 6: start the full stack through Docker Compose
- Named volume `postgres_data` so DB data survives `docker compose down` (only wiped with `down -v`)
- DB health check in `docker-compose.yaml`; backend waits for Postgres to be healthy before starting
- Memory limits on all Docker services: DB 256 MB, backend 512 MB, frontend 64 MB
- BuildKit cache mounts in Dockerfiles for faster Maven and npm rebuilds
- `frontend/Dockerfile` multi-stage build: Node 22 Alpine → nginx Alpine (~20 MB runtime image)
- `frontend/nginx.conf` with SPA fallback routing and gzip compression
- Demo user credentials (name, email, password) now configurable via `GASTOS_DEMO_NAME`, `GASTOS_DEMO_EMAIL`, `GASTOS_DEMO_PASSWORD` env vars

### Fixed
- Category seed data: "Transporation" corrected to "Transportation"
- `scripts/start.ps1`: em-dash inside string literal replaced with `--` to fix PowerShell 5.1 Windows-1252 parse error

### Changed
- Backend Docker runtime switched from `eclipse-temurin:25-jdk` to `eclipse-temurin:25-jdk-alpine` (~40% smaller image); runs as non-root `spring` user
- `scripts/teardown.ps1` option 3 now explicitly documents that `docker compose down` stops all Docker services including app-profile containers
- Pre-PR checklist: added mandatory runtime execution-testing rule (≥90% of touched paths), infrastructure breaking-change rule, and PS encoding rule

---

## [0.5.1] - 2026-06-09

### Fixed
- Settings page: removed `useEffect` that called `setState` synchronously, resolving the `react-hooks/set-state-in-effect` lint error in CI

### Docs
- Split `ai/skills` into `shared/` (reusable, project-agnostic) and project-specific files
- Added `ai/skills/shared/pre-pr-checklist.md` — mandatory lint/build/test gate before every PR

---

## [0.5.0] - 2026-06-09

### Added
- User profile with name and optional nickname, configurable from the new Settings page
- Nickname (when set) is shown in the navbar and used by the chatbot to personalize greetings; falls back to name when unset
- `GET /user/profile` and `PUT /user/profile` endpoints for fetching and updating profile data

---

## [0.4.2] - 2026-06-09

### Fixed
- Chat widget parse error: mixed `||` and `??` operators in unsupported file type message now correctly wrapped in parentheses

---

## [0.4.0] - 2026-06-09

### Added
- Chat widget now accepts CSV, image, and other file types via the attach button
- CSV files are routed to the expense import endpoint; import summary (imported/skipped counts and any errors) is shown in the conversation
- Images continue to be routed to the AI vision endpoint for receipt analysis
- Unsupported file types (e.g. PDF, Excel, JSON) receive an inline error message in the chat instead of a silent failure

---

## [0.3.2] - 2026-06-09

### Fixed
- `AuthContext`: replaced `useEffect` initialization with a lazy `useState` initializer, eliminating a synchronous setState-in-effect lint error
- `useExpenses` / `Categories`: suppressed false-positive `set-state-in-effect` rule on async data-fetching hooks
- CI: opted GitHub Actions runners into Node.js 24 ahead of forced migration on 2026-06-16

---

## [0.3.1] - 2026-06-09

### Fixed
- CI `Permission denied` error on `./mvnw` — set executable bit in git index

### Changed
- Test requirements are now mandatory (Blocker) for all feature and bug-fix commits

---

## [0.3.0] - 2026-06-09

### Added
- Admin role (`ROLE_ADMIN`) with configurable credentials via `GASTOS_ADMIN_EMAIL` / `GASTOS_ADMIN_PASSWORD` env vars
- Admin users bypass per-user expense scoping — sees all users' data in expenses, reports, and AI queries
- `commit-msg` git hook enforcing SemVer version bumps on `feat`/`fix`/`perf` commits that touch app code

### Changed
- `CLAUDE.md` documents one-time hook setup and version bump rules

---

## [0.2.0] - 2026-06-09

### Added
- Multi-user JWT authentication (register, login, logout)
- `AuthContext` and `ProtectedRoute` on the frontend
- Login (`/login`) and register (`/register`) pages
- Per-user expense data isolation — each user sees only their own expenses
- Demo account seeded when `GASTOS_SEED_SAMPLE_DATA=true`
- Axios 401 interceptor clears token and redirects to login

### Changed (Breaking)
- All API endpoints now require a valid JWT `Authorization: Bearer` header
- Expenses, reports, and AI queries are scoped to the authenticated user

---

## [0.1.0] - Initial release

### Added
- Expense tracking with categories
- AI-powered natural language expense queries (OpenAI and Claude providers)
- CSV import
- Monthly and category reports
- Chat widget with Plain / Pro / Gen-Z modes
- Dark mode with system preference detection and manual toggle
- Gradient UI redesign
