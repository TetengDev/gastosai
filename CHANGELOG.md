# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/)
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]

---

## [0.28.2] - 2026-06-15

### Changed
- Continued `ChatWidget` decomposition (behavior-preserving): extracted `renderAnswer` + field-format helpers into `chat/chatFormatting.tsx`, the `Message` type into `chat/chatTypes.ts`, and `renderActionResult` alongside the formatters. ChatWidget is now ~930 lines (from 1211); all pure/presentational/type pieces live in `chat/`. The remaining stateful hook/card split is left as a follow-up (better suited to an IDE extract-refactor).

---

## [0.28.1] - 2026-06-15

### Changed
- Began extracting `ChatWidget` into a `chat/` module (behavior-preserving): presentational chrome (`ChatChrome.tsx`) and CRUD action helpers (`chatActions.ts`). No user-facing change; the stateful component split (DraftCard/ActionPreviewCard/DisambiguateList/MessageList/useChatController) is tracked as a follow-up.

---

## [0.28.0] - 2026-06-15

Deferred follow-ups (security + tooling). Backwards compatible.

### Fixed
- AI NL-query fallback is now always user-scoped, including admins Ã¢â‚¬â€ admins previously ran unscoped raw AI SQL (Phase 1 audit HIGH). Cross-user analytics, if ever needed, must be a separate audited endpoint.
- `scripts/bump-version.ps1` no longer crashes on the CHANGELOG step under `Set-StrictMode` (single-element slice unwrapped to a scalar, breaking `.Count`).

### Added
- Circuit breaker (`resilience4j-circuitbreaker` core) on `/ai/query` and `/ai/chat`: when the LLM provider fails past the threshold, requests fast-fail to a friendly degraded message instead of cascading 500s.

### Deferred
- ChatWidget decomposition Ã¢â‚¬â€ tracked for its own focused PR.

---

## [0.27.0] - 2026-06-15

Production-refactor batch (Phases 3ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Å“4): frontend entitlement gating + backend hardening.
Monetization enforcement remains **disabled** by default ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â no UX change.

### Added
- Frontend entitlement gating: `useEntitlements` hook, `<FeatureGate>` + `<UpgradePrompt>`
  components (`api/entitlements.ts`); the Dashboard AI Insights card is gated behind
  `ADVANCED_INSIGHTS` (renders normally while enforcement is off).
- Per-user rate limiting on `/ai/**` (`AiRateLimitInterceptor`, 429 past quota;
  `gastos.ratelimit.ai-per-minute`, default 20).
- `application-prod.properties`: HikariCP pool for the 512 MB tier, sample-seeding off,
  `/actuator/health` exposed, quieter logging.
- V4 migration: indexes on user-scoped read paths (expenses, budgets, recurring, alerts, goals).
- CI: report-only Trivy dependency vulnerability scan.
- Demo account seeded an open-ended PREMIUM subscription so it stays fully featured under enforcement.

### Changed / Fixed
- `SqlGuard` now rejects subqueries/CTEs, guaranteeing the fallback NLÃƒÂ¢Ã¢â‚¬Â Ã¢â‚¬â„¢SQL path is a single flat
  SELECT ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â closes the `appendUserFilter` user-scoping bypass flagged in the AI-path security review.
- `SecurityStartupValidator` warns when sample-data seeding targets a remote database.

### Deferred
- ChatWidget decomposition and a Resilience4j circuit breaker (need focused review / dependency vetting).

---

## [0.26.0] - 2026-06-15

Production-refactor batch (Phases 0ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Å“2). All changes are backwards compatible and additive;
monetization enforcement ships **disabled** (`gastos.monetization.enforce=false`), so no feature
is gated yet and there is no UX change.

### Added
- Safe AI analytics query pipeline (`ai.query`): the LLM emits a structured, validated query intent
  (metric/date-range/category/sort/limit allowlists) that the server turns into a fully parameterized,
  user-scoped query (`AnalyticsQueryPlanner` + `SafeAnalyticsExecutor`, statement timeout). Falls back
  to the existing SqlGuard NLÃƒÂ¢Ã¢â‚¬Â Ã¢â‚¬â„¢SQL path when no valid intent is produced, so no analytics is lost.
