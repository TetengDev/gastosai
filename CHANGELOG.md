# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/)
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]

---

## [0.44.0] - 2026-06-20

### Added
- Passwordless **email magic-link login** — enter your email, get a one-time sign-in link, click it to log in. Works alongside the existing email+password login. First-time emails get a passwordless account automatically. Endpoints: `POST /auth/magic-link`, `POST /auth/magic-link/verify`. Tokens are single-use, hashed at rest, and expire in 15 minutes.
- Dev fallback: when SMTP isn't configured the sign-in link is logged to the backend (so local dev needs no mail server); production uses SMTP via `MAIL_*` env vars.

### Security
- Magic-link: no user enumeration (uniform response), CRLF/email-header-injection rejected, request rate-limited per email, tokens never logged in production, passwordless accounts can't be password-logged-in.

## [0.43.0] - 2026-06-20

### Added
- Chatbot CRUD parity — the assistant now does (almost) everything you can do by navigating the app. 14 new tools: read/list (`list_goals`, `list_budgets` with status, `list_recurring` with upcoming bills, `list_alerts`, `search_expenses`, `get_category_totals`, `get_monthly_report`), alerts CRUD (mark read / dismiss / delete), category settings (set default, set icon), and confirmation-gated bulk ops (delete expenses, recategorize expenses). Rich chat rendering for each (lists, progress bars, status/severity badges).

### Fixed
- "List my goals / budgets / recurring / alerts" no longer misroutes to expense category totals — intent routing now sends these to the proper read tools instead of the NL→SQL expense path.

### Security
- Every new chat tool is user-scoped (no cross-user access); bulk delete/recategorize require explicit confirmation; an unscoped bulk delete (no ids or filters) is refused. `SqlGuard` unchanged.

## [0.42.0] - 2026-06-19

### Added
- Managed AI provider mode (behind `AI_ALLOW_SHARED_KEY`): serve AI from one backend-funded key instead of requiring each user to bring their own. BYOK remains the default; managed turns on when the flag + a funded provider key are set, with fail-fast startup validation.
- Per-user AI usage metering (`ai_usage` table, Flyway V9) + `GET /ai/usage` (plan, used, limit, remaining, vision sub-usage, managed flag, reset date) + a usage indicator in Settings.
- Per-plan monthly AI quotas (env-configurable): FREE 30 / PREMIUM 300 / TRIAL 50, with receipt-scan sub-caps 5 / 50 / 10; insights are exempt (cached), ADMIN bypasses; over-cap returns HTTP 429. Pricing rationale in `docs/pricing/pricing-memo-2026-06-19.md`.
- AI redaction layer: card numbers, emails, and phone numbers are masked before any prompt is sent to the provider (chat, NL query, expense parse, receipt scan).
- `pricing-agent` (`.claude/agents/pricing-agent.md`) for research-backed PHP pricing.

### Changed
- PREMIUM plan price set to ₱149 (from ₱199); the seeder now reconciles the price on existing databases.

### Security
- AI provider keys never reach the frontend bundle, API responses, or logs; full prompts are not logged. Per-request LLM timeout, prompt-size cap, and bounded retries added.

## [0.41.0] - 2026-06-18

### Added
- Contact and Feedback pages — public (no login) forms to send a message or a suggestion. Submissions are stored and shown to admins in a new in-app "Messages" view (`/admin/submissions`). Backed by a new `submissions` table (Flyway V8); `POST /submissions` is public, `GET /submissions` is admin-only.
- Site footer with links to About, Contact, Feedback, FAQ, Privacy, and Terms (plus app version), shown on every page.
- New informational pages: About, FAQ, Privacy Policy, and Terms of Service (with a lightweight public layout).
- Styled 404 Not Found page for unknown routes.

### Changed
- Dashboard "Recent Expenses" now lists the 10 most recent entries (was 6).

---

## [0.40.0] - 2026-06-17

