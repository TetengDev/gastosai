# Copilot Instructions — gastosai

GitHub Copilot guidance for the gastosai repository. Read `AGENTS.md` first — this file adds Copilot-specific conventions on top of it. For deeper detail on any topic, read the relevant file under `ai/skills/`.

---

## Project snapshot

- **Backend**: Spring Boot 4 / Java 25, Maven wrapper (`mvnw.cmd` on Windows)
- **Frontend**: React 19 + TypeScript + Vite + Tailwind CSS v4 + Recharts
- **Database**: PostgreSQL 17 (Docker local on port 5433; Supabase in prod)
- **AI providers**: OpenAI or Anthropic Claude, toggled by `GASTOS_AI_PROVIDER`
- **Currency**: Philippine peso (₱); all money is `BigDecimal`
- **Repo root**: `D:\Lester\Practical\PersonalProjects\Others\gastosai`

---

## Shell & environment

**Always use PowerShell** — this machine is Windows 11. Never suggest bash, sh, or WSL paths (`/mnt/d/...`).

Default ports — never accept a fallback silently:

| Service | Port |
|---|---|
| Backend (Spring Boot) | 8080 |
| Frontend (Vite) | 5173 |
| Database (PostgreSQL / Docker) | 5433 |

GitHub CLI: `C:\Program Files\GitHub CLI\gh.exe`. Load token before any gh command:

```powershell
$env:GH_TOKEN = (Get-Content ".env" | Select-String "GITHUB_TOKEN=(.+)" | ForEach-Object { $_.Matches[0].Groups[1].Value })
```

---

## Commands

### Database (Docker — always required)

```powershell
docker compose up -d           # start Postgres 17 on :5433 (data preserved)
docker compose down            # stop (data preserved)
docker compose down -v         # stop + wipe volume (full DB reset)
```

### Backend (run from `backend/`)

```powershell
mvnw.cmd spring-boot:run       # start on :8080
mvnw.cmd test                  # all tests (H2 in-memory)
mvnw.cmd test -Dtest=ExpenseApiIntegrationTest   # single class
mvnw.cmd compile               # compile-only check
mvnw.cmd verify                # compile + test + JaCoCo coverage report
mvnw.cmd clean install -DskipTests
```

### Frontend (run from `frontend/`)

```powershell
npm run dev        # Vite dev server on :5173
npm run build
npm run lint
npm run test:coverage
```

### Dev launcher (from repo root)

```powershell
.\scripts\start.ps1              # interactive menu
.\scripts\start.ps1 -Mode all   # DB + backend + frontend
.\scripts\teardown.ps1 -All -Force
```

### Version bump (from repo root)

```powershell
.\scripts\bump-version.ps1                    # dry-run: show recommended bump
.\scripts\bump-version.ps1 -Bump MINOR -Apply # apply to pom.xml, package.json, CHANGELOG.md
.\scripts\bump-version.ps1 -CutRelease        # bump + create release/x.y.z branch + tag + push
```

---

## Git workflow

### Branches

| Pattern | Purpose |
|---|---|
| `feat/<name>` | Feature development |
| `fix/<name>` | Bug fixes |
| `release/x.y.z` | Release branches — CI requires this to merge to master |
| `hotfix/<name>` | Emergency fixes; branch from `release/x.y.z`, cherry-pick to master |

**PRs to master must come from `release/*` branches** — the CI `validate-release-branch` job enforces this.

Never commit non-trivial changes directly to `master`.

### Commit style

Format: `type(scope): description` (conventional commits)

- No `Co-Authored-By` or AI attribution lines in commit messages
- Atomic commits — one concern per commit
- No secrets in staged files (`.env`, API keys)

### Semantic versioning

| Commit type | Bump |
|---|---|
| `fix:`, `perf:` | PATCH |
| `feat:` | MINOR |
| `feat!:` or `BREAKING CHANGE:` footer | MAJOR |
| `docs:`, `style:`, `refactor:`, `test:`, `chore:` | None |

Both `backend/pom.xml` and `frontend/package.json` must be bumped to the **same** version. Bump once per PR (not once per commit) based on the highest-impact commit since the last release.

---

## Pre-PR checklist

Before opening any PR, verify all of these pass:

1. On a feature branch — not master
2. `mvnw.cmd compile` — zero errors
3. `mvnw.cmd test` — all green
4. New features: unit test for service logic + integration test for happy path
5. Bug fixes: regression test that fails before the fix
6. No secrets in staged files
7. `mvnw.cmd verify` — JaCoCo coverage report at `target/site/jacoco/index.html`; if < 70% note in PR
8. `npm run lint` — zero warnings
9. `npm run build` — clean compile
10. `npm run test:coverage` — if < 70% note in PR
11. Version bumped in both `backend/pom.xml` and `frontend/package.json`
12. `CHANGELOG.md` updated — move `[Unreleased]` into new `[x.y.z]` section

