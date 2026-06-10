# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/)
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]

---

## [0.9.0] - 2026-06-10

### Added
- `ParsedExpenseResult` now includes `saveable` (boolean) and `hint` (string|null) fields; HIGH-confidence parses with a positive amount are marked saveable, LOW-confidence parses return a hint asking for more detail
- ChatWidget: expense-logging intent detection — messages containing spending keywords (English + Filipino) are routed to `POST /expenses/parse` instead of the AI query endpoint
- ChatWidget: draft expense card in chat — shows amount, category, date, and description with a "Save expense" button; on save, creates the expense directly without opening the modal; shows "Saved to expenses" on success
- Suggestion chip: "spent 250 on Jollibee lunch" as an example to guide users toward the log-expense flow

---

## [0.8.0] - 2026-06-10

### Added
- `POST /expenses/parse` — natural-language text parse endpoint; accepts free-form text (e.g. "spent 250 on lunch") and returns a draft expense with amount, category, date, description, and confidence level without saving
- `ExpenseParser` interface with OpenAI and Claude implementations; active provider follows the existing `GASTOS_AI_PROVIDER` env var
- Philippine time (UTC+8) is used as the default date when no date is mentioned in the parsed text

---

## [0.7.0] - 2026-06-10

### Added
- Avatar color picker in Settings — users can choose from 6 gradient presets; selection is persisted and reflected immediately in the Navbar avatar and Settings header
- Category icon picker — add/edit category modal now shows a 24-icon grid; selected icon is stored on the backend and displayed on the category card; falls back to name-based icon mapping if none set
- Email editing in Settings — email field is now editable; backend validates uniqueness and issues a fresh JWT so the session stays valid after an email change

### Fixed
- Dark mode text visibility in ChatWidget — suggestion chips and accent text in all 3 modes (Plain, Pro, Gen Z) now have proper dark-mode colour variants
- Category colour badges (Expenses table, Dashboard recent list) and category cards (Categories page) now use dark-tinted backgrounds and light text in dark mode instead of light-on-dark

---

## [0.6.0] - 2026-06-10

### Added
- `lucide-react` icon library; all inline SVG icons replaced with lucide equivalents (`Pencil`, `Trash2`, `Upload`, `Loader2`, `Sun`, `Moon`, `LogOut`)
- Category cards now display a semantic icon per category name (e.g. Car for Transportation, Utensils for Meal Plan, GraduationCap for Training/Upskilling); user-created categories fall back to the Tag icon
- Navbar profile link replaced with an avatar button showing user initials in a circle — clearly clickable with hover state and active highlight; name label visible on sm+ screens
- Settings page now shows a gradient avatar with user initials and email summary at the top of the profile section
- `getInitials` utility exported from `lib/formatters.ts`

---

## [0.5.3] - 2026-06-10

### Fixed
- Expenses and Categories pages: "Delete All" button relocated from the primary action cluster to beneath the page title as a low-prominence text link, separating destructive actions from primary actions per UX best practices
- Dark mode: app now resets to system preference (`prefers-color-scheme`) on logout instead of persisting the last user's theme choice

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
