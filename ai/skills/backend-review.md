# Skill: Backend Code Review

Checklist and guidance for reviewing gastosai backend changes.

---

## Controller layer

- [ ] Controller is thin — no business logic, only `@Valid`, delegate to service, return DTO
- [ ] Returns DTO, not JPA entity
- [ ] `@ResponseStatus(HttpStatus.CREATED)` on POST endpoints
- [ ] `@ResponseStatus(HttpStatus.NO_CONTENT)` on DELETE endpoints
- [ ] No `@JsonIgnore` on DTO fields — frontend needs IDs

## Service layer

- [ ] Write methods annotated `@Transactional`
- [ ] Read-only methods annotated `@Transactional(readOnly = true)`
- [ ] Business logic lives here, not in controllers or repositories
- [ ] `ResourceNotFoundException` thrown (not `RuntimeException`) for missing entities
- [ ] Categories created through `CategoryService.getOrCreateByName()`, not directly

## Repository layer

- [ ] JPQL used for custom queries, not native SQL (unless unavoidable)
- [ ] Aggregation queries return `List<Object[]>`; cast carefully in service
- [ ] No raw SQL unless justified

## Entity layer

- [ ] Entities are not returned from controllers
- [ ] `@Column(nullable = false)` on required fields matches DTO `@NotNull`/`@NotBlank`
- [ ] `BigDecimal` with `precision = 19, scale = 4` for monetary fields
- [ ] `LocalDateTime` for date/time fields

## DTO layer

- [ ] Records preferred over classes
- [ ] Validation annotations on record components (`@NotBlank`, `@DecimalMin`, etc.)
- [ ] `@Size(max = N)` where DB column has length constraint
- [ ] No JPA annotations on DTOs

## AI path — extra scrutiny

- [ ] Any change near `SqlGuard` is reviewed against `ai/skills/ai-sql-safety.md`
- [ ] `SqlGenerator` implementations pass the full system prompt unchanged
- [ ] No SQL execution path exists that bypasses `SqlGuard.validate()`
- [ ] Error from SqlGuard surfaces as HTTP 400, not 500

## General

- [ ] No secrets or credentials in source files
- [ ] Imports are clean — no unused imports
- [ ] Compiles cleanly: `mvnw.cmd compile`
- [ ] Tests pass: `mvnw.cmd test`
- [ ] Jackson date serialization: `write-dates-as-timestamps=false` is set; LocalDateTime serializes as ISO string
