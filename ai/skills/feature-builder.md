# Skill: Feature Builder

How to add a new backend + frontend feature to gastosai end-to-end.

---

## Backend — vertical slice order

Build top-down: entity → repository → service → controller → DTO.

### 1. Entity (if new table)

```java
@Entity @Table(name = "my_table")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class MyEntity {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private String name;
}
```

### 2. Repository

```java
public interface MyEntityRepository extends JpaRepository<MyEntity, Long> {
    // Add derived queries or @Query JPQL here
}
```

### 3. DTOs

Prefer records. Put validation on request components:

```java
public record MyEntityRequest(@NotBlank @Size(max = 100) String name) {}
public record MyEntityResponse(Long id, String name) {}
```

### 4. Service

```java
@Service
@RequiredArgsConstructor
public class MyEntityService {
    private final MyEntityRepository repo;

    @Transactional
    public MyEntityResponse create(MyEntityRequest req) { ... }

    @Transactional(readOnly = true)
    public List<MyEntityResponse> findAll() { ... }

    @Transactional
    public MyEntityResponse update(Long id, MyEntityRequest req) { ... }

    @Transactional
    public void delete(Long id) { ... }
}
```

### 5. Controller

```java
@RestController
@RequestMapping("/my-entities")
@RequiredArgsConstructor
public class MyEntityController {
    private final MyEntityService service;

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public MyEntityResponse create(@Valid @RequestBody MyEntityRequest req) {
        return service.create(req);
    }
    // GET list, GET /{id}, PUT /{id}, DELETE /{id}
}
```

---

## Category-aware features

Any feature that creates or references expenses must use `CategoryService.getOrCreateByName()` — never save a `Category` entity directly from another service.

---

## Frontend — adding a page

1. **Add types** to `frontend/src/api/types.ts`
2. **Add API functions** to `frontend/src/api/<entity>.ts` using the shared Axios client
3. **Create page** at `frontend/src/pages/MyPage.tsx`
4. **Register route** in `frontend/src/App.tsx`
5. **Add nav link** in `frontend/src/components/Navbar.tsx`

### Minimal page pattern

```tsx
import { useCallback, useEffect, useState } from "react";
import { getMyEntities } from "../api/myEntity";
import type { MyEntity } from "../api/types";

export default function MyPage() {
  const [items, setItems] = useState<MyEntity[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const load = useCallback(async () => {
    setLoading(true);
    try { setItems(await getMyEntities()); }
    catch { setError("Failed to load."); }
    finally { setLoading(false); }
  }, []);

  useEffect(() => { load(); }, [load]);

  if (loading) return <div className="flex justify-center py-20 text-gray-400">Loading...</div>;
  if (error) return <p className="text-red-500 text-center py-8">{error}</p>;

  return ( /* ... */ );
}
```

---

## Checklist before opening a PR

Run the full pre-PR checklist from `ai/skills/shared/pre-pr-checklist.md`. Additionally for this project:

- [ ] New endpoint appears in Swagger: http://localhost:8080/swagger-ui.html
- [ ] `.\mvnw.cmd test` passes (from `backend/`)
- [ ] `npm run lint` passes with 0 errors (from `frontend/`)
- [ ] `npm run build` compiles clean (from `frontend/`)
- [ ] No `any` types introduced in TypeScript
- [ ] No entity returned directly from a controller
- [ ] Version bumped in `backend/pom.xml` and `frontend/package.json` if required
