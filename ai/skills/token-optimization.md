# Skill: Token-Efficient Agent Operation

Rules for minimizing token usage across all agents and the main orchestration thread without sacrificing correctness.

Priority: safety > existing skills/agents > CLAUDE.md > this skill.

---

## Core principle

Find the smallest set of high-signal tokens that maximise the likelihood of the desired outcome. Every token not written is a token saved — but only cut tokens that carry no signal.

---

## System prompt / agent prompt rules

- Target **< 2 000 tokens** per agent prompt. If exceeded, extract repeated context to a shared skill file and reference it by path.
- **Never restate what the target agent can derive itself** — file paths it will Glob/Read, type signatures it will Grep, patterns it will find by looking at existing code.
- **Reference, don't copy.** Instead of pasting 50 lines of existing DTO fields, write: "follow the pattern in `ExpenseResponse.java`."
- One sentence per task. No motivational framing ("This ensures…", "This is important because…").
- No pleasantries, no summaries, no "Done criteria" that just restate the task.
- Use bullet lists for task sequences; prose only when order/causality must be explained.
- **Few-shot beats edge-case lists.** One concrete example is worth five "be careful about X" clauses.

---

## Orchestration-thread rules (main Claude session)

- Read targeted sections, not whole files. Supply `offset` + `limit` to Read when the relevant code is known.
- Grep before Read — confirm the symbol exists at a line before reading the surrounding context.
- Don't scan `node_modules/`, `target/`, `build/`, `dist/`, `.git/`, lock files, generated files.
- No unrelated refactors or file changes while executing a focused task.
- No commits/pushes unless the user explicitly asks.
- If context grows large, remind the user to run `/compact`.

---

## Multi-agent rules

- **Planner first, then parallel agents.** `full-stack-planner` produces the DTO contract and task split; backend-dev + frontend-dev consume it. Do not re-derive in agent prompts what the planner already captured.
- **Lean prompts for parallel agents.** Give each agent: role, branch name, 3–5 bullet tasks, file paths to create/modify, done criteria (compile/lint/test command only). Nothing else.
- **No duplicated verification.** If an agent ran `mvnw test`, do not re-run the same command in the main thread. Trust the agent's reported output; only re-run if the agent reported a failure or was unable to run.
- **Tool search over full tool list.** Agents should use ToolSearch to fetch only the tools they need rather than carrying the full schema.
- **CLI over MCP** where both can accomplish the task — CLI calls cost ~1 k tokens vs ~13 k for equivalent MCP round-trips.

---

## Context compression at handoff

When briefing a sub-agent on a topic already established in the conversation:
1. State the conclusion, not the derivation. ("DTO is `BudgetResponse(id, categoryId, …)` — see planner output.")
2. Give the file path + line range if the agent needs to read existing code.
3. Omit historical context (why we chose X, what failed before) unless it directly constrains the agent's work.

---

## Output format for completed work (all agents and main thread)

```
Files changed: <list>
What changed: <one line per file>
Commands run: <command → result>
Issues / next steps: <if any>
```

Nothing else. No narrative prose.

---

## Benchmark targets (from research)

| Technique | Typical token reduction |
|---|---|
| Caveman-style output (no filler) | ~65% on prose sections |
| CLI over MCP for same task | ~92% (1 k vs 13 k) |
| Reference-not-copy in agent prompts | 40–60% on repeated context |
| ToolSearch (dynamic tool loading) | ~80% on tool schema tokens |
| Adaptive context compression (Acon) | 26–54% for long-horizon agents |

Sources: Anthropic context-engineering guide, Acon paper (arxiv 2510.00615), Active Context Compression paper (arxiv 2601.07190), morphllm.com prompt compression guide.
