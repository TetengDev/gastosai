# Skill: Feature Branch Workflow

## When to use

Any change that introduces new functionality, a significant refactor, or a risky modification should live on its own feature branch — never directly on `master`. Merge only after the feature works correctly end-to-end.

For full-stack features (backend + frontend), use the parallel agent workflow described in `ai/skills/agents.md` instead of implementing both layers sequentially.

---

## Workflow steps

### 1. Branch from master

```powershell
git checkout master
git pull
git checkout -b feat/<name>    # e.g. feat/budget-tracking, fix/dark-mode-badges
```

### 2. Develop and commit incrementally

One concern per commit. Stage specific files — never `git add .` (risks committing `.env`).

```powershell
git add backend/src/... frontend/src/...
git commit -m "feat: add Budget entity and CRUD endpoints"
```

### 3. Verify — automated checks

Run the full pre-PR checklist from `ai/skills/shared/pre-pr-checklist.md`. Minimum:

```powershell
cd frontend; npm run lint; npm run build
cd ..\backend; .\mvnw.cmd test
```

### 4. Verify — user acceptance (REQUIRED before merge)

**Never merge, never mark a feature done, and never open a PR without this step.**

Start the app so the user can exercise the new feature:

```powershell
# Full Docker stack (default)
docker compose --profile app up -d --build
```

Then explicitly ask the user:
- Which endpoint or UI flow to test
- What the expected behavior looks like
- Whether to test any edge cases

Only after the user confirms the feature works as expected may the branch be merged or the feature marked ✅ Done in the roadmap tracker.

### 5. Open PR from feat/* into release/x.y.z

**CI gate:** PRs to `master` must come from `release/*` only. Never open a PR from `feat/*` directly to `master` — CI will reject it.

Two-PR flow:
1. PR: `feat/<name>` → `release/x.y.z`
2. PR: `release/x.y.z` → `master`

`release/x.y.z` is created via `.\scripts\bump-version.ps1 -CutRelease` (bumps versions, creates branch, tags, pushes). If the release branch already exists, just open the PR from `feat/<name>` into it.

```powershell
$env:GH_TOKEN = (Get-Content ".env" | Select-String "GITHUB_TOKEN=(.+)" | ForEach-Object { $_.Matches[0].Groups[1].Value })
# PR 1: feat into release
& "C:\Program Files\GitHub CLI\gh.exe" pr create --base "release/<version>" --head "feat/<name>" --title "..." --body-file body.md
# PR 2 (after PR 1 merged): release into master
& "C:\Program Files\GitHub CLI\gh.exe" pr create --base master --head "release/<version>" --title "chore: release v<version>" --body-file body.md
```

### 6. After merge — branch cleanup rules

**Never delete** `master` or `release/*` branches (local or remote). They are permanent records.

Delete only `feat/*`, `fix/*`, `chore/*`, `refactor/*`, `ci/*`, `test/*` branches after their PR is merged:

```powershell
git branch -d feat/<name>               # delete local
git push origin --delete feat/<name>    # delete remote
git checkout master; git pull           # sync master
```

---

## Branch naming

| Prefix | When to use |
|---|---|
| `feat/` | New user-visible functionality |
| `fix/` | Bug fix |
| `refactor/` | Internal restructuring, no behavior change |
| `chore/` | Build, tooling, dependency, or documentation updates |
| `ci/` | CI/CD pipeline changes only |

Name after the concern, not the task — `feat/expense-filters` not `feat/add-filter-param`.

---

## What not to merge

- Feature is broken or partially implemented
- Backend tests fail
- TypeScript errors present
- Causes regressions in adjacent features
- No runtime execution evidence

Stay on the branch and keep iterating. Never merge broken code with intent to fix it on master.

---

## Checking branch state

```powershell
git branch --merged     # branches already merged — safe to delete
git branch --no-merged  # branches with unmerged commits — retain
git log main..HEAD --oneline   # commits unique to this branch
```
