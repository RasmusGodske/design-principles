---
type: concept-explainer
title: Deep Modules
description: Depth is leverage — hide a lot of behaviour behind a small interface; plus the module-structure convention that makes that shape mechanical: an explicit public surface, an enforceable boundary, and a recursive layout, in any language.
---

# Deep Modules

> **Depth is leverage at the interface — the amount of behaviour a caller can exercise per unit of interface they have to learn.**

A **deep module** hides a lot of behaviour behind a small interface. A **shallow module's** interface is nearly as complex as its implementation — the caller gains little by going through it. This principle has two halves: the *lens* (how to judge depth) and the *convention* (a module layout that makes depth the default shape). The lens is language-independent; the convention names **roles**, and a [stack binding](#stack-bindings) says what each role is called in your stack.

## The lens

### What "interface" means here

Wider than a type signature. A module's interface is **everything a caller must know to use it correctly**:

- The signature (parameters, return type)
- Invariants the module guarantees
- Ordering constraints (must call X before Y)
- Error modes the caller must handle
- Required configuration / dependencies
- Performance characteristics relevant to the caller

If callers have to read the implementation to use the module safely, the interface is leaking.

### The deletion test

The single most useful diagnostic. **Imagine deleting the module.**

- If complexity **vanishes** — nobody loses anything, callers carry on — the module was a pass-through. **Shallow.**
- If complexity **reappears** across N callers — each now has to do the work the module was hiding — the module was earning its keep. **Deep.**

A module that fails the deletion test is shallow regardless of how much code it contains. Lines of implementation are not depth.

### Red flags

- A "service" whose every method forwards one call to another object.
- An interface with exactly one implementation, extracted "for testability".
- A module whose README cannot say what it *hides*, only what it *contains*.
- Callers that import three of the module's internals to get one thing done.

## The convention

### Why it exists

Most frameworks' default layout is organized by technical type (`models/`, `controllers/`, `jobs/`, `listeners/`). At small scale this works. Past a few dozen entities it starts to fight you: a single feature scatters across five sibling directories, relationships between things become hard to see, and "where does this go?" becomes a daily question with no good answer.

This convention organizes the same code by **domain**. A module owns its own services, models, entry points, jobs — everything related to one slice of the application lives in one place. Cross-module leakage is enforced through one visible **public surface** rather than through language features that may not exist.

### Where modules live

Every module lives under one **modules root** (the binding names it — e.g. `modules/` or `src/modules/`), never loose beside it. A new domain is `{modules-root}/{Domain}/`.

This is a deliberate boundary. Whatever type-organized layout pre-dates the convention stays where it is; the modules root means a glance at the tree tells you which code is a clearly-bounded module and which is grandfathered legacy — the two never interleave at the top level.

**Not everything is a module, and that's fine.** Existing root-level code stays exactly where it is (see [`legacy-code.md`](legacy-code.md)) — the convention is the default for *new* modules, not a mandate to migrate what already works. Framework glue that your stack expects at fixed paths also stays put.

> **One word, two levels.** The modules root is the home for top-level domains. *Within* a domain, a `modules/` directory holds sub-modules — so a sub-module path reads `modules/Billing/modules/Calculation/`. Same word, same meaning ("modules live in `modules/`"), just at two nesting levels.

### Terminology

- **Module** — a directory that owns a slice of behaviour. The general unit of structure in this convention.
- **Domain** — a top-level module directly under the modules root. A domain is just a module that happens to be at the top level.
- **Sub-module** — a module nested inside another module's `modules/` directory. Same template, recursively.
- **Public surface** — the parts of a module that outside callers may import. Defined by an explicit act of publication, not by directory kind.
- **Role** — a kind of thing a module contains (public surface, internal service, persistence, entry point, wiring, decomposition). This doc names roles; the binding names directories.

### Module shapes

A module takes one of three shapes, distinguished by what it contains at the parent level. Most modules are leaf modules; container and contract modules are deliberate choices when no leaf shape describes the module's intent honestly.

- **Leaf module** — has its own services. Does work. The default and most common shape (~95% of cases).
- **Container module** — exists purely to organize sub-modules. The parent has no public services of its own; sub-modules are public peers. Use when a parent groups related sub-modules but has no orchestration of its own to host.
- **Contract module** — publishes a shared abstraction (one or more interfaces). Has no services or models — implementers live in other independent modules. Use when multiple independent modules need the same contract and no single one is its natural owner.

The three minimums:

