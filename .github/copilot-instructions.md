# Copilot Instructions

GitHub Copilot guidance for the gastosai repository. Read `AGENTS.md` first — this file adds Copilot-specific conventions on top of it.

---

## Project snapshot

- **Backend**: Spring Boot 4 / Java 25, Maven wrapper (`mvnw.cmd` on Windows)
- **Frontend**: React 19 + TypeScript + Vite + Tailwind CSS v4 + Recharts
- **Database**: PostgreSQL 17 (Docker local on port 5433; Supabase in prod)
- **AI providers**: OpenAI or Anthropic Claude, toggled by `GASTOS_AI_PROVIDER`
- **Currency**: Philippine peso (₱); all money is `BigDecimal`

---

## Completion preferences

### Java / Spring Boot

- Prefer Java **records** for DTOs (`ExpenseRequest`, `ExpenseResponse`, etc.)
- Use **Lombok** (`@Builder`, `@Getter`, `@Setter`, `@RequiredArgsConstructor`) on entities and services — already on the classpath
- Use `@Transactional` on service write methods; `@Transactional(readOnly = true)` on reads
- Use `BigDecimal` for all monetary fields — never `double` or `float`
- Use `LocalDateTime` for expense date fields
- Validation annotations go on the DTO record components (`@NotBlank`, `@NotNull`, `@DecimalMin`, etc.)
- Do **not** annotate DTO fields with `@JsonIgnore` — the frontend needs all IDs
- Use `RestClient` (Spring 6) for outbound HTTP, not `RestTemplate`

### Controller → Service → Repository pattern

```
@RestController  →  @Service  →  JpaRepository
```

- Controllers are thin: validate input, call service, return DTO
- Services own `@Transactional` and business logic
- Repositories use JPQL (not native SQL) for queries

### AI query path — safety critical

```
AiController → AiQueryService → SqlGenerator → SqlGuard → JdbcTemplate
```

- `SqlGuard` must run before any AI SQL is executed — never skip it
- `SqlGenerator` implementations must instruct the model to return **only** a bare `SELECT`
- Do not suggest changes that loosen `SqlGuard` validation rules

### Bootstrap / seeding

- `CategoryDataLoader` seeds 13 predefined categories on **every** startup (`@Order(-1)`)
- `AppDataLoader` seeds sample expenses only when `gastos.seed-sample-data=true` and the table is empty
- Do not hardcode category names outside `CategoryDataLoader.PREDEFINED_CATEGORIES`

---

### TypeScript / React

- All API types live in `frontend/src/api/types.ts` — add new interfaces there
- API calls go through files in `frontend/src/api/` using the shared Axios instance (`api/client.ts`)
- Use `useCallback` for functions passed to `useEffect` to avoid re-renders
- Prefer `async/await` over `.then()` chains in event handlers
- Tailwind v4: use `@import "tailwindcss"` in CSS — no `tailwind.config.js`
- No `any` types; use `unknown` for caught errors and narrow with type guards

---

## What Copilot should NOT suggest

- Bypassing or removing `SqlGuard` validation
- Returning JPA entity objects directly from controllers
- Using `@JsonIgnore` on DTO ID fields
- Using `RestTemplate` (prefer `RestClient`)
- Using `double` or `float` for monetary values
- Committing `.env` files or API keys
- Adding `temperature` parameter to gpt-5.5 API calls (not supported)
