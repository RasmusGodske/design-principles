---
type: binding-rule
title: Testing — Laravel / Pest binding
description: How the Testing principle's roles — source roots, the mirror, test kinds, cost tiers and the tagging mechanism — are spelled in a Laravel application tested with Pest / PHPUnit.
---

# Testing — Laravel / Pest binding

This file maps the stack-neutral roles in [`../../README.md`](../../README.md) onto a Laravel codebase. It adds no rules; it only says what each role is called here.

## The mirror

| Role | Laravel |
|---|---|
| Application source root | `app/` → `tests/App/` |
| Tooling source root | `tooling/` → `tests/Tooling/` |
| Packages source root | `packages/` → `tests/Packages/` |
| Test file suffix | `{Subject}Test.php` |
| Casing | StudlyCase for every segment in the test tree |
| Package `src/` segment | dropped |
| Scaffolding directory | `Support/` inside the owning area's test subtree |

Worked derivations:

```text
app/Billing/Refunder.php            →  tests/App/Billing/RefunderTest.php
app/Billing/Invoicer.php            →  tests/App/Billing/InvoicerTest.php
tooling/module-graph/Walker.php     →  tests/Tooling/ModuleGraph/WalkerTest.php
packages/foo-bar/src/Baz.php        →  tests/Packages/FooBar/BazTest.php
```

Split-by-behaviour keeps the subject prefix: `RefunderTest.php`, `RefunderPartialRefundTest.php`.

## Kinds (first path segment)

```text
tests/
├── App/  Tooling/  Packages/   mirrored — executes your code, one root per source root
├── Interface/                  browser tests (Dusk / Playwright); a different runner
└── Conventions/                reads the source tree, never boots the application
```

A root nests inside a kind when both apply: `tests/Interface/Tooling/…`, `tests/Conventions/Routes/…`.

Convention tests are one file per rule, named for the assertion:

```text
tests/Conventions/
├── Routes/       EveryMutatingEndpointIsTestedTest.php
├── Modules/      NoModuleReachesIntoAnotherTest.php
└── Migrations/   EveryNewTableHasACommentTest.php
```

A rule that must *run* something (e.g. "every migration is reversible") lives in the mirrored tree instead — `tests/App/Database/MigrationsAreReversibleTest.php` — tagged for its real cost.

## Cost tiers — the tagging mechanism

Tiers are declared **inside the test** with PHPUnit's group attribute (or Pest's `->group()` chain). Untagged means the cheapest (isolated) tier.

```php
// PHPUnit style
#[Group('database')]
public function test_it_records_a_refund_against_the_original_payment(): void { … }

// untagged — isolated tier
public function test_it_refuses_a_refund_larger_than_the_payment(): void { … }
```

```php
// Pest style
it('records a refund against the original payment', function () { … })->group('database');

it('refuses a refund larger than the payment', function () { … });   // untagged — isolated
```

Suggested tier names, ordered by cost: *(untagged)* isolated → `database` → `full`.

Running a slice:

```text
vendor/bin/pest --exclude-group=database,full     # the cheap slice
vendor/bin/pest --group=database                  # one tier
```

## Kind-level tier defaults

A kind whose cost is uniform declares its tier once at the branch, not per file — a base `TestCase` for `tests/Interface/` (or a `uses(...)` block in that branch's `Pest.php`) carries the `full` group for every test beneath it. The per-test, untagged-means-cheapest default applies only inside the mirrored kind, where cost varies test by test.

## Runtime guard

Whatever an untagged test may not touch must fail the moment it is touched: in the base test case for the isolated tier, bind a database connection resolver that throws with a message naming the fix (`add #[Group('database')]`), rather than silently opening a connection.

## See also

- [`../../README.md`](../../README.md) — the principle these mappings serve
