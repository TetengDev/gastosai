# Skill: Pre-PR Quality Checklist (Shared)

Run this checklist **before** pushing a branch or creating a pull request. Every item marked **Blocker** must pass before the PR is opened.

---

## 1. Static analysis

### Frontend (TypeScript / React)

```bash
# From frontend/
npm run lint        # ESLint — must pass with 0 errors
npm run build       # tsc + bundler — must compile clean
```

Common lint rules to watch for:
- `react-hooks/rules-of-hooks` — hooks called conditionally or outside components
- `react-hooks/exhaustive-deps` — missing effect dependencies
- `react-hooks/set-state-in-effect` — calling `setState` synchronously in a `useEffect` body; derive initial state in `useState` instead
- `@typescript-eslint/no-explicit-any` — use `unknown` for caught errors
- `@typescript-eslint/no-unused-vars` — remove dead variables

**Blocker:** Any ESLint error.

### Backend (Java / Spring Boot)

```bash
# From backend/ — Windows
.\mvnw.cmd compile

# Unix
./mvnw compile
```

**Blocker:** Any compilation error or unused import.

---

## 2. Tests and coverage

### Backend

```powershell
# Windows — runs tests + JaCoCo coverage report; fails build if below threshold
.\mvnw.cmd verify

# Unix
./mvnw verify
```

### Frontend

```bash
npm run test:coverage   # vitest with c8 — fails if below threshold
```

**Blocker:** Any failing test. All tests must be green before opening a PR.

**Warning (not a build blocker):** If line coverage is below 70%, note it in the PR description and add a follow-up task to improve coverage. New features and bug fixes must include tests; coverage below 70% signals missing tests that must be addressed before or shortly after merge.

New features require:
- Unit test for service/business logic (mocked dependencies)
- Integration test for the HTTP happy path

Bug fixes require:
- A regression test that fails before the fix and passes after

---

## 3. No secrets

Before staging, verify nothing sensitive is included:

```bash
git diff --staged
git status
```

Never commit: `.env` files, API keys, tokens, passwords, local machine paths, IDE project files.

**Blocker:** Any secret or credential in staged files.

---

## 4. Version bump

**Blocker:** Version must be bumped before the PR is opened if any app code changed on the branch.

Version bumps happen **once per PR**, not once per commit. Determine the required bump by scanning all commits on this branch since `master`:

```powershell
# List all commit types on this branch vs master
git log master..HEAD --oneline
```

| Highest commit type on branch (with app code changes) | Bump |
|---|---|
| `fix:`, `perf:` | PATCH |
| `feat:` | MINOR |
| `feat!:` / `BREAKING CHANGE:` | MAJOR (MINOR if pre-1.0) |
| `docs:`, `test:`, `chore:`, `refactor:`, `ci:` only | None |

"App code" = `backend/src/`, `frontend/src/`, `backend/pom.xml`, `frontend/package.json`. Docs, CI config, and skills changes do not trigger a bump.

When a bump is required:
1. Update `backend/pom.xml` `<version>` and `frontend/package.json` `"version"` to the same new value
2. Update `CHANGELOG.md` — move `[Unreleased]` entries into a new `## [x.y.z] - YYYY-MM-DD` section
3. Stage and commit these changes before creating the PR

**After merge to master:** tag the release commit:
```powershell
git tag -a v<version> -m "Release v<version>"
git push origin v<version>
```

---

## 5. CHANGELOG

When a version bump is made, move the relevant `[Unreleased]` notes into a new versioned section in `CHANGELOG.md` with today's date.

---

## 6. Branch and diff sanity

```bash
git branch --show-current          # must be a feature branch, not main/master
git diff main...HEAD --stat        # confirm scope matches the task
git log main..HEAD --oneline       # review commit history
```

---

## 7. Infrastructure and breaking changes

Infrastructure changes look harmless but can silently break teammates' local setups or CI. Before opening a PR that touches `docker-compose.yaml`, `Dockerfile`, port bindings, or CI/CD config:

### Is this a breaking change?

A change is **breaking for existing local environments** if it:
- Adds, renames, or removes a **named volume** — existing data in the old volume is not automatically migrated
- Changes a **container or service name** — scripts and `docker exec` commands using the old name will fail
- Adds or removes **compose profiles** — commands without the profile flag won't start new services
- Changes a **default port** — all references in `.env.example`, skills, scripts, and docs must be updated together
- Changes the **CI workflow** in a way that affects test isolation or secret availability

### Required for any infrastructure PR

1. **Migration note in the PR body** — what does an existing developer need to do after pulling?
   - *Example:* "Run `docker compose down -v && docker compose up -d` — the named volume replaces the old anonymous volume; schema re-creates automatically via `create-drop`."
2. **Update all references** — CLAUDE.md, skills, scripts, `.env.example`, README if applicable.
3. **Verify CI is not affected** — check `.github/workflows/` to confirm CI does not rely on anything you changed.
4. **Smoke test the migration path** — pull on a clean checkout and run the documented migration steps.