### Added
- Preferred default category: star a category on the Categories screen to make it the default preselected when adding an expense (falls back to Uncategorized). Stored per user (`users.default_category_name`, Flyway V6) and returned in auth/profile responses.
- Category icons now appear wherever a category is shown — Expenses table, dashboard (Spending by Category, Recent Expenses, Top Expenses), Upcoming Bills, Budget, and Recurring — via a shared `categoryIcon` helper + `CategoryChip`.
- Avatar icons: pick a bundled icon for your avatar in Settings (alongside the color); shown in the navbar + Settings (falls back to initials). Stored per user (`users.avatar`, Flyway V7).
- Chatbot full coverage: manage Categories (create/rename/delete/list), update Budgets/Goals/Recurring, update profile (name/nickname/avatar/default category), and read your plan via chat. Goal/recurring duplicates offer to update instead of erroring; likely-duplicate expenses ask before adding. Paste your OpenAI key in chat to set it (stored encrypted, redacted from chat history, never sent to the model). `SqlGuard` read-only safety unchanged.

### Changed
- Dashboard reordered for clearer hierarchy (ui-ux-reviewed): hero → Daily Trend + **Recent Expenses** side by side → AI Insights → Spending by Category + Budget → Alerts + Top Expenses → Goals + Upcoming Bills → Monthly Trend. Monthly-Trend axis abbreviates (₱12.5k); Alerts empty state reassures.

### Changed
- Login and Register screens restyled to the design system (tokens, brand wordmark, primitives) — they no longer use the old indigo theme.

---

## [0.39.0] - 2026-06-17

### Added
- Structured JSON logging in production (Spring Boot native ECS format to stdout) for ingestion by a hosted aggregator — dev keeps human-readable console logs.
- Per-request correlation id + access log: `RequestLoggingFilter` assigns/propagates an `X-Request-Id` (echoed in the response header) and logs one `http_request` line per request with method, path, status, duration, and user — no secrets.
- `docs/observability.md`: log format, request-context fields, and how to ship logs to a free aggregator (Grafana Cloud Loki / Better Stack).

---

## [0.38.0] - 2026-06-17

### Added
- Multi-select delete on Budgets, Recurring, Goals, and Categories (matching the Expenses pattern): row/card checkboxes, a selection bar with a bulk "Delete selected" action, and select-all on the table screens. Backed by a shared `useMultiSelect` hook + `SelectionBar` primitive. "Uncategorized" is excluded from category selection (protected default).
- Info "?" tooltips on every dashboard section (hero total, AI Insights, Daily Trend, Spending by Category, Budget Overview, Alerts, Savings Goals, Upcoming Bills, Top Expenses, Monthly Trend, Recent Expenses) explaining what each metric means.
- Tips system: a navbar lightbulb opens a rotating "did you know" tips popover surfacing app capabilities, with per-tip dismissal persisted in localStorage and a "show again" reset.

### Fixed
- Dashboard info tooltips no longer clip inside cards: `InfoTip` now portals its tooltip to `<body>` (fixed positioning) and adds `aria-describedby` for screen readers.

---

## [0.37.1] - 2026-06-17

### Fixed
- Navbar wordmark rendered as "Gastos AI" (a flex gap split the text from the accent span); now renders "GastosAI" as one word.
- Browser-tab favicon recolored from the old indigo to the brand green.
- Chat launcher (FAB) was nearly invisible in dark mode (near-black on near-black); now uses the active tone's accent color (green/slate/pink).
- Chat panel now follows the global light/dark theme (it was forced always-dark); per-tone accents (green/slate/pink) retained.

---

## [0.37.0] - 2026-06-17

### Added
- Visual redesign foundation (from the Claude Design handoff): a light/dark design-token system, the Space Grotesk / Hanken Grotesk / Space Mono type scale, and shared UI primitives (`Button`, `Card`, `PageHeader`, `Modal`, `ConfirmDialog`, `Pill`, `IconButton`, `ProgressBar`, `StatTile`).
- Dismissible announcement bar (persisted) pointing to the bring-your-own AI key setting.

### Changed
- Full visual redesign applied across every screen — Dashboard (deep-green hero + stat grid, daily-trend & category bars, budget/alerts), Expenses, Categories, Budget, Recurring, Goals, Settings, and the Chat widget — using the new tokens, type scale, and shared primitives.
- Navbar restyled to the new design: translucent sticky bar, centered pill navigation, brand wordmark, token-based colors that follow light/dark.
- App shell now uses the token page background and a wider 1240px content width.
- Chat widget is now an always-dark panel with per-tone accents (Plain green, Pro slate, Gen Z pink).
- Unified delete UX: one `ConfirmDialog` and shared `Modal` across screens.