- Subscription/feature-entitlement foundation: `subscription_plans`, `plan_features`,
  `user_subscriptions` (V3 migration + entities + repositories), `FeatureKey`/`PlanKey`/
  `SubscriptionStatus`, idempotent `EntitlementSeeder` (FREE/PREMIUM).
- `EntitlementService` (`canAccessFeature`/`requireFeatureAccess`) as the single access authority;
  `@RequiresFeature` + `FeatureAccessInterceptor` enforce it on `/ai/query`, `/ai/chat`,
  `/ai/insights/*`, `/expenses/export`. `FeatureLockedException` ÃƒÂ¢Ã¢â‚¬Â Ã¢â‚¬â„¢ HTTP 402.
- `GET /user/entitlements` (plan, status, granted features) for the frontend.
- `PaymentProvider` seam + `SubscriptionService.activate/cancel` for future, provider-agnostic billing.
- `gastos.monetization.enforce` config flag (default false).

### Changed
- `ChatActionService` uses a typed `ChatTool` enum instead of magic tool-name strings.
- AI-generated SQL is logged at DEBUG (was INFO) to avoid emitting user identifiers/value literals.

---

## [0.25.1] - 2026-06-15

### Fixed
- Expense timestamps are stored as wall-clock values (removed `hibernate.jdbc.time_zone=UTC`). Under a non-UTC JVM the previous setting shifted `LocalDateTime` values to UTC, so month/year/day aggregation (alerts, monthly/category/daily reports) bucketed day-boundary expenses into the adjacent month while the UI showed the correct local date

---

## [0.25.0] - 2026-06-15

### Added
- Chatbot CRUD actions via LLM function-calling (`POST /ai/chat`) ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â create/delete expenses, budgets, goals, and recurring items in plain language
- Editable preview/confirm cards for create actions, with a free-text category combobox
- Draft expense cards now include an editable time field (defaults to current local time) and a cancel action
- Disambiguation flow: multi-select when delete keywords match several rows
- Budget create conflict (409) returns an `update_budget` preview to confirm raising the existing limit
- Sample savings goals seeded for the demo user on an empty database

### Fixed
- AI natural-language query user-scoping: `appendUserFilter` now collapses whitespace before matching clauses, fixing duplicate `WHERE` and misplaced filter on newline-formatted SQL
- AI query failures now return a friendly message instead of a 500
- Aggregation/report queries route to the NL query path; SQL prompt declares the `categories` join so by-category queries resolve names

### Changed
- Seeded budgets derive from the current month (`YearMonth.now`) instead of a hardcoded value

---

## [0.24.0] - 2026-06-14

### Added
- `RECURRING_DUE` alert type ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â generates reminders when a recurring expense is due within 3 days
- `NotificationBell` component in Navbar ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â Bell icon with unread count badge, replaces text "Alerts" link
- Alerts page renamed to "Notifications"; shows budget alerts and recurring due reminders in unified inbox
- Flyway V2 migration: `recurring_expense_id` FK column on `alerts` table

---

## [0.23.2] - 2026-06-14

### Chores
- Add `*.stackdump` to `.gitignore`
- Exclude `**/coverage/**` from Vite hot-reload watcher

---

## [0.23.1] - 2026-06-14

### Added
- Backend integration tests: AI SQL generator, expense parser, `AppDataLoader`
- Frontend Vitest setup + backend unit tests for `AlertService`, `SavingsGoalService`, `CsvImportService`

---

## [0.23.0] - 2026-06-14