**Blocker:** Any infrastructure change with no migration note and no reference audit.

---

## 8. Production-readiness and rollback safety

Before opening a PR for any change that touches data, APIs, or deployment config:

### Database changes
- Every schema change must be **reversible**. If using Flyway, provide a `V<n>__description.sql` migration and ensure a rollback path exists.
- Never add a `NOT NULL` column without a default or a two-step migration (add nullable → backfill → add constraint).
- Test the migration against the current schema before opening the PR.

### API contract changes
- Prefer **additive changes** (new fields, new endpoints) over breaking ones.
- If a breaking change is unavoidable, version the endpoint (`/v2/...`) or provide a deprecation window.
- Confirm existing clients (frontend, tests) are updated before merging.

### Risky or large changes
- Break large changes into a sequence of small, independently-releasable commits. Each commit should leave the app in a working state.
- If a change is too risky to ship immediately, wrap it in a feature flag rather than merging broken code.
- The smaller the diff, the easier the rollback. Prefer multiple focused PRs over one large one.

### Rollback plan
Before merging, be able to answer: *"If this goes wrong in production, how do I revert it in under 5 minutes?"*

Acceptable answers:
- `git revert <merge-sha>` produces a clean revert → re-deploy.
- Previous version tag (`v0.5.0`) is deployable → roll back to it.

If neither answer applies, the change is not rollback-safe — reconsider the approach.

---

## 8. Mandatory execution testing — no exceptions

**Every change must be actually run before a PR is opened.** Passing type-checks, a green test suite, or a clean lint run is not sufficient on its own — the code must execute in the affected context at runtime.

Minimum coverage required: **≥ 90% of touched paths must be exercised at runtime** before the PR is opened.

### What "executed" means by change type

| Change type | Minimum execution required |
|---|---|
| Backend API change | Start the backend, call the affected endpoint (curl or Swagger), confirm response shape and status code |
| Frontend UI change | Start the full stack, open the browser, click through the affected flow and at least one edge case |
| Script change (`.ps1`, `.sh`) | **Run the script.** Every new code path added must be triggered at least once. Observe actual output, not just exit code. |
| Docker / compose change | `docker compose up` (and `--profile app` if app profile was changed), verify containers reach healthy state |
| Bootstrap / seed data change | Start the app with a clean DB, confirm the seeded data is correct |
| Config / env var change | Restart the app with the new config, confirm the value is actually picked up |

### Scripts and tooling — zero tolerance for untested code paths

Scripts are infrastructure — a broken script can block the whole team from starting or stopping the app. Every new function or branch added to a script **must** be invoked and produce the expected output before the PR is opened. Reviewing the code is not enough.

Checklist for script changes:
- [ ] Every new function was called and produced the expected output
- [ ] Every new mode/flag/option was triggered at least once
- [ ] Output messages match the expected text (spot-check key `[OK]`/`[XX]` lines)
- [ ] No non-ASCII characters in PowerShell scripts — use `--` not `—`, use `->` not `→`

### Smoke test for UI/API changes

1. Start the full stack on the default ports.
2. Exercise the affected feature end-to-end (golden path).
3. Check at least one edge case (empty state, error state, or validation error).
4. Confirm no obvious regressions in adjacent features.

---

## 9. Encoding and portability (scripts)

PowerShell 5.1 (Windows) reads scripts as Windows-1252 by default unless a UTF-8 BOM is present. Non-ASCII characters inside string literals cause silent mis-parsing.

**Rule:** Never use non-ASCII characters inside PowerShell string literals or variable values. Comments are safe. When in doubt, run:

```powershell
Select-String -Path your-script.ps1 -Pattern "[^\x00-\x7F]" | Select-Object LineNumber, Line
```

Any match outside a comment line is a blocker.

---

## Checklist summary

```
[ ] npm run lint         — 0 errors
[ ] npm run build        — clean compile
[ ] Backend tests green       — `mvnw test` (or `mvnw verify` for coverage report)
[ ] Frontend tests green      — `npm run test:run`
[ ] Coverage checked          — run `mvnw verify` + `npm run test:coverage`; if line coverage < 70%, note in PR and add follow-up task
[ ] No secrets staged
[ ] On a feature branch, not main/master
[ ] Version bumped       — once for the branch based on highest commit type (BLOCKER if app code changed)
[ ] CHANGELOG updated    — [Unreleased] moved to new version section
[ ] EXECUTED at runtime  — every touched code path run; ≥90% coverage
[ ] Scripts tested       — every new function/mode invoked, output verified
[ ] No non-ASCII in PS1 string literals
[ ] Infrastructure migration note in PR body (if compose/Dockerfile/ports changed)
[ ] All references updated   (if infrastructure changed)
[ ] CI unaffected            (if infrastructure changed)
[ ] DB migrations reversible (if schema changed)
[ ] API changes additive or versioned (if contract changed)
[ ] Rollback plan identified
[ ] Smoke tested on default ports
```
