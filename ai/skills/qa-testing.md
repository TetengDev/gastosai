# Skill: QA / QC Testing

Single source of truth for defining test scope/scenarios and verifying a gastosai feature. Read this before doing QA; the `qa-engineer` agent references it rather than duplicating it.

QA here = **define scenarios → execute what's possible headlessly → report defects + a human checklist**. QA is read-only: it finds and reports; `backend-dev`/`frontend-dev` fix.

---

## 1. Scope & scenario definition (do this first)

For each feature under test, write a short charter:

- **Feature** — what it is, the endpoint(s) + screen(s) involved.
- **In scope / out of scope** — be explicit; out-of-scope prevents wasted effort.
- **Preconditions** — auth, seeded data, feature flags (`gastos.monetization.enforce`).
- **Scenarios**, grouped: **happy path**, **boundary**, **negative/invalid**, **security/isolation**, **regression**.
- **Expected result** per scenario (the oracle).

Keep it a table: `# | Type | Scenario | Steps | Expected | Result`.

## 2. Test-design techniques (pick per field/flow)

| Technique | Use for | gastosai example |
|---|---|---|
| Equivalence partitioning | inputs with classes | CSV `amount`: valid (>0) imports · ≤0/blank skips · non-numeric errors |
| Boundary-value analysis | numeric/date edges | budget `amountLimit` = 0, 0.01, negative, huge; expense dated 1st-of-month 00:00 (timezone) |
| Decision table | combined conditions | duplicate create × `force` flag → 409 vs created |
| State transition | lifecycle | subscription ACTIVE→EXPIRED→FREE entitlement; goal ON_TRACK→COMPLETED |
| Error guessing | known weak spots | empty/whitespace name, currency symbols/commas, expired JWT, huge payload |
| Risk-based | prioritize | money math, user-data isolation, AI SQL safety first |
| Pairwise | many optional params | recurring frequency × dayOfMonth/dayOfWeek/monthOfYear |

## 3. gastosai test context

- **Stack** (native dev): DB `:5433` (Docker) · backend `:8080` (`mvnw.cmd spring-boot:run`) · frontend `:5173` (`npm run dev`).
- **Demo login**: `demo@gastosai.dev` / `demo123` (seeded: expenses, budgets, recurring, goals, PREMIUM sub). Get a JWT: `POST /auth/login` → `token`.
- **Import fixtures**: `qa-csv/import-accepted.csv` (6 import), `import-partial.csv` (2 import / 3 skip / 1 error), `import-unaccepted.csv` (0 import).
- **Suites**: backend `cd backend; mvnw.cmd test` · frontend `cd frontend; npm run lint; npm run build; npm run test:run`.
- **Isolation oracle**: register a second user → must see **zero** of the demo user's data.
- **Money**: PHP `₱`, 2-decimal display; aggregation must match the current wall-clock month.

## 4. Execution boundary (be honest about it)

- **Headless (the agent can do):** HTTP against `:8080` via `curl` (auth + CRUD + status codes + body asserts); run `mvnw`/`npm` suites; read frontend code to trace UI logic + event flow (`gastosai:*-changed`).
- **Browser-only (emit a human checklist):** rendering, clicks, modals, charts, responsiveness. The agent cannot click a browser natively — produce a **numbered manual checklist** (step → expected) for the human. (Real browser automation is tracked backlog item B9 — Playwright/browser MCP.)

## 5. Severity rubric (match the reviewer convention)

🔴 critical — data loss/corruption, security/isolation breach, broken core flow · 🟠 major — feature wrong/unusable, bad money math · 🟡 minor — edge-case glitch, confusing copy · 🔵 polish — cosmetic.

## 6. Definition of done / quality gates

- Scenarios cover happy + boundary + negative + isolation for the feature.
- No open 🔴/🟠 defects.
- User-owned data is scoped to the authenticated user (verified, not assumed).
- Backend + frontend suites green; new behavior has a regression test (filed to dev agents if missing).
- Money formatted/aggregated correctly; no raw ISO dates shown to users.
