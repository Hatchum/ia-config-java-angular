---
paths:
  - "**/*.java"
---

# Java coding rules (baseline)

Path-scoped rule (`paths: **/*.java`): loads when Claude works on Java files.
Deterministic rules below always apply to Java code in this repo. The team's Java
skills deepen these — when a skill and this file overlap, follow the skill's
detail but never violate a rule here.

## Layering & responsibilities
- Respect the layer direction: `controller → service → repository`. A layer may
  only depend downward, never upward or sideways into a sibling's internals.
- **No business logic in controllers** — they validate input, delegate to a
  service, and map the result. No branching on domain state, no persistence.
- **No business logic in entities** — entities model persistence, not workflows.
- Keep cross-cutting concerns (security, transactions, mapping) out of the
  domain core.

## DTO / entity separation
- Never expose JPA/persistence entities across the API boundary. Map to/from
  DTOs at the controller (or a dedicated mapper).
- DTOs are immutable where possible (Java `record`s or final fields).

## Dependency injection
- **Constructor injection only.** No field/setter `@Autowired`; declare
  collaborators `final` and inject via the constructor.
- Depend on interfaces, not concrete implementations, where it aids testability.

## Logging
- **Never** use `System.out.println` / `System.err.println` or
  `printStackTrace()`. Use the project's logging facade (e.g. SLF4J).
- Log with parameterized messages (`log.info("user {} created", id)`), not
  string concatenation. No secrets/PII in logs.

## Exception strategy
- Don't swallow exceptions (no empty `catch`). Either handle meaningfully or
  propagate.
- Use domain-specific exceptions; translate them to HTTP responses centrally
  (e.g. `@ControllerAdvice` / global handler), not ad hoc per controller.
- Prefer unchecked exceptions for unrecoverable domain errors; never use
  exceptions for normal control flow.

## Transactions
- Place `@Transactional` on the **service** layer, not on controllers or
  repositories. Mark read-only operations `@Transactional(readOnly = true)`.
- Keep transactions short; no remote calls inside a transaction boundary.

## Immutability & null-safety
- Prefer immutability: `final` fields, immutable collections, `record`s for
  value/data carriers.
- Avoid returning `null` for collections — return empty. Make optionality
  explicit (`Optional`) at API edges rather than scattering null checks.

## Secrets & configuration
- **No secrets, credentials, tokens, or connection strings in code.** Externalize
  to configuration/environment. Never commit `.env` or key material.

## Naming
- Classes `PascalCase`; methods/fields `camelCase`; constants
  `UPPER_SNAKE_CASE`. Names describe intent, not type. Test classes end in
  `Test`.
