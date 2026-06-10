# CLAUDE.md

Claude Code guidance for the gastosai repository. Read `AGENTS.md` first — this file adds Claude-specific detail on top of it.

---

## Commands

### Database (DB-only — default dev workflow)
```bash
docker compose up -d         # start Postgres 17 on :5433 (data in named volume)
docker compose down          # stop (data preserved)
docker compose down -v       # stop + wipe volume (full DB reset)
```

### Full stack in Docker
```bash
docker compose --profile app up -d        # build + start DB, backend, frontend
docker compose --profile app up -d --build  # force rebuild images
docker compose --profile app down         # stop all (data preserved)
docker compose --profile app down -v      # stop all + wipe DB volume

# Pass a custom backend URL when building (defaults to http://localhost:8080)
VITE_API_URL=http://api.example.com docker compose --profile app up -d --build
```

### Backend (run from `backend/`)
```bash
mvnw.cmd spring-boot:run              # Windows
./mvnw spring-boot:run                # Unix
mvnw.cmd test                         # all tests (H2 in-memory)
mvnw.cmd test -Dtest=ExpenseApiIntegrationTest     # single class
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

### Version bump (from repo root)
```powershell
.\scripts\bump-version.ps1                     # dry-run: show recommended bump + release prep table
.\scripts\bump-version.ps1 -Bump MINOR -Apply  # apply bump to pom.xml, package.json, CHANGELOG.md
.\scripts\bump-version.ps1 -CutRelease         # bump + create release/x.y.z branch + annotated tag + push
```

---

## Shell & runtime defaults

These apply in every session without exception — do not wait to be reminded:

- **Shell tool**: Always use the **PowerShell tool** for every command. Never use the Bash tool — this machine is Windows 11 and Bash uses WSL paths (`/mnt/d/...`) that fail here.
- **Default run mode**: Run **natively** to save memory — Docker for the DB only (`docker compose up -d`), backend via `mvnw.cmd spring-boot:run`, frontend via `npm run dev`. Use the full Docker stack (`docker compose --profile app up -d --build`) only when the user explicitly asks for it. Always check if ports `:8080` / `:5173` / `:5433` are already occupied before starting; tear down existing processes first if they are.
- **Default ports**: backend `:8080` · frontend `:5173` · database `:5433`. Never silently accept a fallback port.
- **GitHub CLI**: Installed at `C:\Program Files\GitHub CLI\gh.exe`. The `GITHUB_TOKEN` is in the repo root `.env`. Load it before any `gh` command:
  ```powershell
  $env:GH_TOKEN = (Get-Content ".env" | Select-String "GITHUB_TOKEN=(.+)" | ForEach-Object { $_.Matches[0].Groups[1].Value })
  ```

---

## Environment

**Repo root `.env`** (not committed — contains secrets):

| Variable | Description |
|---|---|
| `GITHUB_TOKEN` | Personal access token for `gh` CLI — loaded into `$env:GH_TOKEN` before gh commands |

**`backend/.env`** (copy from `backend/.env.example`):

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

**`frontend/.env.local`**:
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

References: [SemVer 2.0.0](https://semver.org/) · [Conventional Commits 1.0.0](https://www.conventionalcommits.org/en/v1.0.0/) · [Keep a Changelog 1.1.0](https://keepachangelog.com/en/1.1.0/) · [semantic-release](https://github.com/semantic-release/semantic-release)

Both `backend/pom.xml` and `frontend/package.json` must be bumped **together** to the same version.

**Version bump is a pre-PR concern, not a per-commit concern.** Commit freely on a feature branch. Before opening a PR, bump once based on the highest-impact change since the last release tag.

### Version format

```
MAJOR.MINOR.PATCH
Pre-release:    1.2.0-alpha.1 / 1.2.0-beta.1 / 1.2.0-rc.1
Build metadata: 1.2.0+build.sha  (informational only; ignored by precedence rules)
```

### Commit type → version bump

| Commit type | Bump |
|---|---|
| `fix:`, `perf:` | PATCH |
| `feat:` | MINOR |
| Any type with `!` (e.g. `feat!:`, `fix!:`) or `BREAKING CHANGE:` footer | MAJOR |
| `docs:`, `style:`, `refactor:`, `test:`, `chore:`, `build:`, `ci:`, `revert:` | None |

Notes:
- `perf:` → PATCH unless the change is behaviorally incompatible (then MAJOR).
- `refactor:` → no bump unless it changes user-facing behavior.
- If uncertain whether a change is breaking, **explain the risk and ask before choosing the version.**

### Breaking change defined

Breaking = removes or renames an existing endpoint or field, changes request/response shape or HTTP status codes, renames a public env var or CLI flag, drops support for a runtime version. Adding new endpoints, fields, env vars, or DB tables is `feat:`, not a breaking change.

### Release decision process

Before bumping, inspect commits since the last release tag (`git log <last-tag>..HEAD --oneline`):

1. Any breaking change → MAJOR
2. Else any `feat:` → MINOR
3. Else any `fix:` / `perf:` / security patch → PATCH
4. Else no bump

Never downgrade. Never skip versions. Do not call a breaking change a patch or minor release.

### Release preparation output

When preparing a release, produce this output and **wait for explicit approval** before committing, tagging, pushing, or publishing. Do not push tags unless explicitly asked.

```
- Current version:
- Latest tag:
- Recommended bump:
- Reason:
- Proposed next version:
- Changelog entry:
- Files to change:
- Commands to run:
```

### Applying the bump

1. Update `backend/pom.xml` `<version>` and `frontend/package.json` `"version"` to the same new value.
2. Update `CHANGELOG.md` — move `[Unreleased]` entries into a new `## [x.y.z] - YYYY-MM-DD` section.
3. Stage and commit before opening the PR.