### Added
- Dashboard KPI strip (5 cards): total spent, MoM change, daily average, biggest category, remaining budget
- Real-time unread alert badge on Alerts nav link (`useUnreadAlertCount` hook + `gastosai:alert-changed` event)
- Horizontal category bar chart replacing donut chart (Recharts `BarChart layout="vertical"`)
- `SecurityStartupValidator`: startup warning when JWT secret uses dev default
- `ai/skills/security-audit.md`: reusable security audit checklist with fix policy and severity tags
- `.claude/agents/security-auditor.md`: security-auditor agent definition
- `brand/gastosai-brand-breakdown.svg`: brand system reference sheet

### Changed
- Dashboard restructured into responsive grid layout (3-col on desktop, stacked on mobile); AI Insights promoted to row 2
- Brand color shifted from violet to indigo-blue across all pages, buttons, and gradients
- Okabe-Ito colorblind-safe palette applied to category chart colors
- Logo replaced with styled text wordmark "GastosAI" (Navbar, Login, Register); Navbar logo links to Dashboard
- CORS: `allowedOriginPatterns("*")` replaced with env-driven `CORS_ALLOWED_ORIGINS` (default `http://localhost:5173`)
- Actuator security permit narrowed from `/actuator/**` to `/actuator/info`
- `LoginRequest` and `RegisterRequest`: `password` field bounded with `@Size(max=72)` (BCrypt limit)
- `VisionService`: file `Content-Type` validated against image allowlist before AI call

---

## [0.22.0] - 2026-06-13

### Added
- Flyway baseline migration (`V1__initial_schema.sql`) covering all seven tables: `users`, `categories`, `expenses`, `recurring_expenses`, `budgets`, `savings_goals`, `alerts`
- `flyway-core` and `flyway-database-postgresql` dependencies added to `pom.xml`

### Changed
- `spring.jpa.hibernate.ddl-auto` switched from `create-drop` to `validate` ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â schema now managed exclusively by Flyway migrations
- Flyway disabled in test profile; H2 in-memory tests continue to use `create-drop`

---

## [0.21.0] - 2026-06-13

### Added
- Multi-currency support on `Expense`: `currency`, `exchangeRate`, `amountInBaseCurrency` fields; all report queries normalise to PHP via `amountInBaseCurrency`
- `CurrencySelect` component with country flag images (flagcdn.com) for PHP, USD, EUR, SGD, JPY, GBP, AUD
- Live exchange-rate suggestion from `open.er-api.com` with 1-hour module-level cache; rate rounded to 4 dp; disclaimer shown to user
- Category list cache (5-min TTL) in shared `src/lib/cache.ts` to avoid redundant API calls
- Multi-currency support on `RecurringExpense`: `currency`, `exchangeRate` fields; UpcomingBills response includes `currency`
- Multi-currency support on `SavingsGoal`: `currency` field; goal amounts display with correct symbol
- Multi-currency support on `Budget`: `currency`, `exchangeRate`, `amountLimitInBaseCurrency` fields; budget summary comparison normalised to PHP
- Currency badge in Expenses, Recurring, and Budget tables for non-PHP entries (shows original amount + PHP equivalent)
- `GoalProgressCard` and `UpcomingBillsCard` dashboard cards display currency-aware amounts

---

## [0.20.1] - 2026-06-12

### Fixed
- Dashboard cards (BudgetOverview, DailyTrend, TopExpenses, AlertsCard, GoalProgress, UpcomingBills) now re-fetch whenever any related data changes ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â not just on mount
- Renamed internal event `gastosai:expense-created` to `gastosai:expense-changed` for semantic accuracy
- `useExpenses` hook dispatches `gastosai:expense-changed` after every add, update, delete, and delete-all
- Budget, Goals, Recurring, and Categories pages dispatch entity-specific events (`gastosai:budget-changed`, `gastosai:goal-changed`, `gastosai:recurring-changed`, `gastosai:expense-changed`) on every mutation so dashboard cards stay in sync with off-screen changes

---

## [0.20.0] - 2026-06-12

