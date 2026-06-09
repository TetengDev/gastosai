# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/)
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]

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
