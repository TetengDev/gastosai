# Prompt: Add Feature

Use this prompt when asking an AI agent to implement a new feature.

---

## Prompt template

```
Context: gastosai — AI-powered expense tracker.
Read AGENTS.md and ai/skills/project-context.md before starting.

Feature request: <describe the feature>

Implementation path:
- For full-stack features (touches backend + frontend): use the parallel agent
  workflow defined in ai/skills/agents.md — planner first, then backend-dev +
  frontend-dev in parallel, then pre-pr.
- For backend-only or frontend-only features: use the relevant single agent.

Constraints:
- Follow the Controller → Service → Repository pattern for backend
- Use DTOs (records) for API contracts; never return JPA entities from controllers
- New categories must be created through CategoryService.getOrCreateByName()
- Any AI SQL path changes must be reviewed against ai/skills/ai-sql-safety.md
- Use .\mvnw.cmd on Windows — not local Maven
- Version bump required if commit type is feat: (MINOR) or fix: (PATCH)

Deliver:
1. Plan: files to create/modify + DTO contracts agreed before coding starts
2. Implementation (backend + frontend in parallel where possible)
3. Compile and test confirmation (backend) + lint and build confirmation (frontend)
4. Runtime execution evidence — what was run and what was observed
5. Note any follow-up concerns
```

---

## When to use

- Adding a new entity (e.g., Budget, Tag, RecurringExpense)
- Adding a new report endpoint (e.g., weekly totals, top-N categories)
- Adding a new frontend page
- Adding a new AI query capability

---

## Example filled prompt

```
Context: gastosai — AI-powered expense tracker.
Read AGENTS.md and ai/skills/project-context.md before starting.

Feature request: Add a Budget entity. A budget has a category, a monthly cap
amount, and an optional note. The user should be able to CRUD budgets via
/budgets. The dashboard should show whether each category is over or under budget
for the current month.

Implementation path: full-stack — use parallel agent workflow (ai/skills/agents.md).

Constraints:
- Follow the Controller → Service → Repository pattern for backend
- Use DTOs (records) for API contracts; never return JPA entities from controllers
- New categories must be created through CategoryService.getOrCreateByName()
- Any AI SQL path changes must be reviewed against ai/skills/ai-sql-safety.md
- Use .\mvnw.cmd on Windows — not local Maven
- Version bump: feat: → MINOR bump required

Deliver:
1. Plan: files + DTO contracts agreed before coding
2. Backend + frontend implementation in parallel
3. Compile/test confirmation + lint/build confirmation
4. Runtime execution evidence
5. Note any follow-up concerns
```
