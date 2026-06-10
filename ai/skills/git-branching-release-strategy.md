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

## Tag on merge to protected branches — required

`master` and `release/*` are protected branches. **Every merge to these branches must be immediately followed by a version tag.** Do not skip tagging.

### Procedure

```powershell
# 1. Confirm you are on master (or the release branch) and it is clean
git status
git log --oneline -3

# 2. Read the current version from pom.xml
$version = (Select-String '<version>(\d+\.\d+\.\d+)</version>' backend/pom.xml |
    Where-Object { $_.LineNumber -eq 13 } |
    ForEach-Object { $_.Matches[0].Groups[1].Value })
Write-Output "Tagging v$version"

# 3. Create annotated tag
git tag -a "v$version" -m "Release v$version"

# 4. Push the tag
git push origin "v$version"
```

### Why annotated tags

Annotated tags store the tagger, date, and message — they make it possible to `git checkout v0.5.1` to reproduce any released state exactly. Lightweight tags do not carry this metadata.

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
