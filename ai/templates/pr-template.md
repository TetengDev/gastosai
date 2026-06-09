# PR Template

Copy this into the pull request description when opening a PR for gastosai.

---

## Summary

<!-- 2-3 bullet points describing what changed and why -->

-
-

## Type of change

- [ ] Bug fix
- [ ] New feature
- [ ] Refactor (no behavior change)
- [ ] Documentation
- [ ] Dependency update
- [ ] Infrastructure / CI

## Changes

### Backend
<!-- List backend files changed and what changed in each -->

### Frontend
<!-- List frontend files changed and what changed in each -->

### Infrastructure / Config
<!-- Dockerfile, CI, env vars, scripts -->

## Testing

- [ ] `mvnw.cmd test` passes locally
- [ ] New behavior covered by a test (or explain why not)
- [ ] Swagger UI verified: http://localhost:8080/swagger-ui.html
- [ ] Frontend dev server verified: http://localhost:5173

## AI path changes

- [ ] This PR does NOT touch the AI query path
- [ ] This PR DOES touch the AI path — SqlGuard rules reviewed and unchanged/extended safely

## Checklist

- [ ] No secrets committed
- [ ] No JPA entities returned from controllers
- [ ] BigDecimal used for all monetary values
- [ ] Commits are atomic and follow `type: description` convention
- [ ] AGENTS.md / CLAUDE.md updated if architecture changed

## Screenshots (if frontend change)

<!-- Before / After if applicable -->
