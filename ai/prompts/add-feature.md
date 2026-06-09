# Prompt: Add Feature

Use this prompt when asking an AI agent to implement a new feature.

---

## Prompt template

```
Context: gastosai — AI-powered expense tracker.
Read AGENTS.md and ai/skills/project-context.md before starting.

Feature request: <describe the feature>

Constraints:
- Follow the Controller → Service → Repository pattern for backend
- Use DTOs (records) for API contracts; never return JPA entities from controllers
- New categories must be created through CategoryService.getOrCreateByName()
- Any AI SQL path changes must be reviewed against ai/skills/ai-sql-safety.md
- Use mvnw.cmd (Windows) / ./mvnw (Unix) — not local Maven
- Run mvnw.cmd test before reporting done

Deliver:
1. List of files to create or modify
2. Implementation (one file at a time)
3. Confirm tests pass
4. Note any follow-up concerns
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

Constraints:
- Follow the Controller → Service → Repository pattern for backend
- Use DTOs (records) for API contracts; never return JPA entities from controllers
- New categories must be created through CategoryService.getOrCreateByName()
- Any AI SQL path changes must be reviewed against ai/skills/ai-sql-safety.md
- Use mvnw.cmd (Windows) / ./mvnw (Unix) — not local Maven
- Run mvnw.cmd test before reporting done

Deliver:
1. List of files to create or modify
2. Implementation (one file at a time)
3. Confirm tests pass
4. Note any follow-up concerns
```
