# SOLID — detailed examples and anti-patterns

Language-agnostic; examples use TypeScript-flavored pseudocode. Translate to the project's idiom.

## Single Responsibility

**The test:** describe the unit in one noun phrase, no conjunctions. "Order price calculator" passes. "Order manager" (validates, prices, saves, emails) fails.

**Anti-pattern — the god service:**

```ts
class OrderService {
  placeOrder(input) {
    // validates input          ← responsibility 1
    // calculates totals        ← responsibility 2
    // writes to database       ← responsibility 3
    // sends confirmation email ← responsibility 4
    // formats API response     ← responsibility 5
  }
}
```

Any change to email templates, tax rules, or the DB schema forces edits (and re-tests) of the same class.

**Refactor:** `OrderValidator`, `PricingPolicy`, `OrderRepository` (interface), `OrderNotifier` (interface), with a thin `PlaceOrderUseCase` orchestrating them. The use case's single responsibility is *the orchestration itself*.

**Nuance:** SRP is about *reasons to change*, not line count. A 300-line pricing engine with one reason to change is fine. A 40-line class that mixes persistence and formatting is not.

## Open/Closed

**The test:** adding the next variant should mean adding a file, not editing one.

**Anti-pattern — type switch that grows forever:**

```ts
function shippingCost(order) {
  switch (order.carrier) {
    case "ups": ...
    case "fedex": ...
    // every new carrier edits this function and re-risks all carriers
  }
}
```

**Refactor — strategy:**

```ts
interface CarrierRates { cost(order: Order): Money }
class UpsRates implements CarrierRates { ... }
class FedexRates implements CarrierRates { ... }
// registry or DI selects the implementation; adding DHL touches nothing existing
```

**Nuance:** don't pre-abstract. Two variants with no third in sight can stay a conditional. Reach for strategy when the switch appears in multiple places or variants keep arriving.

## Liskov Substitution

**The test:** any code written against the abstraction works, unchanged, with every implementation — same contract, no surprises.

**Anti-patterns:**

- The classic: `Square extends Rectangle` — `setWidth` breaking the height invariant.
- The practical one you'll actually see:

```ts
class ReadOnlyUserRepo implements UserRepository {
  save(user) { throw new Error("not supported") }  // ❌ violates the contract
}
```

If an implementation can't honor part of the contract, the contract is too big (see ISP) or the type hierarchy is wrong (prefer composition).

**Contract dimensions to preserve:** preconditions can't be strengthened, postconditions can't be weakened, invariants hold, no new exception types callers don't expect.

## Interface Segregation

**The test:** does every caller use (or could reasonably use) every method? If different callers use disjoint subsets, split.

**Anti-pattern — the fat repository:**

```ts
interface UserRepository {
  findById; findByEmail; save; delete; countByRegion;
  exportToCsv; bulkImport; anonymize; ...
}
```

The signup use case needs `findByEmail` + `save`; it now depends on (and its tests must stub) twelve methods.

**Refactor:** `UserReader`, `UserWriter`, and task-specific contracts (`UserExporter`). A concrete class may implement several small interfaces — callers only see the slice they need.

**Rule of thumb:** interfaces are defined by the *caller's* need. One caller, one small contract, even if that means several interfaces per implementation.

## Dependency Inversion

**The test:** can the domain/application layer compile with zero imports from infrastructure? Grep the domain folder for framework/DB/HTTP imports — the result should be empty.

**Anti-pattern:**

```ts
import { PostgresClient } from "pg";           // ❌ in a use case file
class RegisterUser {
  private db = new PostgresClient(CONFIG);     // ❌ constructs its own dependency
}
```

**Refactor:** the use case declares `constructor(private users: UserRepository)` where `UserRepository` is an interface defined *next to the use case*. `PostgresUserRepository` lives in infrastructure and imports the interface — the arrow points inward.

**Ownership rule:** the consumer owns the abstraction. Infrastructure implements contracts it does not define. This is what makes swapping Postgres → DynamoDB (or → in-memory fake in tests) a wiring change, not a refactor.

## How the five interact

They reinforce each other: DIP gives you seams; ISP keeps those seams small; LSP makes the seams trustworthy; OCP exploits the seams to add behavior; SRP keeps each side of every seam simple. When code feels hard to test, the root cause is usually a DIP violation; when a change fans out across many files, it's usually SRP or OCP.
