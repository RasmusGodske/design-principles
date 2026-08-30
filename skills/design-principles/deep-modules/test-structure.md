---
type: lookup-reference
title: Test File Structure
description: The module-specific parts of test placement — factories, module-scoped fixtures, and cross-module reach — with the general structure rules deferred to the Testing principle.
---

# Test File Structure

Where test files live is governed by the **[Testing principle](../testing/README.md)**, not by this
convention. That doc owns the mirror rule (a test lives where its subject lives), the naming of
source roots, how cost tiers are declared, and where rules-about-the-code live.

This page covers only what is specific to *modules*.

For what to test and at what level, see [`testing.md`](testing.md).

## How the mirror applies to modules

A module's test path is its source path with the test root substituted — including the `modules/`
segment.

```text
modules/billing/public/services/BillingService
  → tests/modules/billing/public/services/BillingServiceTest

modules/billing/modules/calculation/public/services/CalculationService
  → tests/modules/billing/modules/calculation/public/services/CalculationServiceTest
```

**Keep the `modules/` segment.** It is tempting to drop it, since everything under the modules root
is a module. Don't: a codebase migrating into modules will have a legacy `billing/` and a new
`modules/billing/` alive at the same time, and dropping the segment collapses both onto one test
path.

Paths get long. The payoff is that placement never needs a discussion — the source path already
determined it.

### Filtering

Long paths buy sharp filtering, which is the module-specific reason the verbosity pays:

| Filter | Runs |
|---|---|
| `billing` | everything for one module, at every tier |
| `public/services` | every module's public services |
| `modules/calculation` | every sub-module of that name |

Cost tiers themselves are declared inside the test with the test runner's tagging mechanism — see the
[Testing principle](../testing/README.md) and its stack binding for the concrete spelling.

## Factories

Model factories (test-data builders for a module's entities) live either where the persistence layer
expects them by default or under the module itself (e.g. `modules/billing/database/factories/`),
whichever the stack resolves cleanly. Either is fine; pick one and apply it consistently — a codebase
with both takes a lookup to answer "where is this model's factory?". The [stack binding](bindings/)
says which one applies.

## Fixtures and helpers belong to a module

Test data builders and scenario helpers live with the tests that use them, scoped by module:

```text
tests/modules/billing/support/BillingScenario
tests/modules/billing/support/fixtures/InvoiceFixtures
```

A `support/` directory *inside a module's test subtree* is fine — the no-junk-drawer rule is about
the source tree, and this scaffolding has a clear owner. A **global** `tests/helpers/`,
`tests/support/`, or `tests/common/` is the junk drawer, and it has the same problem here that it has
in source: everything lands there, nothing is ever removed, and no one owns it.

## Cross-module test reach is a smell

A Billing test that imports an Analytics fixture is telling you something. Either Billing's test data
should belong to Billing, or the two modules are more entangled than the boundary claims. Fix the
ownership, not the import.

This is the test-side echo of the module boundary itself: if a module's tests cannot be written
without reaching into another module's internals, the module is not deep.

## See also

- [Testing principle](../testing/README.md) — the general structure rules
- [`testing.md`](testing.md) — what to test under this convention
- [`directories.md`](directories.md) — source directory reference
