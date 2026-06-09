# API Design Template

Use this template when designing a new endpoint or resource before implementing it.

---

## Resource: `<ResourceName>`

**Base path**: `/resource-name`

---

## Endpoints

### `POST /resource-name`

**Purpose**: Create a new `<ResourceName>`

**Request body**:
```json
{
  "field1": "string (required, max 50)",
  "field2": 0.00
}
```

**Response `201 Created`**:
```json
{
  "id": 1,
  "field1": "string",
  "field2": 0.00
}
```

**Errors**:
| Status | Condition |
|---|---|
| 400 | Validation failure (missing required field, out of range) |
| 409 | Duplicate (if uniqueness applies) |

---

### `GET /resource-name`

**Purpose**: List all `<ResourceName>` records

**Response `200 OK`**: array of response objects (see above)

---

### `GET /resource-name/{id}`

**Response `200 OK`**: single response object  
**Errors**: `404` if not found

---

### `PUT /resource-name/{id}`

**Request body**: same as POST  
**Response `200 OK`**: updated response object  
**Errors**: `400` validation, `404` not found, `409` conflict

---

### `DELETE /resource-name/{id}`

**Response `204 No Content`**  
**Side effects**: describe any cascading changes (e.g., "reassigns child records to default")  
**Errors**: `404` if not found

---

## DTO definitions

```java
// Request
public record ResourceNameRequest(
    @NotBlank @Size(max = 50) String field1,
    @NotNull @DecimalMin("0.01") BigDecimal field2
) {}

// Response
public record ResourceNameResponse(
    Long id,
    String field1,
    BigDecimal field2
) {}
```

---

## Entity / DB notes

- Table name: `resource_names`
- New columns or FK relationships: describe
- Index requirements: describe
- Migration needed: yes / no

---

## Open questions

- [ ] Question 1
- [ ] Question 2