See `ai/skills/git-best-practices.md` and `ai/skills/shared/pre-pr-checklist.md` for full detail.

---

## Code conventions

### Java / Spring Boot

- Prefer Java **records** for DTOs (`ExpenseRequest`, `ExpenseResponse`, etc.)
- Use **Lombok** (`@Builder`, `@Getter`, `@Setter`, `@RequiredArgsConstructor`) on entities and services
- Use `@Transactional` on service write methods; `@Transactional(readOnly = true)` on reads
- Use `BigDecimal` for all monetary fields — never `double` or `float`
- Use `LocalDateTime` for expense date fields
- Validation annotations go on DTO record components (`@NotBlank`, `@NotNull`, `@DecimalMin`, etc.)
- Do **not** annotate DTO fields with `@JsonIgnore` — the frontend needs all IDs
- Use `RestClient` (Spring 6+) for outbound HTTP, not `RestTemplate`
- `CategoryService.getOrCreateByName()` is the correct path for category auto-creation — never save categories directly elsewhere

### Controller → Service → Repository

```
@RestController  →  @Service  →  JpaRepository
```

- Controllers: thin — validate input, call service, return DTO
- Services: own `@Transactional` and business logic
- Repositories: JPQL (not native SQL) for queries

### AI query path — safety critical

```
AiController → AiQueryService → SqlGenerator → SqlGuard → JdbcTemplate
```

- `SqlGuard` must run before any AI SQL executes — never skip it
- `SqlGenerator` implementations must instruct the model to return **only** a bare `SELECT`
- `SqlGuard` blocks: non-SELECT statements, missing `FROM expenses`, multi-statements (`;`), system catalogs (`pg_`, `information_schema`)
- Never suggest changes that loosen `SqlGuard` validation rules
- See `ai/skills/ai-sql-safety.md` for the full rule set

### Bootstrap / seeding

- `CategoryDataLoader` seeds 13 predefined categories on **every** startup (`@Order(-1)`)
- `AppDataLoader` seeds sample expenses only when `gastos.seed-sample-data=true` and the table is empty
- Never hardcode category names outside `CategoryDataLoader.PREDEFINED_CATEGORIES`

### TypeScript / React

- All API types live in `frontend/src/api/types.ts` — add new interfaces there
- API calls go through files in `frontend/src/api/` using the shared Axios instance (`api/client.ts`)
- Use `useCallback` for functions passed to `useEffect` to avoid re-renders
- Prefer `async/await` over `.then()` chains in event handlers
- Tailwind v4: use `@import "tailwindcss"` in CSS — no `tailwind.config.js`
- No `any` types; use `unknown` for caught errors and narrow with type guards

### Comments and docs

- No comments by default — only add when the WHY is non-obvious
- No multi-paragraph docstrings or multi-line comment blocks
- No unused imports — run `mvnw.cmd compile` after every backend change

---

## Security rules

- **CORS**: driven by `cors.allowed-origins` env var (`CORS_ALLOWED_ORIGINS` in production) — never hardcode origins
- **Actuator**: only `/actuator/info` is public — do not expose wildcard `/actuator/**`
- **JWT secret**: warn at startup if using the dev default; set `JWT_SECRET` in production
- **Passwords**: `@Size(max = 72)` on all password fields (BCrypt 72-char limit)
- **File uploads**: validate content-type against allowlist before processing
- **No secrets committed** — `.env`, API keys, tokens must never appear in git history

---

## What Copilot should NOT suggest

- Bypassing or removing `SqlGuard` validation
- Returning JPA entity objects directly from controllers
- Using `@JsonIgnore` on DTO ID fields
- Using `RestTemplate` (use `RestClient`)
- Using `double` or `float` for monetary values
- Hardcoding CORS origins or wildcard actuator exposure
- Committing `.env` files or API keys
- Saving categories directly without `CategoryService.getOrCreateByName()`

---

## Key skill documents

Read these for deeper context on any topic:

| Topic | File |
|---|---|
| Domain model + DTO contracts | `ai/skills/project-context.md` |
| Feature build pattern | `ai/skills/feature-builder.md` |
| Java/Spring conventions | `ai/skills/java-spring-standards.md` |
| Testing strategy | `ai/skills/testing.md` |
| AI SQL safety | `ai/skills/ai-sql-safety.md` |
| Git rules | `ai/skills/git-best-practices.md` |
| Branching + versioning | `ai/skills/git-branching-release-strategy.md` |
| Pre-PR checklist | `ai/skills/shared/pre-pr-checklist.md` |
| Security audit | `ai/skills/security-audit.md` |
| Deployment | `ai/skills/deployment.md` |
| Backend review | `ai/skills/backend-review.md` |
| Environment / shell | `ai/skills/environment.md` |
