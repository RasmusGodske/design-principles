---
type: concept-explainer
title: Testing
description: How to think about what to test, at what level, and what not to test under the module convention.
---

# Testing

How to think about what to test, at what level, and what NOT to test under this convention.

This page is about *what* a module's tests should target. The shape of the suite itself — where test
files live, how cost tiers are declared, how coverage is made visible — is governed by the
[Testing principle](../testing/README.md); the module-specific placement details are in
[`test-structure.md`](test-structure.md).

## The core shift

In a shallow-module codebase, the unit of testing is a **class**. Hundreds of small services each get their own tiny unit test, mostly mocking each other. The tests pass green; the integrated system breaks anyway because the bugs hide in how the classes compose.

In a deep-module codebase, the unit of testing is the **module's public surface**. You test what the module promises to do — not how it does it.

A `BillingService` test exercises `chargeCustomer()` end-to-end — with real internal services, real models, real DB. It does not unit-test `CurrencyRoundingHelper` in isolation. The helper is covered through the service's behavior. If `chargeCustomer()` rounds correctly, the helper works.

This is closer to "behavioral tests at the module boundary" than to classical unit tests. It is what the public surface buys you.

## The anti-pattern this resists

> **Pure-function-for-testability** — a function was extracted only so it could be unit-tested, not because callers benefit. The real bugs hide in how it's called.

A shallow-module codebase is full of these — services extracted not because they hide complexity but because someone wanted a unit test. The convention's "no junk drawer" rule and "internal services only when earned" rule push back on this. Testing pushes back too: don't extract for testability, test through the module's public promise.

## Layer-by-layer guidance

| Layer | How to test |
|---|---|
| Public services | Behavioral tests — call the service, assert outcomes (stored state, returned values, side effects) |
| Internal services | Through the public service that uses it. Direct unit tests only for combinatorial or pure logic |
| Models / entities | Through services. Direct tests only for complex queries, derived attributes, or non-trivial relationships |
| HTTP entry points | Feature test — send the request, assert response and side effects |
| CLI entry points | Invoke the command, assert output and side effects |
| Background jobs | Through the dispatching service, OR an integration test asserting queue/work effects |
| Event listeners | Fire the event, assert the listener's effect (often via service-level integration) |
| Data, enums, events, exceptions | Rarely tested directly — they are values, exercised through services that use them |

## Cross-module testing — don't mock the public boundary

When module A calls module B's public services, A's test uses the **real** B service. The whole point of the public boundary is that it is stable and contract-shaped — mocking it tests A against an imagined B, not the real one.

Exceptions:

- **B has external side effects** (payment gateway, email, third-party API): fake at the *external* boundary, not at B's interface. The payment provider's API gets faked; B's service does not.
- **B is genuinely slow** (large DB query, heavy computation): use a fake, but the fake must still implement B's public interface. Do not bypass the contract.

This is one of the practical wins of deep modules: there are far fewer interfaces to mock, and the boundaries are clear about which ones must remain real.

## Contract tests for variant frameworks

When a module has published contracts and multiple implementations (Stripe and Paypal both implement `PaymentGateway`), write a **shared contract test** — the same behavioral suite run against each implementation:

```text
// tests/modules/payment-gateways/framework/PaymentGatewayContractTest

for each gateway in [StripeGateway, PaypalGateway]:
    test "it processes a charge" (gateway):
        // behavioral test against the contract's promises
```

Most test runners have a native way to parameterize one test over several subjects; use it rather than copying the suite per implementation.

Each implementation must pass the same promises. This is where published contracts actually earn their ceremony — without contract tests, the interface is a documentation gesture; with them, it is a tested invariant.

## When direct testing of internals IS warranted

Three legitimate reasons to test an internal class directly:

- **Combinatorial logic.** A state machine with many transitions, a parser with many edge cases, a matrix of validation rules — enumerating at the unit level gives signal an integration test cannot.
- **Pure transformations.** A non-trivial calculation, a complex serializer. Pure functions have predictable inputs and outputs; unit tests are cheap and sharp.
- **Regression tests for a specific bug.** A bug found in an internal helper may warrant a targeted unit test that fixes that exact case.

Default to testing through the surface; promote to direct unit tests only when one of these applies. If you find yourself extracting a private method into a class so you can unit-test it, you are over the line.

## The README's promise IS the test plan

Each module's `README.md` describes what the module hides — that is its test plan. Tests verify those promises. If the README claims *"Billing guarantees an invoice is never sent twice for the same period,"* there should be a test asserting it.

This makes the README a load-bearing artifact:

- **Reviewers** read it to check *"do the tests prove this?"*
- **Future maintainers** read it to check *"what behavior must I preserve when refactoring?"*
- **A README that promises behavior the tests don't verify is a bug.** Either add the test or revise the promise.

## When in doubt

- Default to behavioral tests at the public surface.
- Direct unit tests are an exception, not a default.
- Don't mock things you own. Mock external systems only.
- Test the README's promise.

## See also

- [Testing principle](../testing/README.md) — the shape of the test suite as a whole
- [`test-structure.md`](test-structure.md) — module-specific test placement
- [`public-surface.md`](public-surface.md) — what defines the boundary tests target
- [`promotion-criteria.md`](promotion-criteria.md) — when internal services exist (and thus when "test through the surface" applies)
