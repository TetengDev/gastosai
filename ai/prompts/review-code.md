# Prompt: Review Code

Use this prompt when asking an AI agent to review a changeset or specific files.

---

## Prompt template

```
Context: gastosai — AI-powered expense tracker.
Read AGENTS.md and ai/skills/backend-review.md before reviewing.

Review the following: <file path(s) or diff>

Focus areas:
- [ ] Correctness: does it do what it claims?
- [ ] Safety: does any change touch the AI path? If so, check ai/skills/ai-sql-safety.md
- [ ] DTOs: are entities kept out of controller responses?
- [ ] Transactions: are @Transactional annotations correct?
- [ ] Validation: are inputs validated at the DTO layer?
- [ ] Money: is BigDecimal used for all monetary values?
- [ ] Tests: are new behaviors covered by tests?

Report:
1. Issues found (severity: critical / warning / suggestion)
2. Anything that looks correct and shouldn't be changed
3. Specific line-level feedback if applicable
```

---

## When to use

- Before merging a PR
- When an AI agent has produced an implementation and you want a second opinion
- After a refactor to check for regressions
- When reviewing an unfamiliar part of the codebase