### Added
- `GET /expenses/report/daily?month=YYYY-MM` ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â returns daily spending totals for all days in a month (missing days = 0); enables day-by-day trend analysis
- `GET /expenses/report/top?month=YYYY-MM&limit=5` ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â returns top N expenses by amount descending for a given month
- Daily Trend card on Dashboard ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â bar chart showing per-day spending with recharts BarChart
- Top Expenses card on Dashboard ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â ranked list of highest single expenses for the current month
- Seed data updated: `expenseType`/`reimbursable` seeded on sample expenses; June entries spread across 19+ days for realistic daily trend display

---

## [0.19.0] - 2026-06-12

### Added
- `expenseType` field on `Expense` ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â enum (PERSONAL/BUSINESS); defaults to PERSONAL
- `reimbursable` boolean field on `Expense` ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â tracks whether expense can be reimbursed; defaults to false
- `ExpenseRequest` and `ExpenseResponse` DTOs updated to include expenseType and reimbursable
- Expense modal UI updated to allow selection of expense type and reimbursable flag
- Backend service and integration tests updated to handle new fields

---

## [0.18.0] - 2026-06-11

### Added
- `Alert` entity ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â stores budget warnings, budget-exceeded alerts, and spending-spike nudges per user per month; tracks read/dismissed state
- `GET /alerts?month=YYYY-MM` ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â auto-generates alerts from live budget + expense data (idempotent upsert); returns non-dismissed alerts sorted by severity
- `PATCH /alerts/{id}/read` ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â mark alert as read; `PATCH /alerts/{id}/dismiss` ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â dismiss alert (hides from future responses); `DELETE /alerts/{id}` ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â hard delete
- Alert types: `BUDGET_WARNING` (ÃƒÂ¢Ã¢â‚¬Â°Ã‚Â¥80% of budget spent), `BUDGET_EXCEEDED` (ÃƒÂ¢Ã¢â‚¬Â°Ã‚Â¥100%), `SPENDING_SPIKE` (current month > previous month ÃƒÆ’Ã¢â‚¬â€ 1.5)
- Alerts page (`/alerts`) ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â month picker, severity badges (CRITICAL/WARNING/INFO), mark-read and dismiss per alert
- Dashboard: **Spending Alerts** card ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â shows up to 4 active alerts; mark-read button inline
- Alerts nav link in Navbar
- `@OnDelete(CASCADE)` added to `Expense.user` FK (fixes cross-test FK violations in integration test suite)

---

## [0.17.0] - 2026-06-11

### Added
- `SavingsGoal` entity ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â named goal with `targetAmount`, `savedAmount`, optional `targetDate`, `paused` flag; per-user scoped
- Status derivation: `PAUSED` ÃƒÂ¢Ã¢â‚¬Â Ã¢â‚¬â„¢ `COMPLETED` (saved ÃƒÂ¢Ã¢â‚¬Â°Ã‚Â¥ target) ÃƒÂ¢Ã¢â‚¬Â Ã¢â‚¬â„¢ `ON_TRACK` / `BEHIND` (linear interpolation against elapsed time fraction when `targetDate` present; `ON_TRACK` when no deadline)
- `GET /goals`, `POST /goals`, `GET /goals/{id}`, `PUT /goals/{id}`, `DELETE /goals/{id}` ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â full CRUD for savings goals
- Goals page (`/goals`) ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â card grid with progress bar, status badge, add/edit/delete modals
- Dashboard: **Goal Progress** card ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â shows up to 4 active (non-PAUSED, non-COMPLETED) goals sorted by target date; links to Goals page
- Goals nav link in Navbar

---

## [0.16.0] - 2026-06-11

### Added
- `GET /expenses/export?from=&to=` ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â exports all expenses matching the current date filter as a CSV file; both params optional; respects per-user scoping
- CSV columns: `Date` (yyyy-MM-dd HH:mm), `Description`, `Category`, `Amount` ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â roundtrippable with the existing CSV import format
- Expenses page: **Export CSV** button in the filter toolbar; passes active `from`/`to` filter so "what you see is what you download"; shows "ExportingÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¦" spinner while download is in progress

---

## [0.15.0] - 2026-06-11

