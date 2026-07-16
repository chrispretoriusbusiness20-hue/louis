# Dependency injection — patterns and pitfalls

## The three injection styles

| Style | When | Notes |
|---|---|---|
| **Constructor injection** | Default. Required dependencies. | Object is valid from birth; dependencies are visible in the signature; easy to fake in tests. |
| **Method/parameter injection** | Dependency varies per call (a clock, a transaction handle). | Keeps per-call context out of object state. |
| **Property/setter injection** | Optional dependencies with a safe default (a logger). | Last resort — allows half-initialized objects. |

If a constructor takes 5+ dependencies, that's an SRP smell, not a reason to switch styles. Split the class or group related dependencies into a cohesive collaborator.

## The composition root

All wiring lives in **one place per executable**: `main()`, an app factory, or a container module. Everything below it receives collaborators; nothing below it constructs them.

```ts
// composition root — the only file that knows concrete types
function buildApp(config: Config) {
  const db = new PostgresPool(config.dbUrl);
  const users: UserRepository = new PostgresUserRepository(db);
  const mailer: Notifier = new SesNotifier(config.ses);
  const registerUser = new RegisterUserUseCase(users, mailer);
  return new HttpApi({ registerUser });
}
```

Tests get their own tiny composition root that wires fakes.

## With or without a container

- **Manual wiring** (plain constructors, as above) is the right default for most codebases. It's type-checked, greppable, and refactorable.
- **A DI container / framework mechanism** (Spring, NestJS, .NET DI, Guice, FastAPI `Depends`) earns its keep when the graph is large, scopes matter (per-request), or the framework already mandates it.
- Use the mechanism the stack already has. Never bolt a container onto a codebase that wires manually, or vice versa.

## Scoping

| Scope | For | Hazard |
|---|---|---|
| Singleton | Stateless services, config, connection pools | Any mutable field becomes shared global state |
| Scoped (per-request) | Units of work, request context, DB transactions | Injecting a scoped item into a singleton (captive dependency) |
| Transient | Cheap stateful helpers | Constructing expensive resources per use |

**Captive dependency** is the classic bug: a singleton service holding a per-request DB session keeps the *first* request's session forever. Containers rarely warn about this — check scopes at every injection edge.

## Pitfalls

**Service locator (the anti-DI):**

```ts
class RegisterUser {
  run(input) {
    const repo = Container.get(UserRepository);  // ❌ hidden dependency, untestable signature
  }
}
```

Dependencies pulled from a global are invisible in the type signature, break at runtime instead of compile time, and force tests to mutate global state. Always push dependencies in.

**Leaking the container:** injecting the container itself (`constructor(private container: Container)`) is service locator with extra steps.

**Over-abstraction:** an interface with exactly one implementation, no test double, and no variance in sight is noise — inject the concrete class until a second implementation or a test need appears. (Exception: I/O boundaries — DB, HTTP, clock, randomness — always deserve an abstraction because tests need to fake them.)

**Framework types in the core:** if a use case's constructor mentions `Request`, `HttpClient`, or an ORM entity manager, infrastructure has leaked inward. Wrap it behind a domain-owned interface.

**Doing work in constructors:** constructors assign dependencies, nothing else. I/O in a constructor makes the object impossible to build in tests and hides failures at wiring time.

## Faking at the seams

Every injected abstraction should have an obvious test double:

```ts
class InMemoryUserRepository implements UserRepository {
  private rows = new Map<Id, User>();
  async findByEmail(e) { ... }  // real logic against the map
  async save(u) { this.rows.set(u.id, u); }
}
```

Prefer hand-written fakes with real (in-memory) behavior for repositories and gateways; use mocks/stubs for one-off interactions. If a fake is painful to write, the interface is too fat — split it.