### Fixed
- Notification bell and admin "View as" toggle were invisible on the light navbar (leftover white text); retoned to theme tokens.

---

## [0.36.0] - 2026-06-16

### Fixed
- Chatbot suggestions (and any natural-language expense logging) no longer error when AI is enabled: `/expenses/parse` now runs through the per-user BYO key path (it previously used the server placeholder key and failed in production).
- Tour steps reordered to match the navbar (Expenses — Budget — Recurring — Goals) and restyled (spacing, spotlight, overlay).

### Added
- "Uncategorized" is protected as the sole default category: always present, badged, sorted to the top of the list, and not deletable; all other categories remain editable/deletable.
- Admin accounts are always seeded with sample expenses/budgets/goals/recurring on startup (independent of `GASTOS_SEED_SAMPLE_DATA`) so testing always has data.

---

## [0.35.0] - 2026-06-16

### Added
- Admin accounts now always have every feature (bypass entitlement gating regardless of monetization enforcement).
- Admin-only **"View As"** switcher in the navbar: preview the app as a Free or Premium tier, with AI on/off, and as a regular user — without changing real data or keys. Sends `X-View-As-*` headers honored only for admins; `EntitlementService`/AI gate simulate the chosen state, and the UI (FeatureGate, insights, chat) updates live.
- `AuthResponse` now returns `role`; `GET /user/entitlements` returns `admin`.

---

## [0.34.0] - 2026-06-16

### Added
- First-run onboarding tour (react-joyride): new users get a one-time guided walkthrough of the nav (Expenses, Budget, Goals, Recurring), the AI chat, and where to add their OpenAI key. Dismissal is persisted per browser (`gastosai:tour:completed`); a "Replay tour" button in Settings re-runs it. Backend `AuthResponse` now returns `firstLogin` (true on register, false on login) to trigger it.

---

## [0.33.0] - 2026-06-16

### Added
- Strict CSV import mode (`POST /expenses/import?strict=true`): any invalid or skippable row rejects the whole file with a per-row reason list and persists nothing; valid files import atomically in one transaction. Lenient (default) behavior unchanged. Expenses page gains a "Strict" checkbox.
- CSV format helper: a `?` info modal documenting columns/rules + a downloadable template (`GET /expenses/import/template`).

---

## [0.32.0] - 2026-06-16

### Added
- Server-side caching (Caffeine) for AI insight responses (top-category, month-summary, recommendations), keyed per user + month. Repeat dashboard loads within the TTL skip the LLM call — faster and fewer tokens spent on the user's key. Cache is evicted on any expense create/update/delete. Tunable via `gastos.insights.cache.{enabled,ttl-minutes,max-size}` (`INSIGHTS_CACHE_*` env), default 15-min TTL.

---

## [0.31.1] - 2026-06-16

### Fixed
- AI features now correctly **require a per-user OpenAI key**: without one the AI endpoints return `402` and the UI shows a "Connect your OpenAI key" prompt (insights card + chat disabled), instead of falling back to a server key. 0.31.0 shipped the pre-refinement build where this gate was missing. Optional `AI_ALLOW_SHARED_KEY=true` still re-enables a shared key.

---

## [0.31.0] - 2026-06-16

### Added
- Bring-your-own AI key: each user saves their own OpenAI key in Settings (stored encrypted with AES-256-GCM, never returned to the client). AI features (insights, chat, NL query, receipt scanning) **require the user's own key** — without one, those surfaces show a "Connect your OpenAI key" prompt and are disabled, while all non-AI features keep working. No fallback to a server key by default, so the operator incurs no AI cost. Endpoints: `GET/PUT /user/ai-settings`, `DELETE /user/ai-settings/{provider}` (booleans + `aiAvailable` only). Env: `AI_KEY_ENCRYPTION_SECRET` (encrypts keys at rest); optional `AI_ALLOW_SHARED_KEY=true` re-enables a shared server key.

---

## [0.30.0] - 2026-06-16

### Added
- Budget duplicate overwrite: `POST /budgets?force=true` overwrites an existing budget for the same category and month instead of returning `409`, and the Budget page now shows an explicit Overwrite/Cancel confirm on a duplicate. Without `force`, a duplicate still returns `409`. Matches the duplicate-handling of goals and recurring expenses.

