# CLAUDE.md

Claude Code guidance for the gastosai repository. Read `AGENTS.md` first — this file adds Claude-specific detail on top of it.

---

## Commands

### Database
```bash
docker compose up -d      # start Postgres 17 on host port 5433
docker compose down       # stop (data preserved)
docker compose down -v    # stop + wipe volume
```

### Backend (run from `backend/`)
```bash
mvnw.cmd spring-boot:run              # Windows
./mvnw spring-boot:run                # Unix
mvnw.cmd test                         # all tests (H2 in-memory)
mvnw.cmd test -Dtest=ExpenseApiIT     # single class
mvnw.cmd clean install -DskipTests
```

### Frontend (run from `frontend/`)
```bash
npm run dev      # Vite dev server on :5173
npm run build
npm run lint
```

### Dev launcher (from repo root)
```powershell
.\scripts\start.ps1              # interactive menu
.\scripts\start.ps1 -Mode all   # start DB + backend + frontend
.\scripts\teardown.ps1           # interactive teardown
.\scripts\teardown.ps1 -All -Force
```

---

## Environment

`backend/.env` (copy from `backend/.env.example`):

| Variable | Description |
|---|---|
| `DB_URL` | `jdbc:postgresql://localhost:5433/gastos` |
| `DB_USERNAME` | `postgres` |
| `DB_PASSWORD` | `dev` |
| `OPENAI_API_KEY` | Required if using OpenAI provider |
| `OPENAI_MODEL` | e.g. `gpt-4o-mini` |
| `CLAUDE_API_KEY` | Required if using Claude provider |
| `CLAUDE_MODEL` | e.g. `claude-3-5-sonnet-20241022` |
| `GASTOS_AI_PROVIDER` | `openai` (default) or `claude` |
| `GASTOS_SEED_SAMPLE_DATA` | `true` seeds 15 sample expenses on empty DB |

`frontend/.env.local`:
```
VITE_API_URL=http://localhost:8080
```

---

## Architecture detail

See `ai/skills/project-context.md` for the full domain model and data flow.

### AI safety — read before touching the AI path

`SqlGuard` (`ai/SqlGuard.java`) is the security boundary:

- Blocks all non-SELECT statements (INSERT, UPDATE, DELETE, DROP, TRUNCATE, …)
- Requires the query to include `FROM expenses` (or alias)
- Rejects multi-statement input (`;` separator check)
- Blocks system catalog access (`pg_`, `information_schema`)

**Never bypass or weaken SqlGuard.** See `ai/skills/ai-sql-safety.md` for the full rule set.

---

## Coding conventions Claude should follow

- **No comments by default.** Only add a comment when the WHY is non-obvious.
- **No unused imports.** Run `mvnw.cmd compile` after every backend change.
- **Records for DTOs.** Prefer Java records over classes for request/response types.
- **@Transactional on service methods.** Read-only queries get `@Transactional(readOnly = true)`.
- **BigDecimal for money.** Scale to 2 for display (`setScale(2, RoundingMode.HALF_UP)`), store at precision 19 scale 4.
- **Category auto-creation.** `CategoryService.getOrCreateByName()` is the correct path; do not save categories directly in other services.
- **DTOs only through controllers.** Never return entity objects from controller methods.
- Frontend TypeScript: no `any`, prefer `unknown` for caught errors.

---

## Semantic versioning — required

Both `backend/pom.xml` and `frontend/package.json` must be bumped together to the same version. A `commit-msg` hook enforces this automatically (see setup below).

**The bump is only required when app code changes** (`backend/src/`, `frontend/src/`, `backend/pom.xml`, `frontend/package.json`). Commits that only touch docs, skills, CI config, or git hooks do not need a bump even if they use `feat:` or `fix:`.

| Commit type + app code changed | Bump |
|---|---|
| `fix:`, `perf:` | PATCH — e.g. `0.3.1 → 0.3.2` |
| `feat:` | MINOR — e.g. `0.3.1 → 0.4.0` |
| `feat!:` / `fix!:` / `BREAKING CHANGE:` | MINOR while pre-1.0, MAJOR at `1.0.0+` |
| `docs:`, `test:`, `chore:`, `refactor:`, `ci:` | No bump required |

When bumping, also update `CHANGELOG.md` — move relevant notes from `[Unreleased]` into the new version section. Then tag:

```bash
git tag -a v0.4.0 -m "Release v0.4.0"
git push origin v0.4.0
```

### One-time hook setup

Run once per clone to activate the `commit-msg` hook:

```bash
git config core.hooksPath .githooks
```

---

## What to check before committing

1. Working on a feature branch — never commit non-trivial changes directly to `master`
2. `mvnw.cmd compile` — zero errors
3. `mvnw.cmd test` — all green
4. New features include a unit test for service logic + an integration test for the happy path
5. Bug fixes include a regression test that fails before the fix
6. No secrets in staged files (`.env`, API keys)
7. Commits are atomic and scoped to one concern per commit
8. No `Co-Authored-By` or AI attribution lines in commit messages
9. Version bumped in `backend/pom.xml` and `frontend/package.json` if commit type requires it (see above)
10. `CHANGELOG.md` updated — move `[Unreleased]` notes into the new version section when releasing

---

## Deployment targets

| Layer | Service | Notes |
|---|---|---|
| Backend | Koyeb | 512 MB free tier; `-Xmx320m -XX:+UseSerialGC` |
| Frontend | Vercel | Set `VITE_API_URL` to Koyeb HTTPS URL |
| Database | Supabase | Free PostgreSQL; pauses after ~1 week idle |

See `ai/skills/deployment.md` for the full deployment walkthrough.
