# Skills Index — gastosai

Read this file first in any session. It defines precedence, reading order, and which skill governs each task type.

---

## Precedence (highest → lowest)

```
CLAUDE.md                          ← project-level overrides; always authoritative
ai/skills/  (project-specific)     ← gastosai rules; override shared defaults
ai/skills/shared/  (reusable)      ← general conventions; baseline for any project
```

When rules conflict, the higher-precedence source wins. Project-specific skills extend — not replace — shared ones. Always read both layers for a given task.

---

## Reading order by task

| Task | Read first | Then read |
|---|---|---|
| Any shell command | `shared/environment.md` | `environment.md` |
| Starting / testing the app | `environment.md` | `shared/pre-pr-checklist.md` |
| Making code changes | `shared/git-best-practices.md` | `git-best-practices.md` |
| Branching / versioning / releasing | `shared/git-branching-release-strategy.md` | `git-branching-release-strategy.md` |
| Before opening a PR | `shared/pre-pr-checklist.md` | `git-best-practices.md` |
| Reviewing a PR or commit | `commit-pr-review.md` | `backend-review.md` |
| Building a new feature | `feature-builder.md` | `java-spring-standards.md` |
| Writing or updating tests | `testing.md` | — |
| Touching the AI query path | `ai-sql-safety.md` | — |
| Deploying to production | `deployment.md` | `git-branching-release-strategy.md` |
| Understanding the domain model | `project-context.md` | — |
| Implementing with parallel agents | `agents.md` | — |
| Auditing / cleaning up stale docs | `doc-audit.md` | — |

---

## Skill descriptions

### Shared (reusable across projects)

| Skill | Purpose |
|---|---|
| `shared/environment.md` | OS/shell detection, port management, PATH quirks |
| `shared/git-best-practices.md` | Commit hygiene, branching rules, PR policy |
| `shared/git-branching-release-strategy.md` | SemVer, branch naming, CHANGELOG, tags |
| `shared/pre-pr-checklist.md` | Quality gate: lint, build, tests, secrets, versioning, rollback readiness |

### Project-specific (gastosai)

| Skill | Purpose |
|---|---|
| `environment.md` | Windows/PowerShell setup, default ports, reset procedure, GitHub CLI |
| `git-best-practices.md` | Project pre-PR commands, SqlGuard rule, summary format |
| `git-branching-release-strategy.md` | Dual-file version bump, tag-on-merge rule, gh CLI snippet |
| `feature-builder.md` | End-to-end feature build pattern for this stack |
| `commit-pr-review.md` | Code review checklist and severity classification |
| `backend-review.md` | Spring Boot layer-by-layer review checklist |
| `java-spring-standards.md` | Java 25 + Spring Boot 4 conventions |
| `testing.md` | Test stack, patterns, and what not to do |
| `ai-sql-safety.md` | SqlGuard rules — never bypass |
| `deployment.md` | Koyeb / Vercel / Supabase deploy walkthrough |
| `project-context.md` | Domain model, DTO contracts, request flow, env vars, frontend structure |
| `agents.md` | Parallel agent system — planner, backend-dev, frontend-dev, pre-pr |
| `doc-audit.md` | Documentation audit checklist — detect and fix stale docs |

---

## Non-negotiable rules (apply in every session)

1. **PowerShell only** — never use the Bash tool on this machine (Windows 11).
2. **Feature branch** — never commit non-trivial changes directly to `master`.
3. **Pre-PR checklist** — lint + build + tests must be green before any PR.
4. **Tag on merge** — every merge to `master` or a `release/` branch gets a version tag immediately.
5. **SqlGuard is inviolable** — no code path may execute AI-generated SQL without `SqlGuard.validate()`.
6. **No secrets committed** — `.env`, API keys, tokens must never appear in git history.
7. **Version files stay in sync** — `backend/pom.xml` and `frontend/package.json` always bump together.
