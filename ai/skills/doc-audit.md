# Skill: Documentation Audit

Use this skill to audit project documentation for staleness and inconsistencies. Run before major releases or whenever the codebase drifts noticeably from the docs.

---

## Authoritative sources (update these first)

These files are the single source of truth — other docs reference them:

| File | Owns |
|---|---|
| `ai/skills/project-context.md` | Domain model, DTO contracts, frontend file structure, routes |
| `ai/skills/java-spring-standards.md` | Java 25 + Spring Boot 4 conventions |
| `ai/skills/shared/pre-pr-checklist.md` | Quality gate — lint, tests, runtime execution, versioning |
| `CLAUDE.md` | Shell/runtime defaults, .env variables, version bump rules |
| `AGENTS.md` | Project overview, agent index, skills index |

---

## Audit checklist

### Domain model drift

Check `ai/skills/project-context.md` against the actual entity classes:

- [ ] All entity fields listed (including recent additions like `icon`, `avatarColor`, etc.)
- [ ] DTO contracts match current record definitions in `backend/src/main/java/.../dto/`
- [ ] Frontend file structure matches `frontend/src/` (pages, components, hooks, api files)
- [ ] Routes list is current
- [ ] No references to renamed fields (e.g. `note` was renamed to `description`)

### Backend CLAUDE.md

Check `backend/CLAUDE.md` against current entities:

- [ ] Entity count and field descriptions are current
- [ ] JWT behavior description is accurate
- [ ] No references to removed/renamed fields

### AGENTS.md index

Check `AGENTS.md`'s agent and skills index:

- [ ] All `.claude/agents/*.md` files are listed
- [ ] All `ai/skills/*.md` files are listed
- [ ] No entries point to deleted files

### Skills internal consistency

- [ ] `ai/skills/feature-workflow.md` — branch naming and merge strategy match actual practice
- [ ] `ai/skills/environment.md` — ports, paths, GitHub CLI location still accurate
- [ ] `ai/prompts/add-feature.md` — references current agent system

### Delete candidates

Flag a file for deletion if it meets any of these criteria:

- References a stack version more than one major behind (e.g. Java 17 when project is on Java 25)
- Documents a deployment target that is no longer used
- Is a generator/boilerplate file with no project-specific content (e.g. `backend/HELP.md`)
- Is a planning document that predates the current implementation with no forward-looking value

---

## Staleness signals

| Signal | File to check |
|---|---|
| Entity field name changed | `project-context.md`, `backend/CLAUDE.md` |
| New page or route added | `project-context.md` (frontend structure + routes) |
| New agent added | `AGENTS.md`, `ai/skills/README.md`, `ai/skills/agents.md` |
| New skill added | `AGENTS.md`, `ai/skills/README.md` |
| Deployment target changed | `CLAUDE.md`, `ai/skills/deployment.md`, `AGENTS.md` quick-start |
| Port changed | `CLAUDE.md`, `ai/skills/environment.md` |
| New .env variable | `CLAUDE.md`, `ai/skills/project-context.md` |

---

## Cleanup order

1. Delete obsolete files first (planning docs, boilerplate)
2. Update authoritative sources (`project-context.md`, `CLAUDE.md`)
3. Update index files (`AGENTS.md`, `ai/skills/README.md`)
4. Update prompts and templates last
5. Add all changes in a single `chore:` commit — no version bump needed for docs-only