### Fixed
- Budget safe-to-spend was wrong for seeded/demo data: `AppDataLoader` created budgets without `amountLimitInBaseCurrency`, which `BudgetService.getSummary` uses as the budget amount, so `totalBudgeted`/`safeToSpend`/`percentUsed`/`status` were all incorrect (over-budget categories showed `ON_TRACK` at 0%). Existing databases need a reseed to pick up correct values.
- `GET /budgets/summary` with an out-of-range calendar month (e.g. `2026-13`) returned `401` instead of `400` — an unhandled `DateTimeException` fell through to Spring Security. It now validates the month via `YearMonth` and returns a proper `400`.
- Budget `month` validation now rejects invalid calendar months (`00`, `13`+); the pattern previously accepted any two digits, allowing unqueryable budgets to be created.
- Budget `exchangeRate` must now be greater than 0; a `0` or negative rate was silently accepted and produced a base-currency amount of 0.
- Missing required request parameters (e.g. `?month`) now return `400` instead of `401` (`MissingServletRequestParameterException` was unhandled and fell through to Spring Security).

---

## [0.29.0] - 2026-06-16

Manual-QA fixes.

### Added
- Expenses: checkbox multi-select with a "Delete Selected (N)" bulk-delete bar.
- Recurring & Goal creates detect duplicates (recurring by name+frequency, goal by name) and prompt to **Update existing** or **Create anyway**.

### Fixed
- Duplicate Budget/Recurring/Goal no longer logs the user out — domain conflicts now return HTTP 409 (`GlobalExceptionHandler` handles `ResponseStatusException` directly instead of forwarding to an authenticated `/error`, which surfaced as 401); `/error` is also permitted.
- Budget duplicate offers to update the existing budget instead of failing.
- Dashboard "This Month" KPI now reflects the current-month total (and updates when a current-month expense is edited) — previously summed the all-time category report.

### Changed
- AI Insights render progressively (each insight as its call resolves) instead of blocking on the slowest. Server-side caching tracked as a follow-up.

---

## [0.28.1] - 2026-06-15

### Changed
- Began extracting `ChatWidget` into a `chat/` module (behavior-preserving): presentational chrome (`ChatChrome.tsx`) and CRUD action helpers (`chatActions.ts`). No user-facing change; the stateful component split (DraftCard/ActionPreviewCard/DisambiguateList/MessageList/useChatController) is tracked as a follow-up.

---

## [0.28.0] - 2026-06-15

Deferred follow-ups (security + tooling). Backwards compatible.

### Fixed
- AI NL-query fallback is now always user-scoped, including admins — admins previously ran unscoped raw AI SQL (Phase 1 audit HIGH). Cross-user analytics, if ever needed, must be a separate audited endpoint.
- `scripts/bump-version.ps1` no longer crashes on the CHANGELOG step under `Set-StrictMode` (single-element slice unwrapped to a scalar, breaking `.Count`).

### Added
- Circuit breaker (`resilience4j-circuitbreaker` core) on `/ai/query` and `/ai/chat`: when the LLM provider fails past the threshold, requests fast-fail to a friendly degraded message instead of cascading 500s.

### Deferred
- ChatWidget decomposition — tracked for its own focused PR.

---

## [0.27.0] - 2026-06-15

Production-refactor batch (Phases 3 — 4): frontend entitlement gating + backend hardening.
Monetization enforcement remains **disabled** by default — no UX change.

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
- `SqlGuard` now rejects subqueries/CTEs, guaranteeing the fallback NL — SQL path is a single flat
 SELECT — closes the `appendUserFilter` user-scoping bypass flagged in the AI-path security review.
- `SecurityStartupValidator` warns when sample-data seeding targets a remote database.

### Deferred
- ChatWidget decomposition and a Resilience4j circuit breaker (need focused review / dependency vetting).

---

## [0.26.0] - 2026-06-15

Production-refactor batch (Phases 0 — 2). All changes are backwards compatible and additive;
monetization enforcement ships **disabled** (`gastos.monetization.enforce=false`), so no feature
is gated yet and there is no UX change.