### Added
- Recurring Bills page (`/recurring`) ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â CRUD for expenses that repeat monthly, weekly, or yearly; YEARLY bills scoped to a specific month via `monthOfYear` field; monthly day capped at 28 for MONTHLY frequency to fire every month including February; YEARLY respects target month's actual length
- `GET /recurring/upcoming?month=YYYY-MM` ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â returns all bills due in the given month with ISO due dates; weekly bills expand to individual occurrences
- Dashboard: Upcoming Bills card ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â shows up to 5 upcoming bills for the current month; links to Recurring page
- Recurring nav link in sidebar
- `CategoryCombobox` shared component ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â type-to-filter + select from existing categories; "Create" affordance when typed name has no match; `allowCreate` prop; used in both Budget and Recurring forms
- Budget page: editable category in edit mode with inline amber retarget warning; create-new-category from the modal via `CategoryCombobox`; `formatMonth` display replacing raw ISO strings; reload icon button; Delete All for current month (with confirm modal and error display)
- Recurring page: reload icon button; Delete All (with confirm modal and error display)
- `DELETE /budgets?month=YYYY-MM` ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â deletes all budgets for the authenticated user in the given month
- `DELETE /recurring` ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â deletes all recurring expenses for the authenticated user
- Categories page: delete error stays visible inside the modal on failure; modal does not dismiss until the user acknowledges
- Demo seed data: 54 synthetic expenses spanning JanÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Å“Jun 2026 across all 13 predefined categories; 5 sample budgets for June 2026; 6 recurring expenses seeded on first startup when `GASTOS_SEED_SAMPLE_DATA=true`

---

## [0.14.0] - 2026-06-11

### Added
- `GET /ai/insights/top-category?month=YYYY-MM` ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â returns the top spending category, total, and percentage of month total for the given month
- `GET /ai/insights/month-summary?month=YYYY-MM` ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â returns an AI-generated natural-language spending summary for the month
- `GET /ai/insights/recommendations?month=YYYY-MM` ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â returns 2ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Å“3 AI-generated actionable spending recommendations based on category and MoM data
- Dashboard: AI Insights card ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â displays top category, month summary paragraph, and recommendations list; renders below Budget Overview; supports dark mode and animated skeleton loading state
- `ExpenseService.categoryReportForMonth()` ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â month-scoped category aggregation used by all three insight endpoints

---

## [0.13.0] - 2026-06-11

### Changed
- `POST /ai/vision` now accepts a `mode` form parameter (`plain` / `professional` / `genz`; defaults to `plain`); the AI generates a mode-appropriate `rejectionMessage` in `ParsedExpenseResult` when `saveable=false`, replacing the previous hardcoded frontend strings
- ChatWidget: non-receipt image rejection message is now AI-generated and contextual (references what the image actually shows, toned to the active chat mode); falls back to a generic message if `rejectionMessage` is null
- `ParsedExpenseResult` fields `amount`, `category`, `date`, `description` corrected to nullable in the TypeScript type

---

## [0.12.0] - 2026-06-11

### Changed
- `POST /ai/vision` now returns `ParsedExpenseResult` (structured JSON) instead of a plain-text `AiQueryResponse`; the AI is prompted to extract amount, category, date, description, and confidence from receipt images; non-receipt images return `saveable: false` with a text description in `hint`
- ChatWidget: uploading a receipt image now renders a saveable draft card (same UI as the text-parse flow) with pre-filled amount, category, and date; non-receipt images render the hint as a plain chat bubble

---

## [0.11.0] - 2026-06-11

