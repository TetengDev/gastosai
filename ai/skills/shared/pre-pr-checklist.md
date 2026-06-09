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

## 2. Tests

### Backend

```bash
# Windows
.\mvnw.cmd test

# Unix
./mvnw test
```

### Frontend (if test runner is configured)

```bash
npm test -- --run
```

**Blocker:** Any failing test. All tests must be green before opening a PR.

New features require:
- Unit test for service/business logic
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

Check whether the commit type and changed files require a version bump:

| Commit type + app code changed | Bump |
|---|---|
| `fix:`, `perf:` | PATCH |
| `feat:` | MINOR |
| `feat!:` / `BREAKING CHANGE:` | MAJOR (MINOR if pre-1.0) |
| `docs:`, `test:`, `chore:`, `refactor:`, `ci:` | None |

"App code" = source files or package manifests. Docs, CI config, and tooling changes do not require a bump.

When a bump is required, update **all version files together** to the same version before committing.

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

## 8. Smoke test

For UI or API changes, verify the golden path in the running app before pushing:

1. Start the full stack on the default ports.
2. Exercise the affected feature end-to-end.
3. Check one or two edge cases (empty state, error state, validation).
4. Confirm no obvious regressions in adjacent features.

---

## Checklist summary

```
[ ] npm run lint       — 0 errors
[ ] npm run build      — clean compile
[ ] Backend tests      — all green
[ ] No secrets staged
[ ] Version bumped     (if required)
[ ] CHANGELOG updated  (if version bumped)
[ ] On a feature branch, not main/master
[ ] Infrastructure migration note in PR body (if compose/Dockerfile/ports changed)
[ ] All references updated  (if infrastructure changed)
[ ] CI unaffected      (if infrastructure changed)
[ ] DB migrations are reversible (if schema changed)
[ ] API changes are additive or versioned (if contract changed)
[ ] Rollback plan identified
[ ] Smoke tested on default ports
```
