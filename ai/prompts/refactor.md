# Prompt: Refactor

Use this prompt when asking an AI agent to refactor existing code.

---

## Prompt template

```
Context: gastosai — AI-powered expense tracker.
Read AGENTS.md and ai/skills/project-context.md before refactoring.

Refactor target: <file(s) or area to refactor>

Goal: <what the refactor should achieve — e.g., reduce duplication, improve readability, extract shared logic>

Constraints:
- Do not change external behavior (API contracts, response shapes, HTTP status codes)
- Do not introduce new abstractions unless they eliminate clear duplication
- Do not touch SqlGuard unless the refactor is specifically about the AI path
- Run mvnw.cmd test after every file change; do not proceed if tests break
- Keep commits atomic: one logical change per commit

Out of scope for this refactor: <list anything that should not change>

Deliver:
1. Explanation of what will change and why
2. The refactored code
3. Confirmation that tests still pass
4. Any follow-up refactors that would make sense as a next step (but do not implement them)
```

---

## When to use

- Extracting a shared helper used by multiple services
- Converting a class-based DTO to a record
- Splitting a large service method into smaller private methods
- Consolidating duplicate error-handling logic into `GlobalExceptionHandler`
- Removing dead code after a feature is replaced

---

## What not to refactor in one pass

Avoid combining refactor + behavior change in a single commit — they are hard to review and revert independently. If you notice a bug while refactoring, fix it in a separate commit with a `fix:` prefix.