### Added
- `GET /expenses?from=YYYY-MM-DD&to=YYYY-MM-DD` ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â date-range filtering on expense list; either param is optional; admin users see all matching expenses, regular users see only their own
- `GET /expenses/report/monthly-comparison?month=YYYY-MM` ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â returns current month total, previous month total, and percentage change; `changePercent` is null when no previous data exists
- Dashboard: Monthly Trend bar chart ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â visualises up to 12 months of spending using recharts `BarChart`
- Dashboard: Spending Trend card ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â side-by-side "This month / Last month" amounts with a plain-English change sentence ("You spent 11.8% more than May 2026") colour-coded green/red
- Expenses page: date-range filter bar (From / To date inputs + Clear); results debounce 350 ms before hitting the API; stale data stays visible during fetch with an inline spinner
- `ui-ux-reviewer` agent ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â reviews dashboard and table UI/UX decisions against data-viz and financial-app best practices; sourced from TanStack Table, Pencil & Paper, UXPin
- `resource-finder` agent ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â searches and ranks libraries/tools by adoption, community consensus, security posture, and real-user satisfaction before any new dependency is introduced

### Changed
- Expense list default sort is date DESC (newest first)

---

## [0.10.0] - 2026-06-10

### Added
- Budgets feature ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â set monthly spending limits per category via `POST /budgets`; full CRUD (`GET`, `PUT`, `DELETE`) with per-user ownership enforcement
- `GET /budgets/summary?month=YYYY-MM` ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â returns per-category spent vs budgeted, remaining, percent used, and status (`ON_TRACK` / `WARNING` at 80% / `OVER_BUDGET` at 100%)
- Safe-to-spend and daily allowance calculated from total budget minus total spent; daily allowance prorates over remaining calendar days in the month
- Budget page (`/budget`) ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â month picker, budget list with inline add/edit/delete modal, category dropdown
- Budget Overview card on Dashboard ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â headline safe-to-spend, daily allowance, status-coloured progress bars per category

### Changed
- Semantic versioning rules updated: `BREAKING CHANGE` / `feat!:` / `fix!:` now always bumps MAJOR (e.g. `0.9.0 ÃƒÂ¢Ã¢â‚¬Â Ã¢â‚¬â„¢ 1.0.0`); pre-1.0 exception removed to follow Conventional Commits spec
- Breaking change definition added to CLAUDE.md and pre-PR checklist: adding new endpoints/fields/tables is `feat:`, not a breaking change

---

## [0.9.0] - 2026-06-10

### Changed
- Category lookups and creation are now case-insensitive ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â `"food"`, `"Food"`, and `"FOOD"` resolve to the same category; duplicate creation via different casings is rejected

---

## [0.8.0] - 2026-06-10

### Added
- `POST /expenses/parse` ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â natural-language text parse endpoint; accepts free-form text (e.g. "spent 250 on lunch") and returns a draft expense with amount, category, date, description, and confidence level without saving
- `ExpenseParser` interface with OpenAI and Claude implementations; active provider follows the existing `GASTOS_AI_PROVIDER` env var
- `ParsedExpenseResult` includes `saveable` (boolean) and `hint` (string|null); HIGH-confidence parses with a positive amount are marked saveable, LOW-confidence returns a hint asking for more detail
- ChatWidget: expense-logging intent detection ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â messages with spending keywords (English + Filipino), currency indicators, or a numeric amount without a query phrase are routed to `POST /expenses/parse`
- ChatWidget: draft expense card ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â shows amount, category, date, and description with a "Save expense" button; fires `gastosai:expense-created` on save so Expenses and Dashboard lists refresh immediately
- Suggestion chip: "spent 250 on Jollibee lunch" to guide users toward the log-expense flow
- AI parse prompt injects current Philippine Time date and predefined category mapping rules to improve accuracy

### Fixed
- Expenses list and Dashboard recent expenses now sorted by date DESC ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â newly added expenses appear at the top

---

## [0.7.0] - 2026-06-10

### Added
- Avatar color picker in Settings ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â users can choose from 6 gradient presets; selection is persisted and reflected immediately in the Navbar avatar and Settings header
- Category icon picker ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â add/edit category modal now shows a 24-icon grid; selected icon is stored on the backend and displayed on the category card; falls back to name-based icon mapping if none set
- Email editing in Settings ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â email field is now editable; backend validates uniqueness and issues a fresh JWT so the session stays valid after an email change

