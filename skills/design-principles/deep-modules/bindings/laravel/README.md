---
type: binding-rule
title: Laravel binding for Deep Modules
description: How the deep-modules roles map onto a Laravel application — the app/Modules/ root, Public/ as the public surface, Eloquent models, Http/Console/Jobs/Listeners entry points, the service provider as wiring, and architecture-test enforcement.
---

# Laravel binding for Deep Modules

The [Deep Modules](../../README.md) convention names **roles**. This binding says what each role is called in a Laravel application, how wiring works, and how to enforce the boundary. Everything the principle says still applies; this file only adds the Laravel spelling.

## Role → Laravel

| Role (neutral name) | Laravel |
|---|---|
| Modules root | `app/Modules/` — never directly under `app/` |
| Module namespace | `App\Modules\{Domain}\…` — PSR-4 resolves it from the existing `App\` → `app/` mapping; no `composer.json` change |
| Module README | `app/Modules/{Domain}/README.md` |
| Public surface | `Public/` — `Public/Services/`, `Public/Data/`, `Public/Enums/`, `Public/Events/`, `Public/Exceptions/`, `Public/Contracts/` |
| Internal services | `Services/` |
| Internal values | `Data/`, `Enums/`, `Events/`, `Exceptions/` at the module root |
| Persistence | `Models/` — Eloquent models |
| Entry points | `Http/` (controllers, form requests, middleware, resources), `Console/` (Artisan commands), `Jobs/` (`ShouldQueue` classes), `Listeners/` |
| Wiring | `{Domain}ServiceProvider.php` at the module root (see below) |
| Sub-modules | `Modules/{SubModule}/` — path reads `app/Modules/Billing/Modules/Calculation/` |
| Variants | `Framework/` + one directory per variant |
| Data-class layers | `Data/Http/Controllers/{Controller}/*PropsData` (one controller's payload — the principle's `*PayloadData`, named after the page props it feeds), `Data/Views/*ViewData` (shared presentational), `*Data` at root (domain) — typically Spatie Laravel Data classes |
| Junk drawers | `Helpers/`, `Util/`, `Common/`, `Shared/`, `Misc/` forbidden anywhere in `app/` |

Directory names are PascalCase to match Laravel's `app/` conventions.

The full template in Laravel spelling:

```
app/Modules/{Domain}/
├── README.md
├── {Domain}ServiceProvider.php            ← optional — only if bindings or macros earn it
├── Public/
│   ├── Services/
│   ├── Data/
│   ├── Enums/
│   ├── Events/
│   ├── Exceptions/
│   └── Contracts/
├── Framework/                             ← optional — only with variants
├── Modules/                               ← optional — only with sub-modules
├── Services/
├── Models/
├── Data/
├── Enums/
├── Http/
├── Console/
├── Jobs/
└── Listeners/
```

## The module's faces (naming)

Per [`naming-and-placement.md`](../../naming-and-placement.md), only a module's faces carry its name. In Laravel those are:

| Face | Class | Toward whom |
|---|---|---|
| Primary public service | `BillingService` in `Public/Services/` | other modules |
| Wiring | `BillingServiceProvider` at the module root, only when one is earned | the container |

Controllers are *not* faces here: Laravel registers routes by FQCN in `routes/`, so a controller is named for the resource or action it handles (`InvoiceController`, `RefundController`), never `BillingController`. Everything else — secondary services, models, data classes, enums, jobs, listeners — is named for what it is.

## Things Laravel makes specific

- **Routes** import controllers by FQCN; that is a route file's job, and route files live outside `app/` (`routes/`). A module does not register routes from its provider.
- **Framework glue at fixed paths** (`app/Providers/`, `app/Console/Kernel`-style files where they exist, `bootstrap/`) stays put — it is not a module.
- **Cross-module Eloquent relationships** (`belongsTo`, `hasMany`) require importing the related model. Treat the imported model as a published reference: keep its surface minimal, prefer accessors over raw public properties, route mutations through `Public/Services/`.
- **Listener auto-discovery** picks up `Listeners/`; **policy auto-discovery** registers policies; the **schedule** is defined in `routes/console.php`. None of these need a provider.

## Wiring: the service provider

A module's `{Domain}ServiceProvider.php` handles wiring that Laravel's auto-resolution cannot do on its own. **Most modules do not need one.**

### Default: no provider

Laravel handles a lot automatically:

- **Constructor injection** — type-hint the dependency, the container resolves it.
- **Listener auto-discovery** — listeners in `Listeners/` are picked up.
- **Policy auto-discovery** — policies are auto-registered.
- **Routes** — registered in `routes/`, not in providers.
- **Schedule** — defined in `routes/console.php`.

If a module is just services, models, and an HTTP layer that uses constructor injection, it does not need a provider. **An empty provider is shallow ceremony** — do not add one to satisfy the template.

### When to add one

Add `{Domain}ServiceProvider.php` when at least one of these is true:

| Trigger | Example |
|---|---|
| Interface → implementation binding | `$this->app->bind(PaymentGatewayContract::class, StripeGateway::class)` |
| Multiple implementations to map | A variant framework where outside callers depend on a contract; the provider picks the variant |
| Singleton with construction logic | A service that holds state and needs setup beyond `new Foo($dep)` |
| Macros | `Collection::macro('toBilling', …)` |
| Observers | `Invoice::observe(InvoiceObserver::class)` |
| Manual event wiring | Events that auto-discovery cannot pick up |

If none apply: no provider.

### Where it lives

The provider lives at the module root — same level as `README.md`:

```
app/Modules/Billing/
├── README.md
├── BillingServiceProvider.php       ← here
├── Public/
└── ...
```

For sub-modules, the provider goes at the sub-module's root following the same rule.

For modules with `Framework/`, the framework provider goes at `Framework/{Domain}FrameworkServiceProvider.php` and handles variant binding (since the framework is what knows about all variants):

```
app/Modules/PaymentGateways/
├── README.md
├── Framework/
│   └── PaymentGatewaysFrameworkServiceProvider.php   ← binds the active variant
├── Stripe/
│   └── (no provider needed — just an implementation)
└── Paypal/
    └── (no provider needed — just an implementation)
```

### Registration

Each provider is registered in `bootstrap/providers.php` — Laravel's flat provider list:

```php
// bootstrap/providers.php
return [
    App\Providers\AppServiceProvider::class,
    App\Modules\Billing\BillingServiceProvider::class,
    App\Modules\PaymentGateways\Framework\PaymentGatewaysFrameworkServiceProvider::class,
    // ...
];
```

The flat list is a deliberate registration point. Auto-discovery of providers exists in some Laravel-package tooling, but it adds runtime magic for no real payoff in application code.

### Anti-patterns

- **Empty providers.** A provider with no logic in `register()` or `boot()` is dead weight. Delete it.
- **One mega-provider.** Stuffing every module's bindings into `AppServiceProvider` couples the bootstrap to module internals. If a module needs bindings, give it its own provider.
- **Provider as a router.** Routes belong in `routes/`. Do not register routes from a provider unless there is a specific reason auto-discovery does not cover.
- **Provider as a config publisher.** Config publishing is a Laravel-package concern. Application modules do not publish config.
- **Cross-module bindings in a provider.** A provider should bind only its own module's classes. If module A's provider binds module B's classes, that is a leak — refactor.

## Enforcement

PHP has no package-level visibility: anything `public` on a class is callable from anywhere by FQCN, and PHPStan does not catch cross-module reaches by default. So in Laravel the `Public/` **directory is the boundary**, and an architecture test guards it.

The rule to encode: *nothing outside `App\Modules\X` may depend on `App\Modules\X\*` except `App\Modules\X\Public\*`* (recursively for `Modules/{Sub}/` and `Framework/`).

Sketch with Pest's architecture plugin:

```php
// tests/Conventions/ModuleBoundariesTest.php
arch('module internals are private')
    ->expect('App\Modules\Billing')
    ->toOnlyBeUsedIn(['App\Modules\Billing'])
    ->ignoring('App\Modules\Billing\Public');
```

Repeat per module (or generate the cases from the `app/Modules/*` listing). Equivalent tooling: PHPArkitect or Deptrac — define each module as a layer, declare its public paths, declare its internal paths, and fail CI on any cross-module import that touches an internal path.

Enforcement is opt-in; the convention works as a guideline without it, but violations accumulate quietly. Add the test when the cost of drift outweighs the cost of setup.

## Legacy Laravel layouts

Laravel's default `app/` is organized by technical type (`app/Services/`, `app/Models/`, `app/Http/`, `app/Jobs/`, …). In a codebase adopting this convention, **that whole root-level layout counts as one grandfathered domain**: references among root-level classes are intra-domain, new modules go under `app/Modules/`, and legacy code moves only as a deliberate, scoped migration. `app/Modules/` is precisely what keeps the two worlds from interleaving. See [`legacy-code.md`](../../legacy-code.md).

**Modules that publish by kind.** If a codebase adopted this convention on top of modules that publish by *kind* — root-level `Data/`, `Enums/`, `Events/`, `Exceptions/`, `Contracts/` treated as public — those surfaces remain valid published contract until the module migrates: treat such a module's root-level value directories as if they were under `Public/`. Migrate opportunistically when the module is substantially reworked; never mix the two styles within one module.

## Test placement

Tests mirror the module: `tests/Modules/{Domain}/…` (or `tests/App/Modules/{Domain}/…`, depending on the suite's source-root mapping), with cost declared per test via PHPUnit/Pest `#[Group]` attributes. See the [Testing principle's Laravel binding](../../../testing/bindings/laravel/README.md) and [`test-structure.md`](../../test-structure.md).

## Worked examples

Full Laravel trees for each shape — flat domain, domain with sub-modules, variant framework, contract module, and the full pattern — live in [`examples/`](examples/README.md).

## See also

- [`../../README.md`](../../README.md) — the principle this binds
- [`../../directories.md`](../../directories.md) — role reference, including the wiring rule
- [`../../public-surface.md`](../../public-surface.md) — why the boundary is explicit and how it is enforced
