# Reusable component design

## When to extract

Extract shared logic when you can name the abstraction by **what it is** rather than where it's used. `Paginator<T>`, `RetryPolicy`, `MoneyFormatter` — yes. `UserListHelper`, `CheckoutUtils` — no; those are grab-bags waiting to accrete.

The rule of three still applies: two similar-looking blocks may be coincidental duplication. Extract on the third occurrence, or earlier only when the two are *required* to stay in sync (a business rule stated twice). **Don't unify code that happens to look alike but changes for different reasons** — that coupling is worse than the duplication.

## Design rules

- **Parameterize, don't specialize.** Generic over the element type (`Paginator<T>`), configured with values/strategies rather than hard-coded policy (`RetryPolicy(maxAttempts, backoff)`).
- **Stateless by default.** A reusable unit holds configuration (immutable, set at construction) but not workflow state. If it must hold state, document the lifecycle and thread-safety explicitly.
- **Side-effect free by default.** Pure in → out. Effects (I/O, logging, metrics) enter only via injected abstractions, so the component stays usable in any context — including tests.
- **Dependencies point at abstractions.** A reusable component may depend on `Clock` or `Logger` interfaces; it may never depend on your app's domain types, config module, or DI container — that's what pins it to one codebase.
- **Minimal surface.** Export the operations callers need, keep internals private. Every public member is a compatibility promise.
- **Isolation test.** A component is reusable iff it can be instantiated and fully tested in a file that imports nothing else from the application. If the test needs app fixtures, it isn't reusable yet.

## Composition over inheritance

Inheritance shares *implementation* and couples the child to every parent decision. Composition shares *behavior* through small parts:

```ts
// ❌ deep hierarchy: each level bakes in decisions the next must live with
class CsvReportExporter extends FileExporter extends BaseExporter { ... }

// ✅ composed behaviors, each independently testable and swappable
const exporter = new Exporter(new CsvFormatter(), new S3Writer(), new GzipCompressor());
```

Reach for inheritance only for genuine is-a contracts with stable, shallow hierarchies (often: abstract base implementing template steps). If a subclass overrides a method to disable it, composition was the answer (see LSP).

## Utilities vs. components

- A **utility** is a pure function (`slugify`, `chunk`). Keep utilities as free functions in cohesive modules (`text.ts`, `collections.ts`) — never a `Utils` dumping ground.
- A **component** has configuration and/or collaborators (`RateLimiter`, `CircuitBreaker`). Make it a class/closure with constructor injection.
- Promotion path: inline logic → private function → module function → component. Promote only under real reuse pressure.

## Versioning discipline for shared code

Once a component is used from 3+ places (or published), treat its API as frozen surface:
- Additive changes are cheap; renames/removals need a deprecation window.
- Never add a parameter that only one caller needs — that caller should wrap or compose instead.
- Resist the "just add a boolean flag" evolution: two flags in, the component has four modes and no name. Split into two components or accept a strategy.
