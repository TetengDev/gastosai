# gastosai

AI-powered personal expense tracker. Natural-language queries translate to safe SQL via a pluggable LLM provider.

---

## Quick start

```bash
# 1. Start the database (port 5433)
docker compose up -d

# 2. Configure backend secrets (first time only)
copy backend\.env.example backend\.env   # fill in DB_URL, API keys

# 3. Launch everything interactively
.\scripts\start.ps1
```

Swagger UI: http://localhost:8080/swagger-ui.html  
Frontend:   http://localhost:5173

---

## Architecture

```
frontend/   React 19 + TypeScript + Vite + Tailwind + Recharts
    ↓ HTTP / Axios
backend/    Spring Boot 4 / Java 25
    ├── Controller → Service → Repository   (CRUD + reports)
    └── AiController → AiQueryService → SqlGenerator
                         → SqlGuard  ← SAFETY BOUNDARY
                         → JdbcTemplate
    ↓ JPA
PostgreSQL 17  (Docker local · Supabase prod)
    ↓ AI path only
OpenAI API  or  Anthropic Claude API
```

### Key packages (`com.teng.app.gastosai`)

| Package | Contents |
|---|---|
| `entity/` | `Expense` (BigDecimal amount, LocalDateTime date, description, FK Category), `Category` |
| `dto/` | `ExpenseRequest/Response`, `CategoryRequest/Response`, `AiQueryRequest/Response`, report items |
| `repository/` | JPA repos; JPQL aggregation for monthly + category reports |
| `service/` | Business logic; `CategoryService` auto-creates categories, reassigns to Uncategorized on delete |
| `controller/` | `ExpenseController`, `CategoryController`, `AiController` |
| `ai/` | `SqlGenerator` interface, `OpenAiSqlGenerator`, `ClaudeSqlGenerator`, `SqlGuard` |
| `config/` | `AIClientConfig`, CORS `WebConfig`, properties classes |
| `bootstrap/` | `CategoryDataLoader` (always runs, seeds 13 predefined categories), `AppDataLoader` (sample expenses) |
| `exception/` | `GlobalExceptionHandler` → structured JSON errors |

---

## Non-negotiable rules

1. **SqlGuard is the security boundary.** Never bypass, weaken, or route AI SQL around it.
2. **Generated SQL must be a single SELECT referencing the `expenses` table.** No mutations, no DDL, no system catalogs.
3. **Never expose JPA entities through controllers.** Always use DTOs.
4. **Use the Maven wrapper**, not local Maven: `mvnw.cmd` (Windows) / `./mvnw` (Unix).
5. **Currency is Philippine peso (₱).** All monetary values are `BigDecimal`.

---

## Git, Review, and Release Workflow

Before making repository changes, follow:

* `ai/skills/git-best-practices.md`

When reviewing commits, diffs, or pull requests, follow:

* `ai/skills/commit-pr-review.md`

For branch naming, release branches, prereleases, SemVer, tags, and hotfix guidance, follow:

* `ai/skills/git-branching-release-strategy.md`

For AI SQL-related changes, also follow:

* `ai/skills/ai-sql-safety.md`

---

## Agent skills and resources

### Sub-agents (parallel execution via `.claude/agents/`)

| Agent | Path | Purpose |
|---|---|---|
| `full-stack-planner` | `.claude/agents/full-stack-planner.md` | Read-only; decomposes a feature into backend + frontend tasks with DTO contracts |
| `backend-dev` | `.claude/agents/backend-dev.md` | Implements Spring Boot changes; verifies with compile + tests |
| `frontend-dev` | `.claude/agents/frontend-dev.md` | Implements React/TypeScript changes; verifies with lint + build |
| `pre-pr` | `.claude/agents/pre-pr.md` | Runs the full quality gate before any PR |
| `prompt-compressor` | `.claude/agents/prompt-compressor.md` | Compresses verbose agent prompts to < 800 tokens before spawning sub-agents |
| `resource-finder` | `.claude/agents/resource-finder.md` | Researches and ranks libraries/tools by adoption, security, and community before adding new dependencies |
| `ui-ux-reviewer` | `.claude/agents/ui-ux-reviewer.md` | Reviews UI/UX decisions against best practices for dashboards and data visualization |
| `feature-prioritizer` | `.claude/agents/feature-prioritizer.md` | Scores feature candidates using ICE + revenue multiplier; returns ranked table with top-pick recommendation |
| `tech-workflow` | `.claude/agents/tech-workflow.md` | Engineering process advisor for branching, PR sizing, sprint discipline, and incident response |
| `cleanup` | `.claude/agents/cleanup.md` | Scans for stale/irrelevant files and reports deletion candidates; never deletes without confirmation |
| `agent-auditor` | `.claude/agents/agent-auditor.md` | Audits agent/skill indexes for completeness, overlap, and consolidation; auto-fixes missing registrations |

See `ai/skills/agents.md` for the full parallel workflow.

### Skills (reference documents in `ai/skills/`)

| Skill | Purpose |
|---|---|
| `ai/skills/README.md` | Skill index — reading order by task, non-negotiable rules |
| `ai/skills/agents.md` | Parallel agent workflow — when and how to use sub-agents |
| `ai/skills/project-context.md` | Full domain model, DTO contracts, frontend structure, env variables |
| `ai/skills/environment.md` | Windows/PowerShell setup, default ports, reset procedure, GitHub CLI |
| `ai/skills/java-spring-standards.md` | Java 25 + Spring Boot 4 conventions |
| `ai/skills/feature-builder.md` | How to add a feature end-to-end |
| `ai/skills/testing.md` | Test strategy and commands |
| `ai/skills/backend-review.md` | Backend code review checklist |
| `ai/skills/commit-pr-review.md` | Commit and PR review checklist |
| `ai/skills/ai-sql-safety.md` | SqlGuard rules in detail |
| `ai/skills/git-best-practices.md` | Git safety rules for all repository changes |
| `ai/skills/git-branching-release-strategy.md` | SemVer, branching, releases, hotfixes, tags |
| `ai/skills/deployment.md` | Koyeb / Vercel / Supabase deployment |
| `ai/skills/feature-workflow.md` | Branch → develop → verify → squash-merge workflow |
| `ai/skills/doc-audit.md` | Documentation audit checklist — run to detect stale docs |
| `ai/skills/token-optimization.md` | Token efficiency rules for agent prompts — < 800 tokens per prompt, reference over copy |

### Prompts and templates

| Type | Path | Purpose |
|---|---|---|
| Prompt | `ai/prompts/add-feature.md` | Structured prompt for new features |
| Prompt | `ai/prompts/review-code.md` | Code review prompt |
| Prompt | `ai/prompts/debug.md` | Debug investigation prompt |
| Prompt | `ai/prompts/refactor.md` | Refactor prompt |
| Template | `ai/templates/pr-template.md` | Pull request description |
| Template | `ai/templates/api-design-template.md` | API endpoint design |
| Template | `ai/templates/architecture-decision-template.md` | ADR format |
