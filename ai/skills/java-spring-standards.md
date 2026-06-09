# Skill: Java + Spring Boot Standards

Conventions for Java 25 and Spring Boot 4 code in gastosai.

---

## Java 25 features in use

| Feature | Usage |
|---|---|
| Records | All DTOs (`ExpenseRequest`, `ExpenseResponse`, etc.) |
| Text blocks (`"""`) | JPQL queries in repositories, AI system prompts |
| Pattern matching (`instanceof`) | Type-narrowing in service helpers |
| `var` | Local variable type inference where type is obvious |
| Sealed classes | Not yet used; candidate for `SqlGuard` result types |

---

## Lombok

Entities use Lombok — do not write boilerplate manually:

```java
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class Expense { ... }
```

Services use `@RequiredArgsConstructor` for constructor injection:

```java
@Service
@RequiredArgsConstructor
public class ExpenseService {
    private final ExpenseRepository expenseRepository;
    private final CategoryService categoryService;
}
```

Do not use `@Autowired` field injection.

---

## Money / BigDecimal rules

- **Store**: `@Column(precision = 19, scale = 4)` — 4 decimal places in DB
- **Display**: `amount.setScale(2, RoundingMode.HALF_UP)` before returning in DTO
- **Never** use `double` or `float` for monetary values
- Frontend receives and displays `₱` (Philippine peso)

---

## Date / time

- Use `LocalDateTime` for expense timestamps (stored as `timestamp` in PostgreSQL)
- Jackson serializes as ISO-8601 strings (`write-dates-as-timestamps=false` is configured)
- Frontend uses `datetime-local` input; value format `YYYY-MM-DDTHH:mm`
- Hibernate time zone: UTC (`spring.jpa.properties.hibernate.jdbc.time_zone=UTC`)

---

## Transactions

```java
@Transactional                          // write operations
@Transactional(readOnly = true)         // queries — enables Hibernate read optimizations
```

- Annotate at the **service** level, not controller or repository
- Do not annotate entire classes `@Transactional` — annotate individual methods
- Integration tests annotated `@Transactional` roll back automatically

---

## Exception handling

`GlobalExceptionHandler` (`@ControllerAdvice`) handles:

- `ResourceNotFoundException` → 404 with structured JSON
- `MethodArgumentNotValidException` → 400 with field errors
- `IllegalArgumentException` → 400
- `IllegalStateException` → 409 (conflict) or 500 depending on context

Throw the right exception type from services. Do not catch and swallow `ResourceNotFoundException`.

---

## RestClient (outbound HTTP)

Use Spring 6 `RestClient`, not deprecated `RestTemplate`:

```java
String response = restClient.post()
    .uri("/v1/chat/completions")
    .contentType(MediaType.APPLICATION_JSON)
    .body(requestBody)
    .retrieve()
    .body(String.class);
```

---

## CORS

`WebConfig` currently allows all origins (`*`). Before going to production, restrict to the Vercel deployment URL.

---

## Flyway

Flyway is on the classpath and enabled. There are no migration files yet. When the project moves to `validate` DDL mode (production), add Flyway migrations in `backend/src/main/resources/db/migration/`.
