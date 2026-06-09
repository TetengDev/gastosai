# Skill: Git Best Practices (Shared)

General git hygiene rules applicable to any project.

---

## Before making changes

Always inspect repository state first:

```bash
git branch --show-current
git status
git diff
```

Rules:

- Do not overwrite user changes.
- If uncommitted changes exist, inspect them before proceeding.
- If changes are unrelated to the current task, avoid touching those files.
- Prefer small, focused changes.
- Avoid broad formatting-only changes unless explicitly requested.
- Do not modify generated files, build outputs, or lockfiles unless required by the task.

---

## Branching

For non-trivial changes, always use a dedicated branch.

Rules:

- Do not create, delete, rename, or switch branches if doing so would risk losing uncommitted work.
- Do not switch branches without checking `git status` first.
- Do not delete branches unless explicitly instructed.
- Do not push unless explicitly instructed.

---

## Breaking changes workflow

A **breaking change** is any change that modifies a public contract, renames/removes an API endpoint, restructures shared data, alters a database schema, or changes behavior that other code depends on.

### Required workflow

1. **Branch out** — always start a dedicated branch before beginning a breaking change.
2. **Commit incrementally** — commit each logical sub-step as soon as it works independently.
3. **Verify before proceeding** — after each commit, confirm the affected layer still works before moving to the next step.
4. **Merge only when fully working** — never merge a half-finished breaking change.
5. **Announce before starting** — state clearly if a change will break the API, DB schema, or shared types.

---

## During changes

- Make one logical change at a time.
- Keep implementation changes separate from refactoring.
- Keep documentation changes separate from source changes.
- Do not mix unrelated features in one change.
- Do not rename files unless needed.
- Preserve existing project conventions.
- Do not commit secrets, `.env`, API keys, tokens, credentials, or IDE-specific files.

---

## Commit message style

Use [Conventional Commits](https://www.conventionalcommits.org/):

| Prefix | Meaning |
|---|---|
| `feat:` | User-facing feature |
| `fix:` | Bug fix |
| `perf:` | Performance improvement |
| `docs:` | Documentation only |
| `refactor:` | Behavior-preserving restructure |
| `test:` | Test-only change |
| `chore:` | Tooling / config / maintenance |
| `ci:` | CI/CD pipeline change |

Breaking changes append `!` or include a `BREAKING CHANGE:` footer:

```
feat!: rename expense API response shape
```

---

## Destructive commands

Never run these without explicit user approval:

```bash
git reset --hard
git clean -fd
git push --force
git push --force-with-lease
git branch -D
git checkout -- .
git restore .
```

If one seems necessary: explain why, explain what data could be lost, suggest a safer alternative, and ask for confirmation.

---

## Final state check

Before finishing any change:

```bash
git status
git diff
git diff --staged
```

---

## Pull request policy

**Simple / single-concern changes** — automatically create the PR.

**Non-trivial / multi-file / feature changes** — ask the user before creating a PR.

Never create a PR for a branch that has failing checks, is not confirmed working end-to-end, or is still in progress.
