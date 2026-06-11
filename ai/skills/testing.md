# Skill: Testing

Test strategy, commands, and patterns for gastosai.

---

## Test stack

| Layer | Technology | DB |
|---|---|---|
| Integration | Spring Boot Test + MockMvc | H2 in-memory |
| Unit | JUnit 5 + Mockito | None (mocked) |

H2 is configured to replace PostgreSQL for all tests. The schema is created via Hibernate `create-drop` on each test run — no test data leaks between runs.

---

## Commands

```bash
# From backend/ directory
mvnw.cmd test                           # all tests
mvnw.cmd test -Dtest=ExpenseApiIntegrationTest       # single class
mvnw.cmd test -Dtest=SqlGuardTest       # single class
mvnw.cmd test -pl backend               # from repo root
```

---

## Writing integration tests

Use `@SpringBootTest` + `@AutoConfigureMockMvc` for full-stack tests:

```java
@SpringBootTest
@AutoConfigureMockMvc
@Transactional
class MyFeatureIntegrationTest {

    @Autowired MockMvc mvc;
    @Autowired ObjectMapper mapper;

    @Test
    void createExpense_returnsCreated() throws Exception {
        var req = new ExpenseRequest(
            new BigDecimal("100.00"), "Meal Plan",
            LocalDateTime.now(), "Lunch"
        );

        mvc.perform(post("/expenses")
                .contentType(MediaType.APPLICATION_JSON)
                .content(mapper.writeValueAsString(req)))
            .andExpect(status().isCreated())
            .andExpect(jsonPath("$.id").isNumber())
            .andExpect(jsonPath("$.description").value("Lunch"));
    }
}
```

`@Transactional` on the test class rolls back after each test method.

---

## Writing unit tests

For service logic that doesn't need the full Spring context:

```java
@ExtendWith(MockitoExtension.class)
class ExpenseServiceTest {

    @Mock ExpenseRepository expenseRepository;
    @Mock CategoryService categoryService;
    @InjectMocks ExpenseService expenseService;

    @Test
    void create_defaultsToUncategorized_whenCategoryBlank() {
        // given
        when(categoryService.getOrCreateByName("Uncategorized"))
            .thenReturn(Category.builder().name("Uncategorized").build());
        when(expenseRepository.save(any())).thenAnswer(i -> i.getArgument(0));

        var req = new ExpenseRequest(new BigDecimal("50"), "", null, "Test");

        // when / then — no exception, category resolved to Uncategorized
        assertDoesNotThrow(() -> expenseService.create(req));
    }
}
```

---

## SqlGuard tests

`SqlGuard` has its own unit tests. When adding new safety rules, add a corresponding test that proves the bad SQL is rejected:

```java
@Test
void rejectsInsert() {
    assertThrows(IllegalArgumentException.class,
        () -> SqlGuard.validate("INSERT INTO expenses VALUES (1)"));
}
```

---

## Test data / fixtures

Pre-made files (CSV, JSON, images) for use in tests live in two standard locations:

### Backend

```
backend/src/test/resources/testdata/
  csv/       ← CSV import files, bulk data samples
  images/    ← image upload test files
  json/      ← request/response fixtures, mock payloads
```

Access in JUnit:
```java
InputStream csv = getClass().getResourceAsStream("/testdata/csv/expenses.csv");
URL jsonFile = getClass().getResource("/testdata/json/expense_list.json");
```

### Frontend

```
frontend/src/__tests__/fixtures/
  csv/       ← parsed CSV fixtures
  images/    ← image file fixtures
  json/      ← mock API response fixtures
```

Access in Vitest:
```typescript
import sampleData from '../__tests__/fixtures/json/expenses.json';
// or use fetch/fs mocks pointing to the fixtures path
```

Each subdirectory contains a `.gitkeep` to track the empty directory in git. Remove it once real files are added.

---

## What not to do

- Do not mock the database — use H2 for integration tests. Mock-vs-real divergence has caused issues before.
- Do not write tests that depend on sample seed data being present. Seed state is not guaranteed in tests.
- Do not use `Thread.sleep()` in tests. If you need to wait for async behavior, restructure the code to be synchronous in test scope.