### Fixed
- Dark mode text visibility in ChatWidget ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â suggestion chips and accent text in all 3 modes (Plain, Pro, Gen Z) now have proper dark-mode colour variants
- Category colour badges (Expenses table, Dashboard recent list) and category cards (Categories page) now use dark-tinted backgrounds and light text in dark mode instead of light-on-dark

---

## [0.6.0] - 2026-06-10

### Added
- `lucide-react` icon library; all inline SVG icons replaced with lucide equivalents (`Pencil`, `Trash2`, `Upload`, `Loader2`, `Sun`, `Moon`, `LogOut`)
- Category cards now display a semantic icon per category name (e.g. Car for Transportation, Utensils for Meal Plan, GraduationCap for Training/Upskilling); user-created categories fall back to the Tag icon
- Navbar profile link replaced with an avatar button showing user initials in a circle ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â clearly clickable with hover state and active highlight; name label visible on sm+ screens
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
- Full Docker stack via `docker compose --profile app up -d --build` ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â backend and frontend now containerised alongside the existing DB service
- `scripts/start.ps1` option 6: start the full stack through Docker Compose
- Named volume `postgres_data` so DB data survives `docker compose down` (only wiped with `down -v`)
- DB health check in `docker-compose.yaml`; backend waits for Postgres to be healthy before starting
- Memory limits on all Docker services: DB 256 MB, backend 512 MB, frontend 64 MB
- BuildKit cache mounts in Dockerfiles for faster Maven and npm rebuilds
- `frontend/Dockerfile` multi-stage build: Node 22 Alpine ÃƒÂ¢Ã¢â‚¬Â Ã¢â‚¬â„¢ nginx Alpine (~20 MB runtime image)
- `frontend/nginx.conf` with SPA fallback routing and gzip compression
- Demo user credentials (name, email, password) now configurable via `GASTOS_DEMO_NAME`, `GASTOS_DEMO_EMAIL`, `GASTOS_DEMO_PASSWORD` env vars

### Fixed
- Category seed data: "Transporation" corrected to "Transportation"
- `scripts/start.ps1`: em-dash inside string literal replaced with `--` to fix PowerShell 5.1 Windows-1252 parse error

### Changed
- Backend Docker runtime switched from `eclipse-temurin:25-jdk` to `eclipse-temurin:25-jdk-alpine` (~40% smaller image); runs as non-root `spring` user
- `scripts/teardown.ps1` option 3 now explicitly documents that `docker compose down` stops all Docker services including app-profile containers
- Pre-PR checklist: added mandatory runtime execution-testing rule (ÃƒÂ¢Ã¢â‚¬Â°Ã‚Â¥90% of touched paths), infrastructure breaking-change rule, and PS encoding rule

---

## [0.5.1] - 2026-06-09

### Fixed
- Settings page: removed `useEffect` that called `setState` synchronously, resolving the `react-hooks/set-state-in-effect` lint error in CI

### Docs
- Split `ai/skills` into `shared/` (reusable, project-agnostic) and project-specific files
- Added `ai/skills/shared/pre-pr-checklist.md` ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â mandatory lint/build/test gate before every PR

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
- CI `Permission denied` error on `./mvnw` ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â set executable bit in git index

### Changed
- Test requirements are now mandatory (Blocker) for all feature and bug-fix commits

---

## [0.3.0] - 2026-06-09

### Added
- Admin role (`ROLE_ADMIN`) with configurable credentials via `GASTOS_ADMIN_EMAIL` / `GASTOS_ADMIN_PASSWORD` env vars
- Admin users bypass per-user expense scoping ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â sees all users' data in expenses, reports, and AI queries
- `commit-msg` git hook enforcing SemVer version bumps on `feat`/`fix`/`perf` commits that touch app code

### Changed
- `CLAUDE.md` documents one-time hook setup and version bump rules

---

## [0.2.0] - 2026-06-09

### Added
- Multi-user JWT authentication (register, login, logout)
- `AuthContext` and `ProtectedRoute` on the frontend
- Login (`/login`) and register (`/register`) pages
- Per-user expense data isolation ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â each user sees only their own expenses
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
