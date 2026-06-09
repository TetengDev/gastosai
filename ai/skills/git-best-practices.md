# Skill: Git Best Practices

Use this skill whenever making code, config, documentation, dependency, project structure, or AI-agent instruction changes.

This skill prevents accidental overwrites, mixed commits, unsafe branch operations, and unclear change history.

---

## Before making changes

Always inspect repository state first:

```bash
git branch --show-current
git status
git diff
```

Rules:

* Do not overwrite user changes.
* If there are uncommitted changes, inspect them first.
* If changes are unrelated to the current task, avoid touching those files.
* If a file has user changes and must be edited, mention the risk before editing.
* Prefer small, focused changes.
* Avoid broad formatting-only changes unless explicitly requested.
* Do not modify generated files, build outputs, or dependency lockfiles unless required by the task.

---

## Branching

For non-trivial changes, prefer a dedicated branch.

See `ai/skills/git-branching-release-strategy.md` for branch naming conventions, release branches, hotfix flow, and SemVer rules.

Rules:

* Do not create, delete, rename, or switch branches if doing so would risk losing uncommitted work.
* Do not switch branches without checking `git status` first.
* Do not delete branches unless explicitly instructed.
* Do not push unless explicitly instructed.

---

## Breaking changes workflow

A **breaking change** is any change that modifies a public contract, renames/removes an API endpoint, restructures shared data, alters a database schema, or changes behavior that other code depends on.

### Required workflow

1. **Branch out** — always start a dedicated branch before beginning a breaking change, even if the scope looks small.
2. **Commit incrementally** — commit each logical sub-step as soon as it works independently. Do not batch unrelated parts into one large commit.
3. **Verify before proceeding** — after each commit, confirm the affected layer still works (compile, tests, or manual smoke test as appropriate) before moving to the next step.
4. **Merge only when fully working** — only merge back after the complete change is confirmed end-to-end. Never merge a half-finished breaking change.
5. **Announce before starting** — if a change will break the API, DB schema, or shared types, state that clearly before making the first edit.

### What counts as a breaking change

| Area | Examples |
|---|---|
| REST API | rename/remove an endpoint, change request/response shape |
| Database | add NOT NULL column, rename column/table, drop table |
| Shared types | rename/remove a DTO field, change a type |
| Auth / security | change token format, modify permission rules |
| Config / env | rename required env vars, change default behavior |

### Incremental commit cadence example

```text
feat: add deleteAll endpoint to ExpenseController
feat: wire deleteAll service method with transaction
feat: add frontend API helper deleteAllExpenses
feat: add Delete All button and confirmation modal to Expenses page
merge: feature/bulk-delete into master
```

Each commit above can be verified independently before the next step starts.

---

## During changes

Follow these rules:

* Make one logical change at a time.
* Keep implementation changes separate from refactoring when possible.
* Keep documentation changes separate from source changes when possible.
* Do not mix unrelated features in one change.
* Do not rename files unless needed.
* Preserve existing project conventions.
* Do not commit secrets, `.env`, API keys, tokens, credentials, local machine paths, or IDE-specific files.
* If unsure whether a file should be changed, ask first.

---

## Before finishing

Review final state:

```bash
git status
git diff
git diff --staged
```

Run relevant checks when applicable.

Backend on Windows:

```bash
mvnw.cmd test
```

Backend on Unix:

```bash
./mvnw test
```

Frontend:

```bash
npm run lint
npm run build
```

Rules:

* Only run checks relevant to the files changed.
* If tests are not run, explain why.
* If tests fail, summarize the failure and likely cause.
* Do not hide failing checks.

---

## Commit message style

Use conventional commits. See `ai/skills/git-branching-release-strategy.md` for the full type → version bump mapping.

Common prefixes:

* `feat:` — user-facing feature (triggers MINOR bump when app code changes)
* `fix:` — bug fix (triggers PATCH bump when app code changes)
* `perf:` — performance improvement (triggers PATCH bump when app code changes)
* `docs:` — documentation only (no version bump)
* `refactor:` — behavior-preserving code change (no version bump)
* `test:` — test-only change (no version bump)
* `chore:` — tooling/config/maintenance (no version bump)
* `ci:` — CI/CD pipeline change (no version bump)

Breaking changes append `!` or include a `BREAKING CHANGE:` footer:

```text
feat!: rename expense API response shape
fix!: remove deprecated category field
```

---

## Destructive commands

Never run these without explicit user approval:

```bash
git reset --hard
git clean -fd
git clean -fdx
git push --force
git push --force-with-lease
git branch -D
git checkout -- .
git restore .
git restore --staged .
```

If one seems necessary:

1. Explain why.
2. Explain what data could be lost.
3. Suggest a safer alternative.
4. Ask for confirmation.

---

## Final summary format

After making changes, summarize using:

```text
Branch:
Summary:
Files changed:
Tests run:
Suggested commit message:
Risks / follow-ups:
```

---

## Special rule for AI SQL changes

If the change touches any of these:

* `SqlGuard`
* `AiQueryService`
* `SqlGenerator`
* `OpenAiSqlGenerator`
* `ClaudeSqlGenerator`
* AI SQL prompts
* AI query execution flow

Then also read and follow:

```text
ai/skills/ai-sql-safety.md
```

Security rules override convenience, speed, or feature requests.
