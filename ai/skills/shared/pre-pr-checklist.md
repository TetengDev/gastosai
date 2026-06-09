# Skill: Pre-PR Quality Checklist (Shared)

Run this checklist **before** pushing a branch or creating a pull request. A PR that fails any blocker item must not be opened until the item is resolved.

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
- `react-hooks/set-state-in-effect` — calling `setState` synchronously inside `useEffect` body; prefer deriving initial state from props/context in `useState`, not syncing via an effect
- `@typescript-eslint/no-explicit-any` — `any` types; use `unknown` for caught errors
- `@typescript-eslint/no-unused-vars` — dead variables
- Import errors — missing or circular imports

**Blocker:** Any ESLint error. Warnings are acceptable but should be reviewed.

### Backend (Java / Spring Boot)

```bash
# From backend/ (Windows)
.\mvnw.cmd compile    # zero errors required

# Unix
./mvnw compile
```

**Blocker:** Any compilation error or unused import.

---

## 2. Tests

### Frontend

```bash
npm run build   # TypeScript type errors surface here too
```

If the project has a test runner (Jest, Vitest):

```bash
npm test -- --run    # run once, no watch mode
```

### Backend

```bash
# Windows
.\mvnw.cmd test

# Unix
./mvnw test
```

**Blocker:** Any failing test. All tests must be green before opening a PR.

---

## 3. No secrets check

Before staging files, verify nothing sensitive is included:

```bash
git diff --staged
git status
```

Never commit:
- `.env` files or any file containing real credentials
- API keys, tokens, passwords
- Local machine paths or personal config
- IDE project files (`.idea/`, `.vscode/` unless intentionally shared)

**Blocker:** Any secret, credential, or token in staged files.

---

## 4. Version bump (if applicable)

Check whether the commit type and changed files require a version bump:

| Commit type + app code changed | Bump |
|---|---|
| `fix:`, `perf:` | PATCH |
| `feat:` | MINOR |
| `feat!:` / `BREAKING CHANGE:` | MAJOR (MINOR if pre-1.0) |
| `docs:`, `test:`, `chore:`, `refactor:`, `ci:` | None |

"App code changed" means source files or package manifests (`pom.xml`, `package.json`) were touched — not docs, CI config, or git hooks.

When a bump is required, update **all version files together** (e.g. both `pom.xml` and `package.json` in a full-stack project) to the same version.

---

## 5. CHANGELOG

When a version bump is made, move the relevant `[Unreleased]` notes into the new version section in `CHANGELOG.md` with today's date.

---

## 6. Branch and diff sanity

```bash
git branch --show-current          # confirm you are on a feature branch, not main
git diff main...HEAD --stat        # review scope of what will be in the PR
git log main..HEAD --oneline       # review commit history
```

Rules:
- Must be on a feature branch (not `main`/`master`).
- Diff should only contain changes related to the current task.
- No unrelated files mixed in.

---

## 7. Manual smoke test

For UI or API changes, verify the golden path in the running app:

- Start the full stack locally.
- Navigate to the affected feature.
- Confirm the happy path works.
- Check one or two edge cases (empty state, error state).
- Confirm no obvious regressions in adjacent features.

---

## Checklist summary

```
[ ] npm run lint   — 0 errors
[ ] npm run build  — clean compile
[ ] Backend tests  — all green
[ ] No secrets in staged files
[ ] Version bumped (if required by commit type + app code)
[ ] CHANGELOG updated (if version bumped)
[ ] On a feature branch, not main
[ ] Smoke tested the affected feature
```
