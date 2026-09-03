---
type: lookup-reference
title: Directories Reference
description: For each module role/directory — its purpose, contents, who may import from it, and when to add it to a module; includes the wiring rule.
---

# Directories Reference

Per-role reference. Each entry covers: purpose, contents, who may import from it, and when to add it to a module.

Directory names are the convention's neutral defaults; a stack [binding](bindings/) gives the real names (e.g. an `entrypoints/` role split into `http/`, `cli/`, `jobs/`, `listeners/`). The roles and import rules are what transfer.

For the rules about when *optional* directories earn their place, see [`promotion-criteria.md`](promotion-criteria.md).

## Required

### `README.md`

- **Purpose:** Describes what the module hides — the deletion test, written down. *If I removed this module, what complexity would reappear in callers?*
- **Contents:** One paragraph (~3–5 lines). What this module does, its public surface in one sentence, notable invariants or constraints if any.
- **Required:** Yes — every module, including sub-modules.

### `public/services/`

- **Purpose:** The public entry surface for the module. Mutations and orchestrating queries live here.
- **Contents:** Concrete `*Service` classes that outside callers invoke.
- **Imported by:** Any module.
- **Required:** Yes for **leaf modules** (the common case). Not present in **container modules** (which contain only `README.md` + `modules/`) or **contract modules** (which contain only `README.md` + `public/contracts/`). See the three module shapes in [`README.md`](README.md#module-shapes).

## Published — under `public/`, importable from any module

Only things on the public surface are importable from outside the module. Placing a class here is the explicit act of publication: it becomes part of the module's contract.

### `public/data/`

- **Purpose:** Published data classes (DTOs) — the module's contract vocabulary.
- **Contents:** Immutable value objects representing requests, responses, configuration, or domain values that outside callers consume or construct.
- **Imported by:** Any module.
- **When to add:** When another module genuinely needs one of this module's data classes. Moving a class from internal `data/` to `public/data/` is the moment a shape becomes contract — treat it as a reviewed decision.
- **Structure — three homogeneous buckets** (applies to the internal `data/` directory too; keep it from becoming a flat mix of domain values and view payloads):

  | Bucket | Holds | Suffix |
  |---|---|---|
  | root | **Domain data classes** — the entity data classes used by services and logic (each a Config or a Record; see [`config-and-record`](../config-and-record/README.md)). | `*Data` |
  | `data/entrypoints/{Handler}/` | **Handler I/O** owned by one entry point — the per-action payload, request data classes, and any child data classes private to that handler. Mirrors the handler's own location. Handler I/O is internal by nature — it lives under the internal `data/`, never `public/data/`. | `*PayloadData` for the per-action payload |
  | `data/views/` | **Shared presentational data classes** — resolved/projected shapes reused by ≥2 handlers (e.g. a domain data class enriched with display-resolved fields). Internal unless another module renders them. | `*ViewData` |

  The placement rule, in one line: *owned by one handler → mirror the handler (internal); shared & presentational → `data/views/`; pure domain value → the root — `public/data/` if published, `data/` if internal.* A suffix signals the layer without reading the path; the suffixes above are the neutral illustration and your binding spells them (`*Data` / `*PayloadData` / `*ViewData` in one stack, `*Dto` / `*RequestDto` / `*ViewDto` in another). Don't over-structure a module with three data classes — promote to the sub-buckets when the flat directory starts mixing the kinds.

### `public/enums/`

- **Purpose:** Published enum types.
- **Contents:** Enum declarations that outside callers reference (often as properties of published data classes).
- **Imported by:** Any module.
- **When to add:** When an enum is part of the published contract (e.g. referenced by a `public/data/` class or accepted by a public service).

### `public/events/`

- **Purpose:** Events fired by this module's services and listened to by other modules.
- **Contents:** Event classes (typically value objects with the data describing what happened).
- **Imported by:** Any module — outsiders' listeners reference these to react to them. Only this module's own services *fire* them.
- **When to add:** When another module listens to the module's events.
- **Note:** This is asymmetric — events are produced internally but consumed externally. The published class is the value type that travels; firing the event still goes through `public/services/` (entry points don't fire events directly). An event only this module listens to stays internal (`events/`).

### `public/exceptions/`

- **Purpose:** Exceptions thrown by the module's public surface.
- **Contents:** Custom exception classes.
- **Imported by:** Any module — outsiders catch these.
- **When to add:** When the module throws domain-specific exceptions that callers may want to catch.

### `public/contracts/`

- **Purpose:** Interfaces (occasionally abstract classes) for shared abstraction or variant abstraction.
- **Contents:** Interfaces. Concrete implementations live elsewhere — in `public/services/`, in variant directories, or in independent modules that implement the contract.
- **Imported by:** Any module.
- **When to add:** When at least one of these is true: (a) ≥2 implementations exist today, (b) the module is a host that variants plug into (paired with `framework/`), or (c) the module IS a **contract module** — its entire purpose is to publish a shared abstraction that independent modules implement. Adding a contract for a service with one implementation in a leaf module is shallow ceremony — don't.

## Internal — only the module imports from these

Outside callers may not import directly. Routing here goes through the module's public surface. The value-kind directories (`data/`, `enums/`, `events/`, `exceptions/`) may also exist at the module root as **internal** counterparts of their published siblings — same content kinds, module-private.

### `services/` (without `public/`)

- **Purpose:** Internal services — sub-services, helpers, the implementation behind `public/services/`.
- **Contents:** `*Service` classes used only by the same module's own code.
- **Imported by:** Only this module.
- **When to add:** When `public/services/` accumulates internal helpers that bloat its public surface. Promote helpers here when they are no longer something outsiders should call.

### `models/`

- **Purpose:** Persistence entities owned by this module (ORM models, table mappings, aggregates).
- **Contents:** Entity / model classes.
- **Imported by:** Only this module. Other modules read or write through `public/services/`.
- **When to add:** When the module has persisted tables/collections.
- **Note:** Cross-module ORM relationships are hard to avoid in many stacks. When the relationship target is in another module, treat it as a published reference — keep the surface minimal and resist exposing model methods that mutate state. See [`detachable-domain`](../detachable-domain/README.md) for the full rule.

### `entrypoints/`

- **Purpose:** The places the outside world enters this module: HTTP handlers/controllers, request validation, middleware, CLI commands, queued jobs, event listeners, RPC/tool endpoints.
- **Contents:** Thin adapters. Bindings usually split this role into several directories (`http/`, `cli/`, `jobs/`, `listeners/`).
- **Imported by:** Only this module. Routing/registration tables reference them by fully-qualified name; that is the router's job, and route tables live outside the module.
- **When to add:** When the module exposes an endpoint, command, job, or reacts to an event.
- **Notes:**
  - Entry points are thin — they delegate every mutation to `public/services/`.
  - Outside callers triggering async work go through `public/services/`, which dispatches the job internally.
  - Listeners live in the *consumer* module (the one that reacts), never the producer.

## Decomposition directories

### `modules/`

- **Purpose:** Container for sub-modules.
- **Contents:** Sub-module directories, each following the same template recursively.
- **Imported by:** Outside callers may import a sub-module's public surface directly — sub-modules are public peers by default.
- **When to add:** When a piece of the module has enough internal complexity to justify hiding behind its own interface. See [`promotion-criteria.md`](promotion-criteria.md).

### `framework/`

- **Purpose:** Shared infrastructure across variants of a module.
- **Contents:** Contracts every variant implements (`framework/public/contracts/`), services that operate on any variant (`framework/public/services/`), shared models, enums, etc.
- **Imported by:** Variants of this module use it freely. Outside callers may import its public surface (`framework/public/**`) under the same rules as any other module.
- **When to add:** When the module hosts multiple variants of the same thing and you can name the variant axis cleanly. See [`promotion-criteria.md`](promotion-criteria.md) and [`framework-and-implementation`](../framework-and-implementation/README.md).

## Wiring

### The module's wiring file (a DI registration, module descriptor, provider, …)

- **Purpose:** Module-level wiring that the stack cannot infer on its own — interface→implementation bindings, singletons with construction logic, observer/hook registration, manual event wiring.
- **Required:** No. **Default: no wiring file.** Most stacks resolve constructor dependencies, discover listeners, and register routes without a per-module file; a module that is just services, models, and entry points using constructor injection needs nothing.
- **When to add:** On the *first real* need — a variant framework whose callers depend on a contract and something must pick the implementation; a singleton that needs setup beyond `new Foo(dep)`; observers or hooks the stack doesn't auto-discover. If none apply: no wiring file.
- **Where it lives:** At the module root, beside `README.md`. For sub-modules, at the sub-module's root. For modules with `framework/`, the framework's wiring file is the one that binds the active variant (the framework is what knows about all variants); variants themselves usually need none.
- **Anti-patterns:**
  - **Empty wiring files.** A registration with nothing to register is dead weight — delete it.
  - **One mega-registration.** Stuffing every module's bindings into the application's root wiring couples bootstrap to module internals. If a module needs bindings, give it its own file.
  - **Wiring as a router.** Routes belong in the route tables.
  - **Cross-module bindings.** A module's wiring binds only its own classes. If module A's wiring binds module B's classes, that is a leak — refactor.
- **Stack specifics** (what the file is called, how it is registered): see your [binding](bindings/).

## Forbidden anywhere in the source tree

### `helpers/`, `util/`, `common/`, `shared/`, `misc/`

- **Why forbidden:** Junk drawer names. Code lands here because nobody could decide where it belongs — and once one class lands, more follow. Projects with these directories reliably end up documenting them as the place where code goes when nothing else fits.
- **What to do instead:** Place each class in the module that actually owns the behaviour. If two modules share a primitive, decide which one *owns* it — usually one is the producer, one is the consumer, and the producer keeps it. If neither does, that is a signal you are missing a module.

## Imports at a glance

The single rule:

> **Outside callers may import a module's public surface. Nothing else.**

| Role / directory | Outsiders may import? |
|---|---|
| `public/**` (`services/`, `data/`, `enums/`, `events/`, `exceptions/`, `contracts/`) | ✅ (`public/events/`: reference in listeners — only the owning module fires them) |
| `services/` (internal) | ❌ |
| `data/`, `enums/`, `events/`, `exceptions/` (root-level, internal) | ❌ |
| `models/` | ❌ |
| `entrypoints/` (http, cli, jobs, listeners) | ❌ |
| wiring file | ❌ (the application bootstrap references it; nothing imports from it) |
| `framework/` | Same rule, recursively. `framework/public/**` ✅ — everything else in `framework/` ❌ |
| `modules/{SubModule}/` | Same rule, recursively. Sub-modules are modules — apply the table to each. |

## Where to go next

- [`public-surface.md`](public-surface.md) — deeper rationale for the public boundary and how to enforce it
- [`promotion-criteria.md`](promotion-criteria.md) — when optional directories earn their place
- [`decision-tree.md`](decision-tree.md) — "where does this class go?" flowchart
- [`bindings/`](bindings/) — real names and mechanisms per stack
