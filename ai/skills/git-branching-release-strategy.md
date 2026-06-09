# Skill: Git Branching and Release Strategy

Use this skill when deciding branch names, branch flow, release branches, prerelease versions, stable releases, hotfixes, tags, changelog entries, or version bump recommendations.

This skill complements:

* `ai/skills/git-best-practices.md`
* `ai/skills/commit-pr-review.md`
* `ai/skills/ai-sql-safety.md`

---

## Strategy preference

Prefer a simple trunk-based workflow with short-lived branches.

Default long-lived branches:

```text
main
```

Optional long-lived branches only when needed:

```text
release/<major>.<minor>.x
```

Avoid long-lived `develop` unless the project explicitly chooses GitFlow.

Why:

* `main` should stay releasable.
* Feature branches should be short-lived.
* Release branches should exist only to stabilize or patch a release line.
* Hotfixes should be fixed on `main` first, then cherry-picked to active release branches when needed.

---

## Branch types

See `ai/skills/git-best-practices.md` for general branching rules. Branch name conventions specific to releases:

```text
release/<major>.<minor>.x   — stabilisation branch for a release line
hotfix/<short-description>  — urgent production fix off main
```

All other types (`feature/`, `fix/`, `docs/`, `refactor/`, `test/`, `chore/`, `ci/`) follow the same pattern — lowercase kebab-case, short, descriptive.

Rules:

* Delete merged short-lived branches after merge.
* Do not delete release branches without explicit approval.

---

## Semantic Versioning

Use Semantic Versioning:

```text
MAJOR.MINOR.PATCH
```

Version bump rules:

```text
MAJOR: breaking changes
MINOR: backward-compatible features
PATCH: backward-compatible bug fixes
```

Examples:

```text
1.4.2 -> 1.4.3  patch fix
1.4.2 -> 1.5.0  new backward-compatible feature
1.4.2 -> 2.0.0  breaking change
```

For pre-1.0 projects:

```text
0.MINOR.PATCH
```

Rules:

* `0.x.y` means the API may still be unstable.
* Use minor bumps for meaningful feature/API changes.
* Use patch bumps for fixes.
* Be extra clear in release notes when behavior changes.

---

## Prerelease versions

Use prerelease versions for testing/staging/release candidates:

```text
1.2.0-alpha.1
1.2.0-beta.1
1.2.0-rc.1
```

Recommended meaning:

```text
alpha: early internal testing; unstable
beta: feature-complete enough for broader testing
rc: release candidate; only fixes should follow
```

Progression example:

```text
1.2.0-alpha.1
1.2.0-alpha.2
1.2.0-beta.1
1.2.0-rc.1
1.2.0
```

Rules:

* Do not release stable `1.2.0` until the matching release candidate is accepted.
* After `rc`, avoid new features unless restarting prerelease.
* Prerelease versions must not be treated as stable production releases unless explicitly approved.
* Use prereleases for risky AI SQL behavior changes, schema changes, or deployment pipeline changes.

---

## Build metadata

Build metadata may be used for traceability:

```text
1.2.0+build.5
1.2.0+20260609
1.2.0+sha.abc1234
1.2.0-rc.1+sha.abc1234
```

Rules:

* Build metadata does not change version precedence.
* Use it only for build traceability.
* Do not use build metadata to represent feature or bugfix differences.

---

## Git tags

Use version tags for releases:

```text
v1.2.0
v1.2.0-rc.1
v1.2.0-beta.1
```

Rules:

* Prefix tags with `v`.
* Tag only commits that pass relevant checks.
* Prefer annotated tags for stable releases.
* Do not create tags automatically unless explicitly requested.
* Do not move existing release tags unless explicitly approved and clearly justified.
* Do not tag dirty working trees.
* Stable tags should point to commits intended for production release.

Suggested stable tag command:

```bash
git tag -a v1.2.0 -m "Release v1.2.0"
```

Suggested prerelease tag command:

```bash
git tag -a v1.2.0-rc.1 -m "Release candidate v1.2.0-rc.1"
```

Push tags only when explicitly requested:

```bash
git push origin v1.2.0
```

---

## Release branches

Use release branches when stabilizing or maintaining a release line:

```text
release/1.2.x
```

Create from `main` when preparing a release:

```bash
git checkout main
git pull
git checkout -b release/1.2.x
```

Rules:

* Only bug fixes, documentation corrections, release config, and stabilization changes should go into release branches.
* No unrelated features.
* Keep CI passing.
* Merge or cherry-pick fixes back to `main` as needed.
* Prefer fixing bugs on `main` first, then cherry-picking to the release branch.

