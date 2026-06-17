# ARCHITECTURE.md — <PROJECT_NAME>

> **Authoritative** for module structure, layering, dependency direction, data
> flow, and build topology. `CLAUDE.md` only summarises this file. When they
> disagree, this file wins. Fill every `<PLACEHOLDER>` at install by reading the
> real parent POM and module layout.

## 1. Build topology (Maven reactor)
- **Parent POM:** `<PARENT_POM_ARTIFACT>` — aggregates the modules below and
  centralises dependency/version management.
- **Reactor modules:** `<MODULE_LIST>`.
- The Angular module is built `<HOW — e.g. via frontend-maven-plugin during the
  reactor build / independently with npm>`.

```
<project>/
├── pom.xml                  # parent POM (<PARENT_POM_ARTIFACT>)
├── <java-module-1>/         # <responsibility>
├── <java-module-2>/         # <responsibility>
├── ...                      # <PLACEHOLDER: list all Java modules>
└── <angular-module>/        # Angular <ANGULAR_VERSION> frontend
```

## 2. Module responsibilities
| Module | Responsibility | Depends on |
|--------|----------------|------------|
| `<module>` | `<what it owns>` | `<modules / none>` |
| `<module>` | `<what it owns>` | `<modules / none>` |
| `<angular-module>` | UI / client | calls the backend API only |

(One row per real module. Keep dependency direction acyclic.)

## 3. Layering (within the backend)
Allowed dependency direction — **downward only**:

```
controller  →  service  →  repository  →  persistence/DB
```

- Controllers: HTTP edge — validate input, delegate, map to DTOs. No business logic.
- Services: business logic, transaction boundaries (`@Transactional`).
- Repositories: persistence access only.
- Entities model persistence; DTOs cross the API boundary. See
  `.claude/rules/java-coding-rules.md` for the enforced law.

## 4. Data flow
**Request path:**
```
Angular component → service (HttpClient) → REST API
  → controller → service → repository → DB
```
**Response** travels back the same chain; entities are mapped to DTOs before
leaving the controller.

- Cross-module dependencies must follow the table in §2 (no cycles).
- `<PLACEHOLDER: note any messaging/async flows, integrations, or shared
  contracts — e.g. OpenAPI, events>`.

## 5. Key cross-cutting concerns
- Configuration & secrets: `<where / how externalised>` (never in code).
- Security/auth: `<approach>`.
- Error handling: centralised (`<e.g. @ControllerAdvice>`).
- `<PLACEHOLDER: anything else authoritative about the structure>`.