```
Leaf:       modules/{Domain}/README.md + public/services/{Service}
Container:  modules/{Domain}/README.md + modules/{SubModule}/...
Contract:   modules/{Domain}/README.md + public/contracts/{Contract}
```

Sections below cover the leaf shape (the default) in detail, with sub-modules and variants for decomposition.

### Principles

1. **Deep modules over shallow ones.** A module hides a lot of behaviour behind a small interface. If deleting the module wouldn't make N callers more complex, the module is a pass-through and shouldn't exist.
2. **Public surface is explicit.** Outside callers may only import a module's public surface — publication is an explicit act, never a side effect of directory kind. Where the language has a visibility mechanism, use it; where it doesn't, a directory plays that role. See [`public-surface.md`](public-surface.md).
3. **Earned, not speculative.** Every optional structural element — internal services, sub-modules, variant frameworks, contracts, wiring files — is added only when it earns its place. See [`promotion-criteria.md`](promotion-criteria.md).
4. **Mutations go through public services.** Entry points (HTTP handlers, CLI commands, listeners, jobs) are thin and delegate. State changes never originate in an entry point.
5. **Names describe what a thing is, not where it lives.** The module name belongs in the namespace / package path. A class carries the module's name only when it is the module's face toward an outsider — its primary public service, or the pieces the framework registers per module (the binding lists them). See [`naming-and-placement.md`](naming-and-placement.md).

### The default shape

A module's minimum is two things: a `README.md` and at least one public service.

```
modules/{Domain}/               ← required: README + one public service
├── README.md
└── public/
    └── services/
        └── {Service}
```

A typical module fills out more of the template (directory names are the neutral defaults — your binding may spell them differently):

```
modules/{Domain}/
├── README.md                   ← what this module hides (one paragraph)
├── public/                     ← the ONLY importable surface — the module's contract
│   ├── services/               ← public services — outsiders call these
│   ├── data/                   ← published data classes — the contract vocabulary
│   ├── enums/                  ← published enums
│   ├── events/                 ← published events (fired by this module, listened to by others)
│   ├── exceptions/             ← published exceptions (caught by outsiders)
│   └── contracts/              ← published interfaces
├── services/                   ← internal services — only this module calls these
├── models/                     ← internal — persistence entities, never imported externally
├── data/                       ← internal data classes
├── enums/                      ← internal enums
└── entrypoints/                ← internal — HTTP handlers, CLI commands, jobs, listeners
```

Add directories as the module genuinely needs them. A small module might be a README and one service file. A large one fills the whole template. Full template and growth path: [`default-shape.md`](default-shape.md).

### Decomposing a module

Modules grow. The convention gives two structural tools for breaking a module into smaller pieces, and they're independent — a module can use neither, either, or both.

#### Sub-modules — for internal complexity

When a piece of a module has enough internal complexity to justify hiding behind a smaller interface, promote it to a **sub-module**. Sub-modules use the same template recursively, nested inside the parent's `modules/` directory.

```
modules/Billing/
├── README.md
├── public/
│   └── services/                ← parent's public surface (orchestration, if any)
└── modules/
    ├── Calculation/             ← sub-module
    │   ├── README.md
    │   ├── public/services/
    │   ├── services/
    │   └── data/
    └── Invoicing/               ← sub-module
        ├── README.md
        ├── public/services/
        └── ...
```

Sub-modules are **public peers by default** — outside callers may import a sub-module's public surface directly. The parent gets its own public services only when it has cross-sub-module orchestration to host (transactions spanning sub-modules, invariants only the parent can enforce, ordering between sub-modules). A parent that only delegates is shallow ceremony.

#### Variants — for multiple kinds of the same thing

When a module exists in several kinds or versions that must evolve independently (payment providers, export formats, engine versions), split it into a shared **framework** and one directory per **variant**:

```
modules/PaymentGateways/
├── README.md
├── framework/                   ← shared across variants
│   ├── public/contracts/        ← the interface every variant implements
│   └── public/services/         ← code that operates on any variant
├── Stripe/                      ← variant — full module template
└── Paypal/                      ← variant — full module template
```

*Promote when you can name the variant axis cleanly and the second variant exists.* If you can't name the axis, you don't qualify. (The framework/variant split is its own principle — see [`framework-and-implementation`](../framework-and-implementation/README.md) for what may live in the framework.)

#### Combining both

Variants and sub-modules compose. A variant can itself contain `modules/` for its own internal decomposition. The recursion has no fixed depth limit, but each level of nesting must earn its place by the same promotion criteria. See [`promotion-criteria.md`](promotion-criteria.md).

### The seven rules