---

## Hotfixes

Use hotfixes for urgent production fixes.

Branch name:

```text
hotfix/<short-description>
```

Preferred flow:

1. Reproduce the bug.
2. Fix on `main` with a test.
3. Verify CI/tests.
4. Cherry-pick to active release branch if needed.
5. Tag a patch release.

Example:

```text
main
  -> hotfix/ai-query-error-leak
  -> merge to main
  -> cherry-pick to release/1.2.x
  -> tag v1.2.1
```

Rules:

* Hotfixes should be minimal.
* Avoid refactoring during hotfixes.
* Add regression tests when possible.
* Patch version should usually increase.

---

## Conventional commits and version bump mapping

Use conventional commits to recommend version bumps.

Mapping:

```text
fix:       PATCH
perf:      PATCH
feat:      MINOR
refactor:  no release bump unless behavior changes
docs:      no release bump unless documentation-only release is desired
test:      no release bump
chore:     no release bump unless release/tooling behavior changes
ci:        no release bump unless deployment behavior changes
```

Breaking changes:

```text
feat!: change expense API response
fix!: remove legacy category field
```

or footer:

```text
BREAKING CHANGE: removes the old category response shape.
```

Breaking changes require a MAJOR bump once the project is stable at `1.0.0+`.

---

## CHANGELOG

Every release must have a corresponding entry in `CHANGELOG.md` following [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

Structure:

```markdown
## [Unreleased]

## [1.2.0] - YYYY-MM-DD
### Added
### Changed
### Deprecated
### Removed
### Fixed
### Security
```

Rules:

* Keep an `[Unreleased]` section at the top. Move its contents to a versioned section when releasing.
* Write entries for the reader, not the developer — describe what changed from a user or operator perspective.
* `Security` entries are highest priority — list them first in the section.
* Every version bump commit must also update `CHANGELOG.md`. The `commit-msg` hook reminds you of this.
* Do not document internal refactors or test-only changes unless they affect observable behavior.

---

## Dependency management

Outdated or vulnerable dependencies must be reviewed before each release.

### Frontend (npm)

```bash
npm audit                          # show vulnerabilities
npm audit --audit-level=high       # fail on high/critical (used in CI)
npm outdated                       # show available updates
```

Rules:

* High or critical vulnerabilities are **release blockers**. Patch them before tagging.
* Moderate vulnerabilities should be tracked and resolved within the next minor release.
* Minor version upgrades are generally safe — test after updating.
* Major version upgrades require a dedicated branch and regression testing.
* `npm audit fix` applies safe automatic fixes; `npm audit fix --force` may introduce breaking changes — use cautiously.

### Backend (Maven)

```bash
./mvnw versions:display-dependency-updates   # show available updates
./mvnw dependency:tree                       # inspect transitive dependencies
```

Rules:

* Direct dependency updates should be reviewed individually.
* BOM-managed versions (Spring Boot parent POM) update together when upgrading Spring Boot — do not override them individually.
* Dependabot (`.github/dependabot.yml`) raises weekly PRs for both Maven and npm — review and merge regularly.
* For explicit vulnerability scanning, consider adding the OWASP Dependency-Check Maven plugin if the project grows.

---

## Release readiness checklist

Before recommending a stable release:

* Working tree is clean
* Correct branch is checked out
* Relevant tests pass
* Frontend build/lint pass if frontend changed
* Backend tests pass if backend changed
* No secrets committed
* Version bump is justified
* Changelog or release notes are prepared
* Deployment configuration is verified
* AI SQL safety-sensitive changes are reviewed carefully
* No unstable prerelease-only work remains

---

## AI SQL release caution

If the release includes changes to:

* `SqlGuard`
* `AiQueryService`
* `SqlGenerator`
* OpenAI or Claude SQL prompts
* AI query execution flow
* Database access rules

Then also follow:

```text
ai/skills/ai-sql-safety.md
```

Rules:

* Prefer prerelease first.
* Require tests for unsafe SQL rejection.
* Do not weaken `SqlGuard`.
* Do not release if the AI SQL path can bypass validation.

---

## Output format

When asked for branching or release guidance, respond with:

```text
Recommended branch:
Reason:
Version bump:
Release type:
Suggested tag:
Prerelease needed:
Checks before merge/release:
Risks:
Suggested commands:
```

Do not run commands that create branches, tags, releases, or pushes unless explicitly requested.
