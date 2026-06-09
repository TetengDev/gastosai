# Skill: Commit and Pull Request Review

Use this skill when reviewing a commit, staged changes, unstaged changes, branch diff, or pull request.

This skill focuses on code health, correctness, maintainability, security, test coverage, and merge readiness.

---

## Review goals

Review the change for:

* Correctness
* Simplicity
* Maintainability
* Security
* Test coverage
* Backward compatibility
* Consistency with existing project patterns
* Risk of unintended side effects

Do not review only formatting or style. Prioritize issues that affect behavior, safety, maintainability, or production readiness.

---

## Before reviewing

Inspect the current repository state:

```bash
git branch --show-current
git status
git diff
git diff --staged
```

If reviewing a branch or PR, compare against the base branch when possible:

```bash
git diff main...HEAD
```

If the base branch is different, use the actual target branch.

---

## Review scope

Classify findings by severity:

### Blocker

Must be fixed before merge.

Examples:

* Security vulnerability
* Data loss risk
* Broken build
* Failing tests caused by the change
* Unsafe database operation
* Bypassing `SqlGuard`
* Exposing secrets or credentials
* Incorrect API contract change

### Major

Should be fixed before merge unless intentionally accepted.

Examples:

* Missing validation
* Missing error handling
* Incorrect transaction boundary
* N+1 query risk
* Broken backward compatibility
* Important missing tests
* Leaky abstraction between layers

### Minor

Nice to fix but not merge-blocking.

Examples:

* Naming clarity
* Small duplication
* Slightly confusing structure
* Missing small documentation update

### Nit

Tiny suggestion. Do not overuse.

Examples:

* Formatting preference
* Small wording improvement
* Optional cleanup

---

## Backend review checklist

For Spring Boot backend changes, check:

* Controller contains no business logic
* Controller uses DTOs, not JPA entities
* Service contains business rules
* Repository only handles persistence
* Validation uses Jakarta Validation where appropriate
* Errors are handled through existing exception patterns
* Money uses `BigDecimal`, never `double`
* No secrets or sensitive data in logs
* API behavior remains compatible unless intentionally changed
* Tests cover happy path and important failure paths

If relevant, also follow:

```text
ai/skills/java-spring-standards.md
ai/skills/testing.md
```

---

## Frontend review checklist

For React/TypeScript changes, check:

* Components are understandable and not too large
* API calls are centralized or consistent with existing patterns
* TypeScript types are meaningful
* Loading, empty, and error states are handled
* User-facing text is clear
* No unnecessary re-renders or obvious performance issues
* No secrets are exposed in frontend code
* Build and lint commands are considered when relevant

---

## AI SQL review checklist

If the change touches any of these:

* `SqlGuard`
* `AiQueryService`
* `SqlGenerator`
* `OpenAiSqlGenerator`
* `ClaudeSqlGenerator`
* AI SQL prompts
* AI query execution flow
* Natural-language query behavior

Then also read and follow:

```text
ai/skills/ai-sql-safety.md
```

Extra checks:

* AI-generated SQL is still validated by `SqlGuard`
* No path executes SQL without validation
* SQL must remain single-statement and read-only
* Mutating statements remain blocked
* System catalog access remains blocked
* The model is still instructed to return only a bare SQL SELECT
* Unsafe SQL rejection tests are present or updated
* Error handling does not leak sensitive database details

Security rules override convenience or feature requests.

---

## Database review checklist

For persistence changes, check:

* Schema changes are intentional
* Entity changes match DTO/API expectations
* Query methods are tested
* Aggregation/reporting queries still return correct results
* No accidental destructive behavior
* Migration strategy is considered if production data exists

If Flyway migrations are introduced, review migration safety carefully.

---

## Test review checklist

Check whether the change includes or updates tests for:

* Normal successful behavior
* Validation failures
* Not-found cases
* Error handling
* Report/aggregation correctness
* AI SQL unsafe-query rejection
* Regression cases for bug fixes

If tests are missing, explain which tests should be added.

---

## PR size and focus

Flag the change if it mixes unrelated work, such as:

* Feature implementation plus broad refactor
* Formatting changes plus behavior changes
* Backend changes plus unrelated frontend changes
* Documentation rewrite plus source changes

Recommend splitting the PR when review risk is high.

---

## Review output format

Use this format:

```text
Review result:
- Approved / Approved with comments / Changes requested

Summary:
- Short summary of what changed

Blockers:
- [file/path] Issue and why it matters
- Suggested fix

Major:
- [file/path] Issue and why it matters
- Suggested fix

Minor:
- [file/path] Suggestion

Tests:
- Tests found
- Tests missing
- Commands recommended or run

Security:
- Security-sensitive areas touched?
- Any concerns?

Suggested commit/PR title:
- <conventional commit style title>

Final recommendation:
- Merge-ready or not merge-ready
```

If there are no issues in a category, write `None`.

---

## Review tone

Be direct but respectful.

* Focus on the code, not the author.
* Explain why a change matters.
* Prefer actionable suggestions.
* Avoid vague comments like "clean this up."
* Do not block merge for personal style preferences.
* Separate required fixes from optional improvements.