1. **Required minimum.** Every module has a `README.md` (one paragraph: what does this hide) AND at least one of: a public service (leaf module — most common), a `modules/` directory containing sub-modules (container module), or a published contract that other modules implement (contract module).
2. **Public surface.** Outside callers may import from a module's public surface. Nothing else. Publication is an explicit act — a class becomes contract by being placed on the public surface, never by directory kind.
3. **Internal roles.** Everything outside the public surface is private to the module — internal services, models, internal data/enums, entry points — only the module itself imports from these.
4. **Mutations go through public services.** HTTP handlers, CLI commands, tool endpoints, listeners are thin entry points that delegate. State changes never originate in an entry point.
5. **No junk drawers.** `helpers/`, `util/`, `common/`, `shared/`, `misc/` are forbidden anywhere in the source tree.
6. **Naming.** Names describe what a class IS, not where it lives. Only a module's faces — its primary public service and the pieces the framework registers per module — carry the module's name; everything it contains, published or not, is named for what it is. Before placing a new class, name 1–2 alternative homes and pick the strongest.
7. **Optional elements earned.** Framework/variant splits, sub-modules, contracts, wiring files, internal services are added only when they earn their place. See [`promotion-criteria.md`](promotion-criteria.md).

## Reading map

This README is the spine. Load other files only when the task requires depth.

| File | Read when |
|---|---|
| [`default-shape.md`](default-shape.md) | Creating a new module or sanity-checking the shape of an existing one |
| [`directories.md`](directories.md) | "What goes in this role/directory?" / "Is this class in the right place?" — includes the wiring rule |
| [`public-surface.md`](public-surface.md) | Deciding whether something is public or internal, and how to enforce the boundary |
| [`promotion-criteria.md`](promotion-criteria.md) | Considering whether to add an optional structural element |
| [`decision-tree.md`](decision-tree.md) | Actively placing a new class and unsure where it belongs |
| [`naming-and-placement.md`](naming-and-placement.md) | Naming a new class |
| [`testing.md`](testing.md) | Deciding what to test, at what level, what NOT to test |
| [`test-structure.md`](test-structure.md) | Module-specific test placement — factories, module-scoped fixtures, cross-module reach (general suite shape lives in the [Testing principle](../testing/README.md)) |
| [`legacy-code.md`](legacy-code.md) | Working in a codebase that pre-dates the convention |
| [`visualization.md`](visualization.md) | Drawing or explaining a structure (ASCII, Mermaid) |
| [`examples/`](examples/README.md) | Looking for a matching pattern from a worked example |
| [`bindings/`](bindings/) | Stack bindings — the real directory names, wiring mechanism, the module's framework-facing classes, and the enforcement tool for a specific stack; today: [`laravel`](bindings/laravel/README.md), [`nestjs`](bindings/nestjs/README.md) |

## Stack bindings

This doc names **roles** (public surface, internal service, persistence, entry point, wiring, decomposition) and uses neutral lowercase directory names as illustrations. A **binding** maps those roles onto one stack: the modules root, the real directory names, the namespace/package convention, the wiring mechanism (DI container, module registration, plain constructors), the native visibility mechanism if any, and the enforcement tool. Bindings live at `bindings/{stack}/README.md`, with their worked examples beside them.

If no binding exists for your stack, apply the roles directly using the language's native visibility mechanism, and write the binding down once the shape has settled.

## What this convention is not

- **Not a package system.** This is a directory convention, not runtime modularization. No manifest per module, no install/uninstall, no plugin marketplace.
- **Not strict DDD.** Hexagonal architecture, bounded contexts, anti-corruption layers are valid choices but not what this is. This is a pragmatic vertical-slice convention informed by the deep-modules lens.
- **Not a substitute for thinking.** The promotion criteria require judgment. The decision tree is a guide, not a generator. When the convention doesn't answer cleanly, that's a signal to stop and think — not to invent a workaround.

## Adopting this convention

- **New project:** Apply from day one — every module under the modules root. Start each one flat and let it earn complexity.
- **Existing project:** New modules go under the modules root. Don't retrofit existing code; grandfather it until there's a specific reason to migrate. The modules root is precisely what keeps the two worlds from interleaving — a half-converted codebase is fine *because* the boundary is visible. See [`legacy-code.md`](legacy-code.md).
- **Enforcement is opt-in.** The convention works as a guideline without tooling. Architectural enforcement (a dependency-rule linter or architecture test — your binding names one) can be added later when the cost of drift outweighs the cost of setup; the convention is designed to map cleanly onto a layered-architecture tool when that time comes.
