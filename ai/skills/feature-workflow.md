# Skill: Feature Branch Workflow

## When to Use

Any change that introduces new functionality, a significant refactor, or a risky modification
should live on its own feature branch — not directly on `master`. Merge only after the feature
works correctly end-to-end.

## Workflow Steps

### 1. Branch out from master

```bash
git checkout master
git pull                          # make sure master is up to date
git checkout -b feature/<name>    # e.g. feature/chatbot-ui, feature/category-crud
```

Name the branch after the feature, not the task (e.g. `feature/expense-filters` not `feature/add-filter-param`).

### 2. Develop and commit incrementally

Commit in logical units — one concern per commit. Keep commits atomic so they can be
reviewed or reverted independently.

```bash
git add <specific files>
git commit -m "feature: <what and why>"
```

Avoid `git add .` — it can accidentally stage `.env` or generated files.

### 3. Verify before merging

Run the full stack and manually test the golden path and edge cases:

```powershell
.\scripts\start.ps1 -Mode all    # or start each layer individually
```

For backend changes, also run tests:

```bash
cd backend && mvnw.cmd test
```

Only merge when:
- The feature works as expected in the running app
- No regressions visible in other features
- Backend tests are green (`mvnw.cmd test`)
- TypeScript compiles clean (`npm run build` from `frontend/`)

### 4. Merge into master

```bash
git checkout master
git merge --no-ff feature/<name>   # preserve branch history
```

`--no-ff` creates a merge commit so the feature boundary is visible in git log.
Do not squash — individual commits carry useful context.

### 5. Delete the branch

After a successful merge, remove the branch to keep the repo clean:

```bash
git branch -d feature/<name>       # safe delete (only if merged)
```

Use `git branch --merged` to confirm before deleting.

## Branch Naming Conventions

| Prefix | When to use |
|---|---|
| `feature/` | New user-visible functionality |
| `fix/` | Bug fix for a specific issue |
| `refactor/` | Internal restructuring, no behavior change |
| `docs/` | Documentation-only changes |
| `chore/` | Build, tooling, dependency updates |

## What NOT to Merge

- Feature is broken or partially implemented
- Backend tests fail
- TypeScript errors present
- Causes regressions in existing pages

If the feature is not ready, stay on the branch and keep iterating. Never merge broken code to
master with the intention of fixing it there.

## Checking Branch State

```bash
git branch --merged     # branches already merged into current HEAD (safe to delete)
git branch --no-merged  # branches with unmerged commits (retain)
```
