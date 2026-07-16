---
name: solid-architecture
description: >
  Apply industry best-practice software architecture: SOLID principles, reusable components,
  dependency injection, clean layering, and testable design — in any language or framework.
  Trigger this skill whenever the user asks to build a class, service, module, component,
  API, repository, use case, or any non-trivial code structure. Also trigger on phrases like
  "best practice", "clean architecture", "SOLID", "dependency injection", "reusable",
  "maintainable", or "testable". Language-agnostic: applies equally to TypeScript, Python,
  C#, Java, Go, Rust, Ruby, and others. Always use this skill — do not rely on defaults.
---

# SOLID Architecture Skill

You are producing production-grade, maintainable software. Before writing any non-trivial code, reason through this skill. Translate every principle below into whatever language and idiom the user is working in — the concepts are universal, the syntax is incidental.

---

## Step 1 — Read the Codebase Context

Before designing anything:
- What language and runtime is in use?
- What architectural style already exists (layered, hexagonal, CQRS, MVC)?
- What DI mechanism is available or preferred (container, manual wiring, framework-native)?
- What testing framework is in use?

Adapt the patterns below to fit that context. Never introduce a foreign pattern that fights the existing stack.

---

## Step 2 — Apply SOLID (Non-Negotiable)

### S — Single Responsibility
> One unit, one reason to change.

- A class/module does **one thing**. If you can describe it with "and also…", split it.
- Separate: input validation, business rules, persistence, external calls, response formatting.
- Test: can you name it in a single noun phrase without conjunctions?

### O — Open / Closed
> Open for extension, closed for modification.

- New behaviour is added by **adding** code (new class, new implementation), not by editing existing logic.
- Replace long `if/switch` on type with a strategy, policy, or handler pattern.
- Existing, tested code should not change when new variants are introduced.

### L — Liskov Substitution
> Any implementation must fully honour its contract.

- A concrete type must satisfy every precondition, postcondition, and invariant of its abstraction.
- Never override a method to throw "not implemented" or silently no-op.
- Prefer composition when a subtype can't fully substitute its parent.

### I — Interface Segregation
> Callers should not depend on methods they don't use.

- Keep contracts small and focused. Fat interfaces become coupling traps.
- Split a large interface when different callers use different subsets.
- A read-only caller should not receive a write capability.

### D — Dependency Inversion
> High-level policy must not depend on low-level detail.

- Business logic depends on **abstractions** (interfaces, protocols, abstract types).
- Concrete implementations (DB, HTTP, file, queue) live in the infrastructure layer.
- The abstraction is owned by the layer that needs it, not the layer that implements it.

---

## Step 3 — Dependency Injection Rules

| Rule | Detail |
|---|---|
| **Constructor injection** | All required dependencies received at construction time — never instantiated inside the class. |
| **Accept abstractions** | Parameters typed as interfaces/protocols, not concrete classes. |
| **Composition root** | Wiring happens in one place: `main`, a factory, or a DI container. Business logic never assembles its own graph. |
| **Scope correctly** | Stateless services → singleton. Per-request state → scoped/transient. Never mix scopes incorrectly. |
| **No service locator** | Do not call a global container from inside a business class. Pass dependencies in, don't pull them. |

---

## Step 4 — Layered Architecture

```
Presentation   →   Application   →   Domain   →   Infrastructure
  (thin)          (use cases)      (pure logic)    (I/O, external)
```

**Dependency arrows always point inward (toward Domain). Never outward.**

| Layer | Responsibilities | Must NOT contain |
|---|---|---|
| **Domain** | Entities, value objects, business rules, domain events | Framework imports, I/O, DB calls |
| **Application** | Use cases, orchestration, input/output DTOs | Domain entity construction details, HTTP concerns |
| **Infrastructure** | Implements domain interfaces: DB, HTTP, queue, file | Business rules, validation logic |
| **Presentation** | Controllers, resolvers, CLI handlers, event consumers | Business logic — delegates immediately to application layer |

---

## Step 5 — Reusable Components

- Extract shared logic into **generic, parameterised** abstractions (a `Paginator<T>`, not a `UserListPaginator`).
- Name by **what it is**, not where it's currently used.
- Reusable units must be **stateless** and **side-effect free** unless explicitly documented otherwise.
- Prefer **composition over inheritance** — small, focused behaviours composed together beat deep hierarchies.
- A component is reusable when it can be tested in complete isolation from the rest of the system.

---

## Step 6 — Contracts Before Implementation

1. Define the **abstraction** (interface / protocol / abstract type) first.
2. Place it in the layer that **consumes** it (domain or application), not the layer that implements it.
3. Keep the contract **minimal** — only the methods callers actually need.
4. Write the implementation against the contract, not the other way around.

---

## Step 7 — Error Handling

- Use **typed errors** that carry meaning — not raw strings, not generic exceptions.
- Distinguish **domain errors** (rule violations: invalid state, business constraint) from **infrastructure errors** (I/O failure, timeout).
- Never silently swallow an exception.
- Handle errors at the **boundary** (presentation or application layer entry point) — not scattered throughout business logic.
- Consider a Result/Either type for expected failure paths to make error handling explicit and type-safe.

---

## Step 8 — Testability Checklist

Before finalising any unit of code, verify:

- [ ] All dependencies injected (none created internally)?
- [ ] No global or static mutable state?
- [ ] No direct I/O (DB, HTTP, file) in business logic?
- [ ] Every public behaviour testable with a test double (mock/stub/fake)?
- [ ] Side effects isolated to the infrastructure layer?
- [ ] Domain logic contains no framework-specific imports?

---

## Output Format

For every non-trivial piece of code, deliver in this order:

1. **Contract** — the abstraction the rest of the system depends on
2. **Implementation** — the concrete class/module that fulfils the contract
3. **Wiring** — a composition root snippet showing how dependencies are assembled
4. **Test stub** — a minimal test showing how a mock/fake is injected

If the scope is large, scaffold the full structure (contracts + empty implementations) first, then fill in logic layer by layer.

---

## Red Flags — Never Produce These

- ❌ Instantiating a dependency inside a business class (`new ConcreteRepo()`, `SomeService()`)
- ❌ Global or static mutable state accessible across call boundaries
- ❌ A single class handling validation + persistence + business rules + formatting
- ❌ An interface with 10+ methods that no single caller uses entirely
- ❌ Silently caught and discarded exceptions
- ❌ Framework or I/O imports inside domain entities
- ❌ Business logic inside a controller, handler, or route definition
- ❌ A subtype that throws "not supported" for inherited methods

---

## Reference Files

For deeper guidance on specific topics, read:

| Topic | File |
|---|---|
| SOLID principles — detailed examples and anti-patterns | `references/solid-deep-dive.md` |
| Dependency injection patterns & common pitfalls | `references/dependency-injection.md` |
| Layered / hexagonal architecture patterns | `references/architecture-patterns.md` |
| Reusable component design | `references/reusable-components.md` |
| Testing strategies (unit, integration, contract) | `references/testing-strategies.md` |

Read the relevant reference only when the user's task requires that depth. Do not load all references by default.
