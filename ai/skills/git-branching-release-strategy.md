# Skill: Git Branching and Release Strategy

> General SemVer, branching, and release rules live in `ai/skills/shared/git-branching-release-strategy.md`. This file adds gastosai-specific rules on top.

---

## Version bump — this project

Both files must be bumped **together** to the same version:

- `backend/pom.xml` — the `<version>` tag at ~line 13 (not the Spring Boot parent version at line 8)
- `frontend/package.json` — the `"version"` field

**Bump once per PR, not once per commit.** Commit freely on the feature branch. Before opening the PR, check `git log master..HEAD --oneline`, find the highest-impact commit type, and bump accordingly. Commits touching only docs, CI config, skills, or git hooks do not need a bump.

The `commit-msg` hook is a **format linter only** — it validates the `type(scope): description` shape but does not block on version bumps.

---

## Release branch workflow

**CI gate:** `.github/workflows/continuous-integration.yml` runs `validate-release-branch` on every PR to `master`. Only two sources are allowed:
- **`release/*`** — the path for **any application change** and **any version bump**. Always allowed.
- **`meta/*`** — a narrow lane for **non-application changes only** (CI/workflows, repo docs, `.claude` agents, `ai/skills`, `.gitignore`). Allowed only if the PR (a) does **not** change the `frontend/package.json` version and (b) touches **no** `backend/src` or `frontend/src`. Either guard tripping fails the gate.

Any other source (`feat/*`, `fix/*`, `chore/*`, `docs/*`, …) is rejected — route app changes through `release/*` and non-app changes through `meta/*`.

**Two-PR flow (for application changes — strictly enforced):**
1. PR: `feat/*` / `fix/*` (or any working branch) → `release/x.y.z`
2. PR: `release/x.y.z` → `master`

Non-app changes skip this: a single `meta/*` → `master` PR (no version bump per SemVer — docs/CI/tooling don't change the public API).

**Branch deletion rules (strictly enforced):**
- `master` and `release/*` — NEVER delete, local or remote. They are permanent records.
- All other branches (`feat/*`, `fix/*`, `meta/*`, etc.) — delete after PR is merged.

This project uses a **release branch strategy**: feature branches are developed on `feat/*`, then merged into a `release/x.y.z` branch via PR, which then PRs to `master`. The release branch is tagged, protected, and never deleted — it is the permanent record of that shipped state. A **hotfix** is an urgent production fix: it is still an application change, so it bumps PATCH and ships through a `release/x.y.z` cut from `master` (it does not use the `meta/*` lane).

### Automated (recommended)

Use `scripts/bump-version.ps1 -CutRelease`. The script:
1. Auto-detects the bump type from git log (or accepts `-Bump MAJOR|MINOR|PATCH`)
2. Updates `backend/pom.xml`, `frontend/package.json`, and `CHANGELOG.md`
3. Creates `release/x.y.z` from the current HEAD
4. Commits the version files, creates an annotated tag, and pushes both
5. Prints the `gh api` command to enable branch protection

```powershell
# Dry-run first — see the recommended bump before applying
.\scripts\bump-version.ps1

# Apply bump + cut release branch
.\scripts\bump-version.ps1 -CutRelease
```

### Manual procedure

If the script is unavailable, follow these steps:

```powershell
# 1. Confirm clean working tree on master
git status
git log --oneline -3

# 2. Read the project version from pom.xml (line ~13, skip Spring Boot parent)
$version = (Get-Content backend/pom.xml |
    Select-String '<version>(\d+\.\d+\.\d+)</version>' |
    Select-Object -Skip 1 -First 1).Matches[0].Groups[1].Value
Write-Output "Version: $version"

# 3. Cut the release branch
git checkout -b "release/$version"

# 4. Commit any last-minute version-bump files (if not already on branch)
git add backend/pom.xml frontend/package.json CHANGELOG.md
git commit -m "chore: release v$version"

# 5. Create annotated tag
git tag -a "v$version" -m "Release v$version"

# 6. Push branch and tag
git push origin "release/$version"
git push origin "v$version"
```

After pushing, set branch protection via the GitHub UI or the `gh api` command printed by the script.

### Why annotated tags

Annotated tags store the tagger, date, and message — they make it possible to `git checkout v0.5.1` to reproduce any released state exactly. Lightweight tags do not carry this metadata.

---

## Tag on merge — required

`master` and `release/*` are protected branches. **Every merge to these branches must have a corresponding version tag.** Do not skip tagging.

Use `scripts/bump-version.ps1 -CutRelease` — it creates the tag automatically. For master-only merges without a release branch cut, create the tag manually:

```powershell
git tag -a "v$version" -m "Release v$version"
git push origin "v$version"
```

---

## Rollback using tags

If a release is broken, roll back the deployment to the previous tag:

```powershell
# List recent tags
git tag --sort=-creatordate | Select-Object -First 5

# Check out the previous good release locally
git checkout v<previous-version>

# Or revert the merge commit on master and re-tag
git revert <merge-commit-sha> --no-edit
# ... bump version to a new patch, commit, tag, push
```

Never force-push `master` to undo a merge. Use `git revert` to create a forward-fixing commit instead.

---

## AI SQL changes — release caution

If the release includes changes to `SqlGuard`, `AiQueryService`, `SqlGenerator`, OpenAI/Claude SQL prompts, or the AI query execution flow:

- Prefer a prerelease (`-rc.1`) first.
- Require tests proving unsafe SQL is still rejected.
- Do not weaken `SqlGuard`.
- Do not release if the AI SQL path can bypass validation.

See `ai/skills/ai-sql-safety.md` for the full rule set.

---

## PR creation via gh CLI

```powershell
$env:GH_TOKEN = (Get-Content ".env" | Select-String "GITHUB_TOKEN=(.+)" | ForEach-Object { $_.Matches[0].Groups[1].Value })
& "C:\Program Files\GitHub CLI\gh.exe" pr create --title "..." --body-file body.md
& "C:\Program Files\GitHub CLI\gh.exe" pr merge <number> --merge --delete-branch
```
