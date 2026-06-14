# ChatGPT Session Starter

Paste this at the start of a ChatGPT session when switching from Claude Code mid-task.
Fill in the bracketed sections before pasting.

---

## Template

```
You are helping me build gastosai — an AI-powered personal expense tracker.

## Stack
- Backend: Spring Boot 4 / Java 25, Maven wrapper (mvnw.cmd on Windows 11)
- Frontend: React 19 + TypeScript + Vite + Tailwind CSS v4 + Recharts
- Database: PostgreSQL 17 (Docker on port 5433 locally; Supabase in prod)
- AI providers: OpenAI or Anthropic Claude, toggled by GASTOS_AI_PROVIDER env var
- Currency: Philippine peso (₱); all money is BigDecimal — never double or float
- OS: Windows 11 — all shell commands must be PowerShell syntax

## Architecture
Request flow: Controller → Service → Repository (JPA)
AI query flow: AiController → AiQueryService → SqlGenerator → SqlGuard → JdbcTemplate

SqlGuard is the security boundary — it blocks all non-SELECT SQL and must never be bypassed.

## Key rules
- Never return JPA entities from controllers — always use DTOs (Java records)
- @Transactional on service write methods; @Transactional(readOnly = true) on reads
- Category creation always goes through CategoryService.getOrCreateByName()
- BigDecimal for all monetary values
- No any types in TypeScript; use unknown for caught errors
- All API types go in frontend/src/api/types.ts
- No comments unless the WHY is non-obvious

## Git / versioning
- Branch naming: feat/<name>, fix/<name>; PRs to master must come from release/x.y.z branch
- Commit format: type(scope): description (conventional commits, no AI attribution lines)
- Version bump: feat → MINOR, fix/perf → PATCH, breaking → MAJOR
- Both backend/pom.xml and frontend/package.json must be bumped together

## Pre-PR checklist (I run these myself)
1. mvnw.cmd compile — zero errors
2. mvnw.cmd test — all green
3. npm run lint — zero warnings
4. npm run build — clean compile
5. Version bumped in pom.xml + package.json
6. CHANGELOG.md updated

## Current task
Branch: [feat/xxx or fix/xxx]
What I was doing: [describe the task]
Progress so far: [what's done]
Blocked on / next step: [what you need help with]

## Files relevant to this task
[Paste content of relevant files here, e.g. the service/controller/component you're working on]
```

---

## Variant: Starting fresh (no in-progress task)

```
You are helping me build gastosai — an AI-powered personal expense tracker.

[Paste the Stack + Architecture + Key rules + Git/versioning sections above]

## What I need
[Describe the feature or bug you want to work on]

## Relevant files
[Paste the files you want reviewed or modified]
```

---

## Tips

- Paste the actual file content directly — ChatGPT cannot read your repo
- One task per session; ChatGPT loses context if the chat gets too long
- After ChatGPT gives you code, run mvnw.cmd compile and mvnw.cmd test yourself before committing
- If ChatGPT suggests bash commands, convert to PowerShell before running (e.g. `./mvnw` → `mvnw.cmd`)
- Resume in Claude Code when tokens reset — it has full memory and can run commands