### Added
- Safe AI analytics query pipeline (`ai.query`): the LLM emits a structured, validated query intent
 (metric/date-range/category/sort/limit allowlists) that the server turns into a fully parameterized,
 user-scoped query (`AnalyticsQueryPlanner` + `SafeAnalyticsExecutor`, statement timeout). Falls back
 to the existing SqlGuard NL — SQL path when no valid intent is produced, so no analytics is lost.
- Subscription/feature-entitlement foundation: `subscription_plans`, `plan_features`,
 `user_subscriptions` (V3 migration + entities + repositories), `FeatureKey`/`PlanKey`/
 `SubscriptionStatus`, idempotent `EntitlementSeeder` (FREE/PREMIUM).
- `EntitlementService` (`canAccessFeature`/`requireFeatureAccess`) as the single access authority;
 `@RequiresFeature` + `FeatureAccessInterceptor` enforce it on `/ai/query`, `/ai/chat`,
 `/ai/insights/*`, `/expenses/export`. `FeatureLockedException` — HTTP 402.
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
- Chatbot CRUD actions via LLM function-calling (`POST /ai/chat`) — create/delete expenses, budgets, goals, and recurring items in plain language
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
- `RECURRING_DUE` alert type — generates reminders when a recurring expense is due within 3 days
- `NotificationBell` component in Navbar — Bell icon with unread count badge, replaces text "Alerts" link
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
- `spring.jpa.hibernate.ddl-auto` switched from `create-drop` to `validate` — schema now managed exclusively by Flyway migrations
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
- Dashboard cards (BudgetOverview, DailyTrend, TopExpenses, AlertsCard, GoalProgress, UpcomingBills) now re-fetch whenever any related data changes — not just on mount
- Renamed internal event `gastosai:expense-created` to `gastosai:expense-changed` for semantic accuracy
- `useExpenses` hook dispatches `gastosai:expense-changed` after every add, update, delete, and delete-all
- Budget, Goals, Recurring, and Categories pages dispatch entity-specific events (`gastosai:budget-changed`, `gastosai:goal-changed`, `gastosai:recurring-changed`, `gastosai:expense-changed`) on every mutation so dashboard cards stay in sync with off-screen changes

---

## [0.20.0] - 2026-06-12

### Added
- `GET /expenses/report/daily?month=YYYY-MM` — returns daily spending totals for all days in a month (missing days = 0); enables day-by-day trend analysis
- `GET /expenses/report/top?month=YYYY-MM&limit=5` — returns top N expenses by amount descending for a given month
- Daily Trend card on Dashboard — bar chart showing per-day spending with recharts BarChart
- Top Expenses card on Dashboard — ranked list of highest single expenses for the current month
- Seed data updated: `expenseType`/`reimbursable` seeded on sample expenses; June entries spread across 19+ days for realistic daily trend display

---

## [0.19.0] - 2026-06-12

### Added
- `expenseType` field on `Expense` — enum (PERSONAL/BUSINESS); defaults to PERSONAL
- `reimbursable` boolean field on `Expense` — tracks whether expense can be reimbursed; defaults to false
- `ExpenseRequest` and `ExpenseResponse` DTOs updated to include expenseType and reimbursable
- Expense modal UI updated to allow selection of expense type and reimbursable flag
- Backend service and integration tests updated to handle new fields

---

## [0.18.0] - 2026-06-11

### Added
- `Alert` entity — stores budget warnings, budget-exceeded alerts, and spending-spike nudges per user per month; tracks read/dismissed state
- `GET /alerts?month=YYYY-MM` — auto-generates alerts from live budget + expense data (idempotent upsert); returns non-dismissed alerts sorted by severity
- `PATCH /alerts/{id}/read` — mark alert as read; `PATCH /alerts/{id}/dismiss` — dismiss alert (hides from future responses); `DELETE /alerts/{id}` — hard delete
- Alert types: `BUDGET_WARNING` ( — 80% of budget spent), `BUDGET_EXCEEDED` ( — 100%), `SPENDING_SPIKE` (current month > previous month — 1.5)
- Alerts page (`/alerts`) — month picker, severity badges (CRITICAL/WARNING/INFO), mark-read and dismiss per alert
- Dashboard: **Spending Alerts** card — shows up to 4 active alerts; mark-read button inline
- Alerts nav link in Navbar
- `@OnDelete(CASCADE)` added to `Expense.user` FK (fixes cross-test FK violations in integration test suite)

