# Prompt: Debug

Use this prompt when asking an AI agent to investigate a bug or unexpected behavior.

---

## Prompt template

```
Context: gastosai — AI-powered expense tracker.
Read AGENTS.md and ai/skills/project-context.md before investigating.

Problem: <describe what is happening vs. what is expected>

Reproduction:
- Steps: <step by step>
- Input: <request body / curl / UI action>
- Observed output: <error message, wrong value, stack trace>
- Expected output: <what should happen>

Environment:
- Backend log snippet (if available): <paste>
- Frontend console error (if available): <paste>
- DB state relevant to the bug (if known): <describe>

Investigation approach:
1. Identify which layer the bug lives in (controller / service / repo / AI path / frontend)
2. Trace the data flow from input to output
3. Identify the first point where behavior diverges from expectation
4. Propose a fix with minimal blast radius

Constraints:
- Do not change SqlGuard rules to work around AI query issues
- Do not change schema without migration planning
- Confirm fix with mvnw.cmd test before reporting done
```

---

## Common debug starting points

| Symptom | Where to look first |
|---|---|
| 400 Bad Request from backend | DTO validation annotations, `GlobalExceptionHandler` |
| 500 from AI query | `AiQueryService`, `SqlGuard`, backend log |
| Category not found after create | `CategoryService.getOrCreateByName()` transaction boundary |
| Frontend showing `undefined` | `types.ts` field name vs. backend JSON key |
| Date displayed wrong | `formatters.ts` `formatDate`, ISO string format from backend |
| Stale categories in dropdown | `getCategories()` called before `CategoryDataLoader` ran |
