# Skill: Git Best Practices

> General git rules live in `ai/skills/shared/git-best-practices.md`. This file adds gastosai-specific rules on top.

---

## Pre-PR checks — required for this project

Before pushing or opening a PR, always run the full pre-PR checklist:

```
ai/skills/shared/pre-pr-checklist.md
```

At minimum:

```powershell
# Backend (from backend/)
.\mvnw.cmd test

# Frontend (from frontend/)
npm run lint
npm run build
```

All checks must be green. Do not open a PR with failing lint, build errors, or test failures.

---

## Version bump rule

Both `backend/pom.xml` (app `<version>` at line ~13, not the Spring Boot parent) and `frontend/package.json` must be bumped **together** to the same version whenever app source code changes. See `ai/skills/git-branching-release-strategy.md` for the commit type → bump mapping.

---

## AI SQL changes — extra rule

If the change touches any of these, also read `ai/skills/ai-sql-safety.md`:

- `SqlGuard`
- `AiQueryService`
- `SqlGenerator` / `OpenAiSqlGenerator` / `ClaudeSqlGenerator`
- AI SQL prompts or query execution flow

Security rules override all other considerations.

---

## Final summary format

After making changes:

```
Branch:
Summary:
Files changed:
Tests run:
Suggested commit message:
Risks / follow-ups:
```
