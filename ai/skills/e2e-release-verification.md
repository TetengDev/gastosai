# Skill: E2E Release Verification (+ Telegram reporting)

The full pre-merge verification battery for a user-facing gastosai release: QA, security,
real-browser end-to-end testing with screenshots + screen recording, and delivery of the
evidence to Telegram. Opt-in / local — **not** wired into the blocking CI.

---

## When to run
Before merging a user-facing feature/release to master (after `pre-pr`, alongside or after
`qa-engineer`). Especially when the change has UI behavior worth capturing.

## Preconditions
- Stack running locally: `docker compose up -d` (DB :5433), backend `mvnw.cmd spring-boot:run` (:8080),
  frontend `npm run dev` (:5173), with the demo user seeded (`demo@gastosai.dev` / `demo123`).
- Playwright installed in `frontend/`: `npm install -D @playwright/test` then `npx playwright install chromium`.

## The battery (run in this order)
1. **QA** — `qa-engineer` agent: scenario matrix (happy · boundary · negative · security/isolation · regression) + curl execution + manual checklist.
2. **Security / pentest** — `security-auditor` agent: live exploitation attempts on the new surface (IDOR, param tampering, authn, injection, info-leak). Never weaken SqlGuard.
3. **Edge-case unit/integration tests** — add the boundary/negative cases the agents surface to the backend suite; keep the suite green.
4. **E2E (real browser)** — `qa-e2e-reporter` agent (or `npm run e2e`): drives the app, asserts the user-visible flows, and auto-produces a **video** (`.webm`) + **screenshots** per test.
5. **Capture + Telegram** — bundle screenshots + a representative video + the report and send via `scripts/notify-telegram.ps1`.

## Playwright harness
- Config: `frontend/playwright.config.ts` (`testDir: e2e`, `video: "on"`, `screenshot: "on"`, baseURL `http://localhost:5173`, override via `E2E_BASE_URL`).
- Specs: `frontend/e2e/*.spec.ts`. Explicit screenshots saved to `frontend/e2e/artifacts/`; videos to `frontend/test-results/`.
- Scripts: `npm run e2e` (run), `npm run e2e:report` (open HTML report).
- Artifacts are runtime-only and **gitignored** — never commit videos/screenshots.

## Telegram delivery
- Script: `scripts/notify-telegram.ps1 -Title <t> -SummaryText <md> -Files <paths...>`.
- Env (repo-root `.env`, gitignored): `TELEGRAM_BOT_TOKEN`, `TELEGRAM_CHAT_ID`.
- Create the bot via @BotFather; get the chat id by messaging the bot then calling `getUpdates`, or via @userinfobot.
- Uses the Bot API: a `sendMessage` summary, then per-file `sendPhoto` (png/jpg) / `sendVideo` (webm/mp4, with `sendDocument` fallback) / `sendDocument`. Multipart via `curl.exe` (works on Windows PowerShell 5.1). Exits 2 (non-fatal) if creds are absent.

## CI note
Keep Playwright out of the blocking workflow (browser download is heavy). This battery is a
local/opt-in pre-merge gate, not an automated CI job.
