# gastosai — Roadmap Progress Tracker

Internal tracking file. Do not commit.

---

## Status legend

| Symbol | Meaning |
|--------|---------|
| ✅ | Complete / confirmed by user |
| 🟡 | Partial — exists but missing key parts |
| 🔲 | Not started |
| 🚧 | In progress (current session) |
| 🧪 | Implemented — awaiting user acceptance test |

## Merge gate (required for every slice)

1. ✅ Automated — compile + all tests green
2. ✅ App running — Docker stack started so user can test
3. ✅ User acceptance — user confirms feature works as expected
4. ➡ Only then: open PR / mark slice ✅ Done

---

## Feature 1: Smart Expense Logging

**Status:** 🟡 Partial

### What exists
- ✅ Manual expense CRUD (`POST/GET/PUT/DELETE /expenses`)
- ✅ CSV import (`POST /expenses/import`)
- ✅ Amount validation, BigDecimal, category auto-create
- ✅ Natural-language text parse endpoint (`POST /expenses/parse`)
- ✅ Expense draft response before saving (parse-and-preview flow)
- ✅ ChatWidget wired to parse endpoint with draft card UI
- ✅ Cross-component refresh via `gastosai:expense-created` event

### What is missing
- 🔲 Source tracking (`MANUAL`, `TEXT`, `VOICE`, `RECEIPT`, `IMPORT`, `AI`) on the `Expense` entity
- 🔲 Parse-and-save shortcut endpoint

### Sessions
| Date | Slice | Branch | Status |
|------|-------|--------|--------|
| 2026-06-10 | `POST /expenses/parse` — NL text → draft | `feat/expense-text-parse` | ✅ Merged |

---

## Feature 2: Smart Categorization and Category Rules

**Status:** 🟡 Partial

### What exists
- ✅ Category name trimming and uniqueness check
- ✅ Duplicate prevention on create and rename
- ✅ 13 predefined system categories seeded by `CategoryDataLoader`
- ✅ Delete with fallback-to-Uncategorized reassignment
- ✅ Case-insensitive matching (`"food"` and `"Food"` treated as same)

### What is missing
- 🔲 Category aliases
- 🔲 Category suggestion endpoint
- 🔲 Merchant-to-category rules

---

## Feature 3: Budgets and Safe-to-Spend Dashboard

**Status:** 🔲 Not started

### What exists
- (nothing)

### What is missing
- 🔲 `Budget` entity (category, month, amount limit)
- 🔲 Budget CRUD endpoints
- 🔲 Budget summary endpoint (`safeToSpend`, `dailyAllowance`, status)
- 🔲 Status enum: `ON_TRACK`, `WARNING`, `OVER_BUDGET`
- 🔲 Frontend budget page

---

## Feature 4: Reports and Interactive Analytics

**Status:** 🟡 Partial

### What exists
- ✅ Monthly report (`GET /expenses/report/monthly`) — year-month + total
- ✅ Category breakdown (`GET /expenses/report/category`) — category + total
- ✅ Frontend dashboard with donut chart + category breakdown

### What is missing
- 🔲 Daily spending trend endpoint
- 🔲 Top vendors/merchants
- 🔲 Month-over-month comparison
- 🔲 Highest single transactions
- 🔲 Date-range filtering on reports

---

## Feature 5: Receipt Scanning and Receipt Vault

**Status:** 🟡 Partial

### What exists
- ✅ `POST /ai/vision` — image upload → AI text description (OpenAI / Claude)
- ✅ `VisionService` — base64 image → unstructured text response

### What is missing
- 🔲 Structured receipt extraction (returns `ParsedExpenseResult` draft, not plain text)
- 🔲 Receipt → expense confirm flow
- 🔲 `Receipt` entity / vault storage
- 🔲 Receipt status (`PENDING`, `CONFIRMED`, `REJECTED`)

---

## Feature 6: Recurring Bills and Subscriptions

**Status:** 🔲 Not started

### What exists
- (nothing)

### What is missing
- 🔲 `RecurringExpense` entity
- 🔲 Recurring CRUD endpoints
- 🔲 Upcoming bills endpoint
- 🔲 Recurrence detection suggestions from expense history

---

## Feature 7: AI Financial Assistant

**Status:** 🟡 Partial

### What exists
- ✅ `POST /ai/query` — natural-language → SQL → results + AI summary
- ✅ SqlGuard safety boundary (blocks non-SELECT, enforces `FROM expenses`)
- ✅ Three summary modes: `plain`, `professional`, `genz`
- ✅ OpenAI and Claude providers switchable via env var

### What is missing
- 🔲 Predefined insight endpoints (top category, month summary, anomaly)
- 🔲 AI recommendations based on report data (not raw SQL)
- 🔲 AI anomaly explanations

---

## Feature 8: Goals and Savings Planner

**Status:** 🔲 Not started

### What exists
- (nothing)

### What is missing
- 🔲 `SavingsGoal` entity
- 🔲 Goal CRUD endpoints
- 🔲 Goal progress calculation
- 🔲 Status enum: `ON_TRACK`, `BEHIND`, `COMPLETED`, `PAUSED`

---

## Feature 9: Alerts, Nudges, and Spending Anomaly Detection

**Status:** 🔲 Not started

### What exists
- (nothing)

### What is missing
- 🔲 `Alert` entity
- 🔲 Alert generation (budget warnings, overspending, spending spikes)
- 🔲 Alert read/unread state
- 🔲 Idempotent alert creation

---

## Feature 10: Export, Freelancer, and Business Mode

**Status:** 🟡 Partial

### What exists
- ✅ CSV import (`POST /expenses/import`)

### What is missing
- 🔲 CSV export (`GET /expenses/export`)
- 🔲 Business fields on `Expense`: `expenseType` (PERSONAL/BUSINESS), `projectTag`, `reimbursable`
- 🔲 Project/client tagging
- 🔲 PDF export

---

*Last updated: 2026-06-10*
