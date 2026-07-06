# Skill: PR Review Flow (two-agent, main-thread orchestrated)

After a PR is opened, run a two-stage automated review and notify the user on
Telegram with a merge verdict. Two sub-agents do the work; **the main thread
wires them** because sub-agents cannot spawn other sub-agents.

Read first: `commit-pr-review.md` (review checklist), `git-branching-release-strategy.md`
(two-PR flow + version rules), `e2e-release-verification.md` (Telegram delivery pattern).

---

## When to run

Immediately after `scripts/gh.ps1 pr create ...` succeeds — before handing the
branch to the user to merge. Applies to every PR type (`feat`/`fix` → `release/*`,
and `meta/*` → `master`).

## The flow

```
scripts/gh.ps1 pr create ...            (main thread opens PR, captures the URL + number)
        |
        v
1. spawn  pr-reviewer  (Agent tool, subagent_type: pr-reviewer)
        input:  PR number + base/head branches
        output: severity-tagged finding list
        |
        v
2. spawn  pr-review-auditor  (Agent tool, subagent_type: pr-review-auditor)
        input:  the pr-reviewer output (paste it in) + PR number
        output: VERDICT (APPROVE / CHANGES-NEEDED / BLOCK) + audit table
        action: sends Telegram card via scripts/notify-telegram.ps1 (includes PR URL)
        |
        v
3. main thread relays the verdict to the user and, if CHANGES-NEEDED/BLOCK,
   addresses the material findings (or routes to backend-dev/frontend-dev), then
   re-runs from step 1 on the updated PR.
```

## Rules

- **Main thread orchestrates.** Spawn `pr-reviewer` first; wait for it; then spawn
  `pr-review-auditor` with the reviewer's text pasted into its prompt. Do not ask
  either agent to spawn the other.
- **Read-only agents.** Neither agent edits, commits, or pushes. Fixes are applied
  by the main thread or the dev agents, never by the reviewers.
- **Never weaken SqlGuard.** Both agents flag SqlGuard / tenant-isolation changes
  as needing paired human review (see `ai-sql-safety.md`).
- **Telegram sanitized.** The auditor sends plain text (no `_`/`*`) and always
  includes the full PR URL. Script exit 2 = Telegram not configured → report, don't fail.
- **This does not replace `pre-pr`.** `pre-pr` runs the build/lint/test/version gate
  before the PR is opened; this flow is static review + a second-opinion audit after.

## Not in CI

This is an in-session flow (e.g. during the autonomous loop), not a GitHub Action.
A CI-native automated review would need the Anthropic API + a repo secret and is
tracked separately if/when the user wants full automation.
