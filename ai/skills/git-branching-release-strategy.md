# Skill: Git Branching and Release Strategy

> General SemVer, branching, and release rules live in `ai/skills/shared/git-branching-release-strategy.md`. This file adds gastosai-specific rules on top.

---

## Version bump — this project

Both files must be bumped **together** to the same version:

- `backend/pom.xml` — the `<version>` tag at ~line 13 (not the Spring Boot parent version)
- `frontend/package.json` — the `"version"` field

A bump is only required when **app code** changes (`backend/src/`, `frontend/src/`, `backend/pom.xml`, `frontend/package.json`). Commits touching only docs, CI config, skills, or git hooks do not need a bump.

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
# Load token (stored in repo root .env)
$env:GH_TOKEN = (Get-Content ".env" | Select-String "GITHUB_TOKEN=(.+)" | ForEach-Object { $_.Matches[0].Groups[1].Value })

# Create PR
& "C:\Program Files\GitHub CLI\gh.exe" pr create --title "..." --body-file body.md
```
