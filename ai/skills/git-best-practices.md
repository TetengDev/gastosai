# Skill: Git Best Practices

> General git rules live in `ai/skills/shared/git-best-practices.md`. This file adds gastosai-specific rules on top.
> PR policy is defined in `shared/git-best-practices.md` (single source of truth).
> Version bump and tagging rules are defined in `git-branching-release-strategy.md`.

---

## Pre-PR checks — required for this project

Before pushing or opening a PR, run the full checklist from `ai/skills/shared/pre-pr-checklist.md`. At minimum:

```powershell
# Backend (from backend/)
.\mvnw.cmd test

# Frontend (from frontend/)
npm run lint
npm run build
```

All three must be green. Do not open a PR with lint errors, build failures, or test failures.

---

## AI SQL changes — extra rule

If the change touches any of the following, also read `ai/skills/ai-sql-safety.md` before proceeding:

- `SqlGuard`
- `AiQueryService`
- `SqlGenerator` / `OpenAiSqlGenerator` / `ClaudeSqlGenerator`
- AI SQL prompts or the query execution flow

Security rules override all other considerations — no exceptions.

---

## Post-merge — tag immediately

After merging to `master` or a `release/` branch, create and push a version tag before doing anything else. See `git-branching-release-strategy.md` for the exact procedure.

---

## Final summary format

After completing any change, summarise using:

```
Branch:
Summary:
Files changed:
Tests run:
Suggested commit message:
Risks / follow-ups:
```
