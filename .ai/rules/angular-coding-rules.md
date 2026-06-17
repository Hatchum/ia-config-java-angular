---
paths:
  - "**/*.ts"
  - "**/*.scss"
  - "**/*.component.html"
---

# Angular coding rules (baseline)

Path-scoped rule, **scoped by content rather than by directory** so it works
whatever the Angular module is named: `.ts`/`.scss` are Angular-only in a
Java + Angular monorepo, and `*.component.html` (Angular CLI convention) avoids
matching backend `.html` templates (e.g. Thymeleaf). Deterministic rules below
apply to the Angular module; the team's Angular skills deepen them — when a skill
and this file overlap, follow the skill's detail but never violate a rule here.

## Component architecture
- Use **standalone components** (or strictly bounded NgModules if the app
  predates standalone). Keep public surfaces small and explicit.
- Apply the **smart/dumb split**: container components own data fetching and
  state; presentational components are pure inputs-in / outputs-out and hold no
  service dependencies.
- **No business logic in templates** — no complex expressions, no method calls
  doing work in bindings. Compute in the component (or a pipe) and bind the
  result.

## Typing
- **Type everything.** No loose `any`; prefer precise interfaces/types,
  `unknown` + narrowing when a type is genuinely open. Enable and respect
  `strict` mode.
- Type component inputs/outputs, service signatures, and HTTP response shapes.

## Change detection
- Use `ChangeDetectionStrategy.OnPush` on components. Drive updates through
  immutable inputs, signals, or observables — not by mutating in place.

## Reactivity & cleanup
- **Always release subscriptions.** Prefer the `async` pipe or
  `takeUntilDestroyed()` over manual `subscribe`; if you subscribe manually,
  unsubscribe on destroy. No leaking long-lived subscriptions.
- Keep RxJS streams declarative; avoid nested `subscribe`.

## State & HTTP
- State and HTTP access live in **services**, not components. Components consume
  services; they don't call `HttpClient` directly or hold app-wide state.
- Keep services focused (single responsibility); provide at the right scope.

## Naming & structure
- Files follow Angular convention: `feature.component.ts`, `*.service.ts`,
  `*.guard.ts`, `*.pipe.ts`. Selectors are kebab-case with the team prefix.
- One primary export per file; co-locate a component's template/styles/spec.
- No secrets or environment-specific URLs hardcoded — use environment config.
