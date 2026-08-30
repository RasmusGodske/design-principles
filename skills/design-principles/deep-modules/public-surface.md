---
type: binding-rule
title: Public Surface
description: Only a module's public surface is importable from outside — publication is an explicit act, everything else is internal; why the boundary is explicit rather than by kind, and how to enforce it in languages with and without native visibility.
---

# Public Surface

Why the public surface exists, what goes in it, and how to think about the boundary.

## The problem to solve

A module is only deep if callers can't reach around its interface. That needs a way to say "internal": callable from inside the module, not from outside. Some languages give you one at package or module level (package-private, `internal/` packages, `pub`/`pub(crate)`, an index file that re-exports a chosen subset). Many do not — anything public on a class is callable from anywhere by its fully-qualified name, and the default static tooling does not notice a cross-module reach.

The convention therefore makes the public surface **explicit and visible in the tree**:

- Where the language has a native mechanism, the public surface is whatever that mechanism exports — *and* the convention still groups it so a reader can see the contract at a glance.
- Where it doesn't, a **directory** stands in for the missing keyword: a class's location in `public/` says *"outside callers may use this."* Its absence from `public/` says *"do not."*

## What the public surface contains

A module's public surface contains **everything** outside callers may touch — nothing outside it is importable from another module:

```
modules/{Domain}/public/
├── services/              ← public services (mutations, orchestrating queries)
├── data/                  ← published data classes — the module's contract vocabulary
├── enums/                 ← published enums
├── events/                ← published events (fired inside, listened to outside)
├── exceptions/            ← published exceptions (thrown inside, caught outside)
└── contracts/             ← published interfaces others implement or reference
```

Each subdirectory is optional — a module adds it when it has something of that kind to publish.

## What is public, what is not

The single rule for outside callers:

> **A module's public surface is public. Everything else is internal.**

| Public | Internal |
|---|---|
| `public/services/` | `services/` — internal services |
| `public/data/` | `data/` — internal data classes |
| `public/enums/` | `enums/` — internal enums |
| `public/events/` | `models/` |
| `public/exceptions/` | `entrypoints/` (http, cli, jobs, listeners) |
| `public/contracts/` | everything else |

Publication is an **explicit act**: placing a class on the public surface says "this is part of my contract — outsiders may depend on it." Nothing becomes contract by accident of directory kind.

## Why publication is explicit, not by kind

A tempting simplification is to make all *value* kinds (data classes, enums, events, exceptions) public by definition — values are cheap to share, and restricting them adds ceremony. That reasoning is true but incomplete; the convention rejects it for two reasons:

1. **The contract becomes legible.** Under public-by-kind, you cannot read a module's tree and see which data classes are load-bearing contract and which are incidentally reachable implementation detail. Under explicit publication, the public surface *is* the contract — reviewable at a glance, and exactly what would become the shared package if the module were ever extracted to a service.
2. **Coupling becomes opt-in.** Public-by-kind means every internal data class is one import away from silently becoming another module's dependency — and nothing marks the moment it happens. Requiring the move onto the public surface makes the owning module consent to every new dependency on it.

The cost is real but small: a class is moved (and re-namespaced) the first time another module genuinely needs it. That move is itself valuable signal — it is the moment a shape becomes a contract, and it should be a reviewed decision, not an import.

Events remain slightly asymmetric: outsiders' listeners reference them, but only the owning module's services *fire* them. The published event class is the value type that travels between producer and consumer; the dispatch site stays inside the module.

Mutations and orchestrating queries carry invariants, side effects, and the risk of being routed around. They live in `public/services/` — that remains what enforcement most protects.

## Why models are NOT freely importable

Persistence entities are technically references too — but they carry methods that mutate state (`save()`, `delete()`, `update()`), expose the storage schema as public surface (column names, casts, relationships), and tend to grow side effects (hooks, observers, scopes).

Letting outsiders import models means letting them call `model.save()`, which is a mutation that bypasses `public/services/` entirely. That is precisely the leak the convention is designed to prevent.

One hard-to-avoid exception in ORM-heavy stacks: **cross-module relationships** require the related model to be importable for typing. Treat the imported model as a published reference — keep its surface minimal, prefer accessors over raw public properties, and route mutations through `public/services/`. [`detachable-domain`](../detachable-domain/README.md) covers the full rule.

## Why this is enforceable

A visible public surface is *enforceable* in a way that a "discipline" rule is not.

- **Language with native visibility:** use it. Package-private / `internal/` / `pub(crate)` / index re-exports make the compiler or module loader the enforcer; nothing extra to install.
- **Language without it:** the directory is the boundary, and an **architecture test** guards it. The single rule above maps cleanly to a dependency-rule linter or arch-test suite: define each module as a layer, declare its public paths, declare its internal paths, and fail CI on any cross-module import that touches an internal path. Your [binding](bindings/) names the tool and shows the rule.

Without enforcement, the convention works as a guideline — but quiet violations accumulate over time. Adding enforcement promotes the convention from "we try to" to "CI fails if you don't."

## Sub-modules and the public surface

Sub-modules are **public peers by default**. Outside callers may import a sub-module's public surface directly — the parent module is not a required gateway.

A parent gets its own `public/services/` only when it has *cross-sub-module orchestration* to host:

- Transactions spanning multiple sub-modules
- Invariants only the parent can enforce
- A single point that enforces ordering between sub-modules

If the parent has nothing to enforce, do not give it a `public/services/`. A delegating facade with no logic is shallow ceremony — see [`promotion-criteria.md`](promotion-criteria.md).

## Adopting the explicit surface in an existing codebase

If a codebase already publishes by kind (root-level value directories treated as public), do not run a big-bang migration. Migrate opportunistically: when a module is substantially reworked, move its published classes onto the explicit public surface as part of the rework. Never mix the two styles *within* one module — a module publishes explicitly (new style) or by kind (grandfathered), not both. See [`legacy-code.md`](legacy-code.md).

## See also

- [`directories.md`](directories.md) — full directory reference
- [`promotion-criteria.md`](promotion-criteria.md) — when optional structural elements earn their place
- [`bindings/`](bindings/) — the enforcement tool and native visibility mechanism per stack
