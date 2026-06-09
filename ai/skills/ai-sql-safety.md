# Skill: AI SQL Safety

Everything about the `SqlGuard` safety boundary and the rules governing AI-generated SQL.

---

## Why this matters

The AI query path executes raw SQL against the production database. A compromised or malformed query could read sensitive data, modify records, or expose system internals. `SqlGuard` is the only thing standing between user-supplied text and the database.

**This is safety-critical code. Never weaken it, bypass it, or route SQL around it.**

---

## SqlGuard rules (current implementation)

`ai/SqlGuard.java` rejects SQL that:

1. **Contains mutating keywords** — `INSERT`, `UPDATE`, `DELETE`, `DROP`, `TRUNCATE`, `ALTER`, `CREATE`, `REPLACE`, `MERGE`, `UPSERT`
2. **Does not contain `FROM expenses`** (or aliased form) — enforces that queries target the correct table
3. **Contains multiple statements** — splits on `;` and rejects if more than one non-empty statement
4. **Accesses system catalogs** — blocks `pg_`, `information_schema`, `pg_catalog`

---

## SqlGenerator contract

Both `OpenAiSqlGenerator` and `ClaudeSqlGenerator` must:

- Instruct the model via system prompt to return **only** a bare SQL SELECT statement
- Accept optional markdown code fences (` ```sql ... ``` `) and strip them before returning
- Pass the extracted SQL string directly to `SqlGuard.validate()` via `AiQueryService`
- Never execute SQL themselves — only return the string

The system prompt schema is:

```
expenses(id bigint, amount numeric, category_id bigint, date timestamp, description text)
categories(id bigint, name varchar)
```

If the schema changes (new columns, renamed columns), update the system prompt in **both** generators.

---

## What agents must NOT do

- Remove or comment out the `SqlGuard.validate()` call in `AiQueryService`
- Add a flag or parameter that skips validation
- Expand the allowed statement types (e.g., to allow `WITH` CTEs that contain mutations)
- Allow execution of SQL that was not returned by a `SqlGenerator`
- Soften the `FROM expenses` requirement to allow arbitrary table access

---

## Extending SqlGuard safely

If you need to extend what is allowed (e.g., allow CTEs for complex aggregations):

1. Write a failing test first that proves the new SQL is currently rejected
2. Update the rule with the minimal change required
3. Write a test proving the previously-rejected SQL now passes
4. Write tests proving that mutating equivalents are still rejected
5. Get a second review on the change

---

## Error handling

- Valid SQL that fails at the DB level returns HTTP 500 with a generic message — do not leak DB errors to the client
- SQL rejected by SqlGuard returns HTTP 400 with a message indicating why
- `AiQueryService` should not swallow SqlGuard exceptions
