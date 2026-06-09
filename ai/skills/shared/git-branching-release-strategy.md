# Skill: Git Branching and Release Strategy (Shared)

General SemVer, branching, and release strategy applicable to any project.

---

## Strategy

Prefer a simple trunk-based workflow with short-lived branches.

Default long-lived branch: `main` (or `master`).

Optional: `release/<major>.<minor>.x` when stabilising a release line.

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

```
MAJOR.MINOR.PATCH
```

| Change | Bump |
|---|---|
| Breaking / incompatible | MAJOR |
| Backward-compatible new feature | MINOR |
| Backward-compatible bug fix | PATCH |

For pre-1.0 projects (`0.x.y`), use MINOR for features and PATCH for fixes.

---

## Conventional commits → version bump

| Prefix | Bump |
|---|---|
| `fix:`, `perf:` | PATCH |
| `feat:` | MINOR |
| `feat!:`, `fix!:`, `BREAKING CHANGE:` | MAJOR (MINOR if pre-1.0) |
| `docs:`, `test:`, `chore:`, `refactor:`, `ci:` | No bump |

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
### Fixed
### Security
```

- Keep an `[Unreleased]` section at the top.
- Move its contents to a versioned section when releasing.
- Write entries from the user/operator perspective, not the developer's.
- `Security` entries are highest priority — list them first.

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
