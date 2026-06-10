# Skill: Git Branching and Release Strategy (Shared)

General SemVer, branching, and release strategy applicable to any project.

---

## Strategy

Prefer a simple trunk-based workflow with short-lived branches.

Default long-lived branch: `main` (or `master`).

Optional: `release/<major>.<minor>.x` when stabilizing a release line.

Avoid long-lived `develop` branches unless the project explicitly uses GitFlow.

---

## Branch naming

| Prefix | When to use |
|---|---|
| `feat/` | New user-visible functionality |
| `fix/` | Bug fix |
| `refactor/` | Internal restructuring, no behavior change |
| `docs/` | Documentation only |
| `chore/` | Build, tooling, dependency updates |
| `ci/` | CI/CD changes |
| `hotfix/` | Urgent production fix |
| `release/<x>.<y>.x` | Stabilisation branch for a release line |

All names: lowercase kebab-case, short, descriptive.

---

## Semantic Versioning

References: [SemVer 2.0.0](https://semver.org/) · [Conventional Commits 1.0.0](https://www.conventionalcommits.org/en/v1.0.0/) · [Keep a Changelog 1.1.0](https://keepachangelog.com/en/1.1.0/) · [semantic-release](https://github.com/semantic-release/semantic-release)

```
MAJOR.MINOR.PATCH
Pre-release:    1.2.0-alpha.1 / 1.2.0-beta.1 / 1.2.0-rc.1
Build metadata: 1.2.0+build.sha  (informational only; ignored by precedence)
```

| Change | Bump |
|---|---|
| Breaking / incompatible API or behavior change | MAJOR |
| Backward-compatible new feature | MINOR |
| Backward-compatible bug fix | PATCH |

---

## Conventional commits → version bump

| Commit type | Bump |
|---|---|
| `fix:`, `perf:` | PATCH |
| `feat:` | MINOR |
| Any type with `!` (e.g. `feat!:`, `fix!:`) or `BREAKING CHANGE:` footer | MAJOR |
| `docs:`, `style:`, `refactor:`, `test:`, `chore:`, `build:`, `ci:`, `revert:` | None |

Notes:
- `perf:` → PATCH unless behaviorally incompatible (then MAJOR).
- `refactor:` → no bump unless it changes user-facing behavior.
- If uncertain whether a change is breaking, **explain the risk and ask before choosing the version.**

**Breaking change** = removes/renames an existing endpoint or field, changes request/response shape or HTTP status codes, renames a public env var or CLI flag, drops runtime version support. Adding new endpoints, fields, env vars, or DB tables is `feat:`, not a breaking change.

## Release decision process

Before bumping, inspect commits since the last release tag:

1. Any breaking change → MAJOR
2. Else any `feat:` → MINOR
3. Else any `fix:` / `perf:` / security patch → PATCH
4. Else no bump

Never downgrade. Never skip versions. Do not call a breaking change a patch or minor.

## Release preparation output

Produce this output and **wait for explicit approval** before committing, tagging, pushing, or publishing. Do not push tags unless explicitly asked.

```
- Current version:
- Latest tag:
- Recommended bump:
- Reason:
- Proposed next version:
- Changelog entry:
- Files to change:
- Commands to run:
```

---

## Prerelease versions

```
1.2.0-alpha.1   early internal testing
1.2.0-beta.1    feature-complete, broader testing
1.2.0-rc.1      release candidate; only fixes after this
1.2.0           stable release
```

Do not treat prerelease versions as stable production releases.

---

## Git tags

Use annotated tags for stable releases:

```bash
git tag -a v1.2.0 -m "Release v1.2.0"
git push origin v1.2.0
```

- Prefix tags with `v`.
- Tag only commits that pass all checks.
- Do not move existing release tags.
- Do not create tags automatically unless explicitly requested.

---

## CHANGELOG

Every release must have an entry in `CHANGELOG.md` following [Keep a Changelog](https://keepachangelog.com/en/1.1.0/):

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

- Keep an `[Unreleased]` section at the top.
- Move its contents to a versioned section when releasing.
- Write entries from the user/operator perspective, not the developer's.
- `Security` entries are highest priority — list them first.
- Omit noisy internal changes unless they affect users, developers, deployment, APIs, config, security, or behavior.

---

## Hotfix flow

1. Fix on `main` with a regression test.
2. Verify CI passes.
3. Cherry-pick to active release branch if needed.
4. Tag a patch release.

---

## Dependency management

### npm

```bash
npm audit --audit-level=high   # fail on high/critical
npm outdated
```

High or critical vulnerabilities are **release blockers**.

### Maven

```bash
./mvnw versions:display-dependency-updates
./mvnw dependency:tree
```

BOM-managed versions update together with the parent POM — do not override them individually.

---

## Release readiness checklist

- [ ] Working tree is clean
- [ ] All relevant tests pass
- [ ] Frontend build and lint pass (if frontend changed)
- [ ] Backend tests pass (if backend changed)
- [ ] No secrets committed
- [ ] Version bump is justified by commit type
- [ ] CHANGELOG updated
- [ ] Deployment configuration verified
