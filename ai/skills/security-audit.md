# Skill: Security Audit

Reusable security workflow for gastosai. Run this before every release or when adding new endpoints, auth changes, or AI path changes.

---

## Non-negotiable constraints

- **Never weaken or bypass `SqlGuard`.** See `ai/skills/ai-sql-safety.md`.
- **Never expose secrets, `.env` values, or API keys** in scan outputs, logs, or external tools.
- **Never auto-commit or auto-push** security fixes — report first, fix with user approval.
- **Risky dependency upgrades** (behavior-changing, major version) → explain impact and ask before applying.

---

## Step 1 — Dependency scans

### Frontend
```powershell
Set-Location frontend
npm audit
```
Zero vulnerabilities = pass. Any HIGH/CRITICAL = block release until fixed.

### Backend
```powershell
Set-Location backend
.\mvnw.cmd dependency:check   # requires OWASP plugin in pom.xml (optional)
```
Without OWASP plugin: manually check key versions against Maven Central + NVD:
- JJWT: `io.jsonwebtoken:jjwt-api` — check https://github.com/jwtk/jjwt/releases
- Spring Boot parent: check https://spring.io/blog (release notes)
- commons-csv: check https://commons.apache.org/proper/commons-csv/changes-report.html
- springdoc-openapi: check https://github.com/springdoc/springdoc-openapi/releases

---

## Step 2 — Code review checklist

### Authentication & JWT
- [ ] `JwtUtil.java` uses HMAC-SHA (not `none` algorithm)
- [ ] JWT secret sourced from env var `JWT_SECRET`, not hardcoded
- [ ] Secret length ≥ 32 chars (JJWT enforces this at runtime)
- [ ] `expirationMs` is reasonable (default 86400000 = 24h)
- [ ] `AuthService.login()` returns same error message for wrong email vs wrong password (no enumeration)
- [ ] `BCryptPasswordEncoder` used — no MD5, SHA1, plaintext

### CORS
- [ ] `WebConfig.allowedOriginPatterns` is **not** `"*"` in production
- [ ] Production allowed origins restricted to known frontend URL(s)
- [ ] Fix pattern (env-driven):
  ```java
  .allowedOriginPatterns(System.getenv().getOrDefault("CORS_ALLOWED_ORIGINS", "http://localhost:5173").split(","))
  ```

### Actuator
- [ ] `management.endpoints.web.exposure.include` exposes only needed endpoints (currently `info`)
- [ ] `SecurityConfig` permits only `/actuator/info`, not `/actuator/**`

### Input validation
- [ ] All `@RequestBody` DTOs have `@Valid` at controller level
- [ ] `RegisterRequest.password` has `@Size(min=6)` — consider adding `max=72` (BCrypt limit)
- [ ] `AiQueryRequest.question` has `@Size(max=2000)` ✓
- [ ] File uploads: content type validated against allowlist before processing

### AI / Vision path
- [ ] `VisionService.analyze()` validates `file.getContentType()` against `ALLOWED_MEDIA_TYPES`
- [ ] File size bounded by `spring.servlet.multipart.max-file-size` (currently 10MB)
- [ ] AI response parsed with Jackson — no `eval()` or dynamic code execution
- [ ] Vision prompt does not include user-supplied text without sanitization check

### SqlGuard (must not change)
- [ ] `SqlGuard.validateAndNormalize()` called by `AiQueryService` before every query execution
- [ ] UNION, INTERSECT, EXCEPT blocked ✓
- [ ] System catalogs (`pg_`, `information_schema`) blocked ✓
- [ ] Multi-statement (`;`) blocked ✓
- [ ] Non-SELECT rejected ✓
- [ ] `FROM expenses` required ✓

### Secrets & config
- [ ] No API keys, passwords, or tokens in source files
- [ ] `.env` files in `.gitignore`
- [ ] `application.properties` defaults use env var placeholders (`${VAR:default}`)
- [ ] JWT secret default is clearly marked "change in production" in comments
- [ ] `gastos.seed-sample-data=false` set in production (prevents weak demo account creation)

### Error handling
- [ ] `GlobalExceptionHandler` catches `DataAccessException` — returns generic message, not DB details ✓
- [ ] SqlGuard rejections return HTTP 400 (not 500)
- [ ] Stack traces not returned to clients

### Security headers
- [ ] Spring Security default headers active (no `.headers().disable()` call) — ensures `X-Content-Type-Options: nosniff`, `X-Frame-Options: DENY` by default

---

## Step 3 — Severity tags

| Tag | Meaning |
|-----|---------|
| 🔴 HIGH | Exploitable with low effort; block release |
| 🟡 MED | Real risk; fix before production deployment |
| 🟢 LOW | Hardening / defense-in-depth; fix in normal sprint |
| ℹ️ INFO | Note only; no code change required |
| ✅ PASS | Verified secure |

---

## Step 4 — Fix policy

| Finding | Action |
|---------|--------|
| Known CVE in npm/Maven dep | Upgrade if semver-minor safe; else ask |
| Wildcard CORS in prod | Add env-driven origin list (see pattern above) |
| Hardcoded secret fallback | Add startup validation or remove default |
| Missing input validation | Add `@Size` / `@NotNull` annotation |
| Actuator wildcard | Narrow to specific endpoints in SecurityConfig |
| SqlGuard weakness | Stop — get second review before any change |

---

## Step 5 — What to report

After each scan, produce a table:

```
| Finding | File | Severity | Status | Notes |
|---------|------|----------|--------|-------|
```

End the report with:
- List of fixes applied (with file + line)
- List of findings NOT fixed and why
- Recommended follow-up actions
