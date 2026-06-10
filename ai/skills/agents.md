# Skill: Agent-Based Feature Workflow

Agents live in `.claude/agents/`. They run as sub-agents via the Claude Code `Agent` tool.
Use them instead of (or alongside) the skill docs when implementing features.

---

## Available agents

### Feature agents

| Agent | Role | Model |
|---|---|---|
| `full-stack-planner` | Read the codebase and decompose a feature into backend + frontend tasks with agreed DTO contracts | Sonnet |
| `backend-dev` | Implement Spring Boot changes; self-verifies with compile + test | Sonnet |
| `frontend-dev` | Implement React/TypeScript changes; self-verifies with lint + build | Sonnet |
| `pre-pr` | Run the full quality checklist before a PR | Haiku |
| `prompt-compressor` | Compress verbose agent prompts to < 800 tokens before spawning sub-agents | Haiku |

### Specialized agents

| Agent | Role | Model |
|---|---|---|
| `resource-finder` | Research and rank libraries/tools by adoption, security, and community before adding new dependencies | Sonnet |
| `ui-ux-reviewer` | Review UI/UX decisions against best practices for dashboards and data visualization | Sonnet |
| `feature-prioritizer` | Score feature candidates with ICE + revenue multiplier; returns ranked table with top-pick | Sonnet |
| `tech-workflow` | Engineering process advisor — branching, PR sizing, sprint discipline, incident response | Sonnet |
| `cleanup` | Scan for stale/irrelevant files and report deletion candidates with confidence levels | Haiku |
| `agent-auditor` | Audit all agents/skills for registration, overlap, consolidation, and skill gaps; auto-fix indexes | Sonnet |

---

## Parallel feature workflow

This is the standard path for any feature that touches both layers.

```
1. full-stack-planner   →  produces: backend task list + frontend task list + DTO contract
                                        ↓
2.              prompt-compressor  →  compress each agent prompt to < 800 tokens
                               ↓                             ↓
3.      backend-dev (parallel)               frontend-dev (parallel)
                        ↓                             ↓
4.                    both finish                 both finish
                                        ↓
5.                             pre-pr  →  checklist report
                                        ↓
6.                       commit + push + open PR
```

**Step 1 must complete before steps 2–3 start.** The DTO contract defined by the planner is the seam that lets both agents work without blocking each other.

Steps 2 and 3 run **in parallel** — spawn both agents in the same message.

---

## When to use each agent

| Situation | Use |
|---|---|
| Full-stack feature (new field, new page, new endpoint) | planner → prompt-compressor → backend-dev + frontend-dev in parallel → pre-pr |
| Backend-only change (new endpoint, service logic) | backend-dev → pre-pr |
| Frontend-only change (UI fix, new component) | frontend-dev → pre-pr |
| Dark mode fix, copy change, style tweak | frontend-dev only (no pre-pr needed for trivial changes) |
| Before any PR | pre-pr |
| Before adding a new dependency | resource-finder |
| Adding or changing charts, cards, tables, controls | ui-ux-reviewer |
| Deciding what to build next | feature-prioritizer |
| Deciding how to structure work or size a PR | tech-workflow |
| Before a release or when docs feel cluttered | cleanup |
| After adding a new agent or skill | agent-auditor |

---

## Invoking agents

Claude Code spawns agents via the `Agent` tool with `subagent_type` set to the agent name.
The user does not need to name the agent — Claude selects the right one from context.

To trigger parallel execution, include both agent calls in the same response.

---

## Built-in agents and commands that complement these

| Built-in | When to use alongside project agents |
|---|---|
| `Explore` | Fast symbol/file lookup before handing a task to backend-dev or frontend-dev |
| `Plan` | Alternative to full-stack-planner for open-ended architecture questions |
| `/code-review ultra` | Post-implementation review before pre-pr (invoke as a slash command, not a subagent_type) |

---

## Relationship to skills

Each project agent reads the `ai/skills/` files relevant to its task:

| Agent | Skills it reads |
|---|---|
| `full-stack-planner` | `project-context.md` |
| `backend-dev` | `project-context.md`, `java-spring-standards.md`, `testing.md` |
| `frontend-dev` | `project-context.md` |
| `pre-pr` | `shared/pre-pr-checklist.md` |
| `prompt-compressor` | `token-optimization.md` |
| `cleanup` | `doc-audit.md` |
| `agent-auditor` | `doc-audit.md` |

Skills remain the single source of truth for conventions. Agents reference them rather than duplicate them.

---

## Notes

- `full-stack-planner` is read-only (tools restricted to Read, Glob, Grep) — it cannot write code.
- `pre-pr` uses Haiku for speed; it runs shell commands and reports results, not code analysis.
- `prompt-compressor` runs between planner and dev agents — always use it to stay under the 800-token prompt budget.
- `agent-auditor` must be run after adding any new agent or skill to keep all indexes in sync.
- All agents self-verify before reporting done — a report without compile/lint results means the verification step was skipped.
