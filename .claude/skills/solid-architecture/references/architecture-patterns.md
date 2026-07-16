# Layered and hexagonal architecture patterns

## The dependency rule

Whatever the style is called, one rule does the work: **source-code dependencies point inward, toward the domain.** The domain knows nothing about the application layer; the application layer knows nothing about HTTP or the database. Outer layers depend on inner-layer *interfaces*.

Enforce it mechanically where possible: import-linting (dependency-cruiser, import-linter, ArchUnit, Go internal packages) beats code review memory.

## Canonical four layers

```
Presentation → Application → Domain ← Infrastructure
```

### Domain
- Entities, value objects, domain services, domain events, and the *interfaces* for anything the domain needs from the outside (repositories, clocks).
- Pure: no framework imports, no I/O, no environment reads. Everything here is unit-testable with no setup.
- Value objects validate on construction (`EmailAddress`, `Money`) so invalid states are unrepresentable downstream.

### Application
- One use case per user-visible operation (`RegisterUser`, `CancelOrder`). Orchestrates domain objects and outbound ports; owns transactions.
- Speaks DTOs at its boundary — never leaks domain entities to presentation, never accepts raw HTTP shapes.
- Thin: if a use case contains business *rules* (not orchestration), push them into the domain.

### Infrastructure
- Implements domain/application interfaces: repositories over a real DB, HTTP clients for external APIs, queue publishers, filesystem, clock.
- Translation layer: maps DB rows/API payloads ↔ domain objects. Persistence models are allowed to look nothing like domain entities.
- No business decisions. If an `if` here encodes a business rule, it's in the wrong layer.

### Presentation
- Controllers, GraphQL resolvers, CLI commands, queue consumers. Parses input, calls one use case, formats output, maps errors to transport codes.
- The test: a controller body should be ~5–15 lines. Anything more is logic leaking in.

## Hexagonal (ports & adapters) — the same rule, different vocabulary

- **Port** = an interface owned by the core. *Driving* ports are what the world calls on the app (use case interfaces); *driven* ports are what the app calls on the world (repository, notifier).
- **Adapter** = an implementation at the edge. Driving adapters (HTTP controller, CLI) call driving ports; driven adapters (Postgres repo, SES mailer) implement driven ports.
- Practical payoff: any adapter is swappable — the same core runs under an HTTP API, a CLI, and a test harness.

Choose hexagonal vocabulary when the system has many kinds of edges (HTTP + queue + cron); plain layering when it's a straightforward web app. They are not competing patterns.

## CQRS-lite (the useful 80%)

Separate command use cases (mutate, return little) from query use cases (read, return DTOs). Queries may bypass the domain and read the DB directly through a thin read layer — rich domain invariants matter for writes, not for rendering a list. Full CQRS with separate stores/event sourcing is rarely warranted; don't introduce it by default.

## Choosing weight by project size

| Project | Appropriate structure |
|---|---|
| Script / small tool | No layers. Functions. Don't scaffold ports for a 200-line CLI. |
| Small service | Two folders: `core` (logic + interfaces) and `adapters` (I/O). The dependency rule, minus ceremony. |
| Growing app | Full four layers, use-case classes, composition root. |
| Large / multi-team | Layers *inside* feature modules (`orders/domain`, `orders/infra`), not global layer folders — vertical slices keep module boundaries meaningful. |

Match the existing codebase first. A consistent MVC app is better served by "fat model, skinny controller" discipline than by a foreign hexagon dropped into one feature.

## Common violations checklist

- ORM entities used as domain entities *and* API responses (one change ripples through all three).
- Domain importing the framework's `@Injectable`/annotation types (couples the core to the container).
- Use case reaching into `request.headers` (transport leaked inward).
- Repository interface with query-builder parameters (`findWhere(sql)`) — the abstraction leaks its implementation.
- Two use cases calling each other through the presentation layer (extract shared application service instead).
