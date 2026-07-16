# Testing strategies — unit, integration, contract

Architecture and testability are the same property viewed from two sides: if the layering and DI rules in this skill are followed, these strategies fall out naturally. If a test is hard to write, treat it as an architecture signal, not a testing problem.

## The shape of the suite

- **Many unit tests** on domain and application logic — fast, no I/O, run on every save.
- **Some integration tests** on each infrastructure adapter — real DB/HTTP against the adapter alone.
- **Few end-to-end tests** through the composition root — smoke the wiring, not every branch.

Branchy business logic gets covered at the unit level, so the expensive levels stay thin.

## Unit tests (domain + application)

- Test through the **public contract** — never private methods, never internal call order. Refactors that preserve behavior must not break tests.
- Domain objects need zero doubles: construct, act, assert.
- Use cases take **fakes** for their ports:

```ts
test("registering a duplicate email fails", async () => {
  const users = new InMemoryUserRepository();       // hand-written fake, real in-memory behavior
  await users.save(existingUser("a@b.com"));
  const useCase = new RegisterUserUseCase(users, new NullNotifier());

  const result = await useCase.run({ email: "a@b.com", ... });

  expect(result).toEqual(err(new DuplicateEmailError("a@b.com")));
});
```

- **Prefer fakes over mocks** for repositories/gateways: fakes assert on *outcomes* (state), mocks assert on *interactions* (calls). Interaction assertions couple tests to implementation — reserve them for cases where the interaction *is* the requirement (e.g., "sends exactly one email").
- Determinism: inject `Clock` and id/randomness generators; a test that sleeps or reads real time is a flake in waiting.

## Integration tests (infrastructure adapters)

- Scope: **one adapter + the real technology**, nothing else. `PostgresUserRepository` against a real Postgres (container/testcontainer), `StripeGateway` against Stripe's test mode or a recorded stub.
- Verify the translation: rows/payloads map to correct domain objects, constraint violations map to the right typed errors, transactions actually roll back.
- Keep them isolated and repeatable: fresh schema per run (or per test via transactions/truncation), no ordering dependencies.

## Contract tests — keeping fakes honest

The gap in the fake-based approach: the fake and the real adapter can drift. Close it by running **one shared test suite against every implementation** of a port:

```ts
function userRepositoryContract(makeRepo: () => Promise<UserRepository>) {
  test("save then findByEmail returns the user", ...);
  test("findByEmail returns none for unknown email", ...);
  test("save with duplicate email raises DuplicateEmailError", ...);
}

userRepositoryContract(() => Promise.resolve(new InMemoryUserRepository()));  // fast
userRepositoryContract(() => makePostgresRepoWithFreshSchema());              // integration
```

If both pass the contract, unit tests using the fake are trustworthy evidence about production behavior. Any new port implementation must pass the existing contract suite before it ships.

For **cross-service** boundaries, the same idea appears as consumer-driven contracts (e.g., Pact): the consumer's expectations become a suite the provider runs in CI.

## End-to-end / composition tests

- Build the app via the **real composition root** with test config (in-memory or containerized infra), hit the outermost interface (HTTP, CLI), assert on responses and visible state.
- Purpose: catch wiring mistakes — wrong scope, missing binding, captive dependency, broken middleware order. A handful of happy paths plus one error path is usually enough.

## Test smells → architecture diagnoses

| Smell | Likely cause |
|---|---|
| Test needs 10 mocks | Class violates SRP or ISP — too many collaborators / fat interface |
| Must mock a concrete class | Missing port at an I/O boundary (DIP violation) |
| Tests break on refactor without behavior change | Interaction-based assertions on internals |
| Can't construct object in a test | Constructor does work / hidden service-locator pull |
| Test needs real env vars or network | Config or I/O read inside business logic |
| Sleeps and retries in tests | Non-injected clock or unawaited async effects |

Fix the code, not the test.