---

## [0.17.0] - 2026-06-11

### Added
- `SavingsGoal` entity — named goal with `targetAmount`, `savedAmount`, optional `targetDate`, `paused` flag; per-user scoped
- Status derivation: `PAUSED` — `COMPLETED` (saved — target) — `ON_TRACK` / `BEHIND` (linear interpolation against elapsed time fraction when `targetDate` present; `ON_TRACK` when no deadline)
- `GET /goals`, `POST /goals`, `GET /goals/{id}`, `PUT /goals/{id}`, `DELETE /goals/{id}` — full CRUD for savings goals
- Goals page (`/goals`) — card grid with progress bar, status badge, add/edit/delete modals
- Dashboard: **Goal Progress** card — shows up to 4 active (non-PAUSED, non-COMPLETED) goals sorted by target date; links to Goals page
- Goals nav link in Navbar

---

## [0.16.0] - 2026-06-11

### Added
- `GET /expenses/export?from=&to=` — exports all expenses matching the current date filter as a CSV file; both params optional; respects per-user scoping
- CSV columns: `Date` (yyyy-MM-dd HH:mm), `Description`, `Category`, `Amount` — roundtrippable with the existing CSV import format
- Expenses page: **Export CSV** button in the filter toolbar; passes active `from`/`to` filter so "what you see is what you download"; shows "Exporting — " spinner while download is in progress

---

## [0.15.0] - 2026-06-11

### Added
- Recurring Bills page (`/recurring`) — CRUD for expenses that repeat monthly, weekly, or yearly; YEARLY bills scoped to a specific month via `monthOfYear` field; monthly day capped at 28 for MONTHLY frequency to fire every month including February; YEARLY respects target month's actual length
- `GET /recurring/upcoming?month=YYYY-MM` — returns all bills due in the given month with ISO due dates; weekly bills expand to individual occurrences
- Dashboard: Upcoming Bills card — shows up to 5 upcoming bills for the current month; links to Recurring page
- Recurring nav link in sidebar
- `CategoryCombobox` shared component — type-to-filter + select from existing categories; "Create" affordance when typed name has no match; `allowCreate` prop; used in both Budget and Recurring forms
- Budget page: editable category in edit mode with inline amber retarget warning; create-new-category from the modal via `CategoryCombobox`; `formatMonth` display replacing raw ISO strings; reload icon button; Delete All for current month (with confirm modal and error display)
- Recurring page: reload icon button; Delete All (with confirm modal and error display)
- `DELETE /budgets?month=YYYY-MM` — deletes all budgets for the authenticated user in the given month
- `DELETE /recurring` — deletes all recurring expenses for the authenticated user
- Categories page: delete error stays visible inside the modal on failure; modal does not dismiss until the user acknowledges
- Demo seed data: 54 synthetic expenses spanning Jan — Jun 2026 across all 13 predefined categories; 5 sample budgets for June 2026; 6 recurring expenses seeded on first startup when `GASTOS_SEED_SAMPLE_DATA=true`

---

## [0.14.0] - 2026-06-11

### Added
- `GET /ai/insights/top-category?month=YYYY-MM` — returns the top spending category, total, and percentage of month total for the given month
- `GET /ai/insights/month-summary?month=YYYY-MM` — returns an AI-generated natural-language spending summary for the month
- `GET /ai/insights/recommendations?month=YYYY-MM` — returns 2 — 3 AI-generated actionable spending recommendations based on category and MoM data
- Dashboard: AI Insights card — displays top category, month summary paragraph, and recommendations list; renders below Budget Overview; supports dark mode and animated skeleton loading state
- `ExpenseService.categoryReportForMonth()` — month-scoped category aggregation used by all three insight endpoints

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
- `GET /expenses?from=YYYY-MM-DD&to=YYYY-MM-DD` — date-range filtering on expense list; either param is optional; admin users see all matching expenses, regular users see only their own
- `GET /expenses/report/monthly-comparison?month=YYYY-MM` — returns current month total, previous month total, and percentage change; `changePercent` is null when no previous data exists
- Dashboard: Monthly Trend bar chart — visualises up to 12 months of spending using recharts `BarChart`
- Dashboard: Spending Trend card — side-by-side "This month / Last month" amounts with a plain-English change sentence ("You spent 11.8% more than May 2026") colour-coded green/red
- Expenses page: date-range filter bar (From / To date inputs + Clear); results debounce 350 ms before hitting the API; stale data stays visible during fetch with an inline spinner
- `ui-ux-reviewer` agent — reviews dashboard and table UI/UX decisions against data-viz and financial-app best practices; sourced from TanStack Table, Pencil & Paper, UXPin
- `resource-finder` agent — searches and ranks libraries/tools by adoption, community consensus, security posture, and real-user satisfaction before any new dependency is introduced