After merge to master, tag with explicit approval:

```powershell
git tag -a v0.10.0 -m "Release v0.10.0"
git push origin v0.10.0
```

### One-time hook setup

Run once per clone to activate the `commit-msg` hook (format linter only — no version enforcement):

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

## What to check before opening a PR

9. `mvnw.cmd verify` — tests pass; JaCoCo report generated at `target/site/jacoco/index.html`; if line coverage < 70%, note in PR body and add follow-up task (does not block build)
10. `npm run test:coverage` — tests pass; if line coverage < 70%, note in PR body and add follow-up task (does not block build)
11. Version bumped in `backend/pom.xml` and `frontend/package.json` (see bump table above)
12. `CHANGELOG.md` updated — move `[Unreleased]` notes into the new version section

---

## Agents

Sub-agent definitions live in `.claude/agents/`. Use them when implementing features that touch both layers simultaneously. See `ai/skills/agents.md` for the full parallel workflow.

| Agent | Role |
|---|---|
| `full-stack-planner` | Read-only; decomposes a feature into backend + frontend tasks with agreed DTO contracts |
| `backend-dev` | Implements Spring Boot changes; verifies with compile + tests before finishing |
| `frontend-dev` | Implements React/TypeScript changes; verifies with lint + build before finishing |
| `pre-pr` | Runs the full quality gate before any PR (lint, build, tests, runtime execution, version) |
| `prompt-compressor` | Compresses verbose agent prompts to minimum tokens before spawning sub-agents |
| `feature-prioritizer` | Scores feature candidates using ICE + revenue multiplier; returns ranked table with top-pick recommendation |
| `tech-workflow` | Engineering process advisor — branching, PR sizing, review gates, sprint discipline, incident response |

Workflow: `full-stack-planner` → **`prompt-compressor`** (compress each agent prompt) → `backend-dev` + `frontend-dev` (parallel) → `pre-pr`

Token-efficiency rules: `ai/skills/token-optimization.md`

---

## Deployment targets

| Layer | Service | Notes |
|---|---|---|
| Backend | Koyeb | 512 MB free tier; `-Xmx320m -XX:+UseSerialGC` |
| Frontend | Vercel | Set `VITE_API_URL` to Koyeb HTTPS URL |
| Database | Supabase | Free PostgreSQL; pauses after ~1 week idle |

See `ai/skills/deployment.md` for the full deployment walkthrough.