### Changed
- Expense list default sort is date DESC (newest first)

---

## [0.10.0] - 2026-06-10

### Added
- Budgets feature — set monthly spending limits per category via `POST /budgets`; full CRUD (`GET`, `PUT`, `DELETE`) with per-user ownership enforcement
- `GET /budgets/summary?month=YYYY-MM` — returns per-category spent vs budgeted, remaining, percent used, and status (`ON_TRACK` / `WARNING` at 80% / `OVER_BUDGET` at 100%)
- Safe-to-spend and daily allowance calculated from total budget minus total spent; daily allowance prorates over remaining calendar days in the month
- Budget page (`/budget`) — month picker, budget list with inline add/edit/delete modal, category dropdown
- Budget Overview card on Dashboard — headline safe-to-spend, daily allowance, status-coloured progress bars per category

### Changed
- Semantic versioning rules updated: `BREAKING CHANGE` / `feat!:` / `fix!:` now always bumps MAJOR (e.g. `0.9.0 — 1.0.0`); pre-1.0 exception removed to follow Conventional Commits spec
- Breaking change definition added to CLAUDE.md and pre-PR checklist: adding new endpoints/fields/tables is `feat:`, not a breaking change

---

## [0.9.0] - 2026-06-10

### Changed
- Category lookups and creation are now case-insensitive — `"food"`, `"Food"`, and `"FOOD"` resolve to the same category; duplicate creation via different casings is rejected

---

## [0.8.0] - 2026-06-10

### Added
- `POST /expenses/parse` — natural-language text parse endpoint; accepts free-form text (e.g. "spent 250 on lunch") and returns a draft expense with amount, category, date, description, and confidence level without saving
- `ExpenseParser` interface with OpenAI and Claude implementations; active provider follows the existing `GASTOS_AI_PROVIDER` env var
- `ParsedExpenseResult` includes `saveable` (boolean) and `hint` (string|null); HIGH-confidence parses with a positive amount are marked saveable, LOW-confidence returns a hint asking for more detail
- ChatWidget: expense-logging intent detection — messages with spending keywords (English + Filipino), currency indicators, or a numeric amount without a query phrase are routed to `POST /expenses/parse`
- ChatWidget: draft expense card — shows amount, category, date, and description with a "Save expense" button; fires `gastosai:expense-created` on save so Expenses and Dashboard lists refresh immediately
- Suggestion chip: "spent 250 on Jollibee lunch" to guide users toward the log-expense flow
- AI parse prompt injects current Philippine Time date and predefined category mapping rules to improve accuracy

### Fixed
- Expenses list and Dashboard recent expenses now sorted by date DESC — newly added expenses appear at the top

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
- `frontend/Dockerfile` multi-stage build: Node 22 Alpine — nginx Alpine (~20 MB runtime image)
- `frontend/nginx.conf` with SPA fallback routing and gzip compression
- Demo user credentials (name, email, password) now configurable via `GASTOS_DEMO_NAME`, `GASTOS_DEMO_EMAIL`, `GASTOS_DEMO_PASSWORD` env vars

### Fixed
- Category seed data: "Transporation" corrected to "Transportation"
- `scripts/start.ps1`: em-dash inside string literal replaced with `--` to fix PowerShell 5.1 Windows-1252 parse error

### Changed
- Backend Docker runtime switched from `eclipse-temurin:25-jdk` to `eclipse-temurin:25-jdk-alpine` (~40% smaller image); runs as non-root `spring` user
- `scripts/teardown.ps1` option 3 now explicitly documents that `docker compose down` stops all Docker services including app-profile containers
- Pre-PR checklist: added mandatory runtime execution-testing rule ( — 90% of touched paths), infrastructure breaking-change rule, and PS encoding rule

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
