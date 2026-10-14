---
name: design-principles
description: Design principles for maintainable, testable, decoupled code — deep modules, pure core / persistent shell, detachable domain, config vs record, single chokepoint per fact, acting on behalf, data view, explicit names, safe deletion, retire don't erase, data minimization, framework vs implementation, testing shape, deterministic tests, documentation placement and discoverability. Load BEFORE planning a feature, adding a module/service/class, deciding who may see or do something, writing a migration that drops or changes data, reviewing a diff, or deciding where code, tests, or docs go. Any language or framework; stack-specific bindings live inside.
---

# Design Principles

**Purpose.** These principles make writing code mechanical: where a thing goes, what kind of entity to create, who owns a piece of data, where its test lives — each is a rule you look up, not a judgment call. That gives developers and coding agents one shared language for design and review, and it keeps a codebase easy to extend for far longer than agent defaults (nearest working shape, another helper, a second write path) would allow. Apply them as you plan, place, and review; when a rule and the code disagree, that is the moment to stop and think, not to work around it.

These are **lenses** — ways of looking at a design or a diff that sharpen the conversation. They describe shape and discipline, not procedure; they produce no artifacts; and they are project- and stack-agnostic. Each principle has a directory beside this file with the full doc (`README.md`), deeper sub-docs, and worked examples. Read this index, decide which lens applies, then read only that principle's `README.md`; go into its sub-docs only when the task needs the depth.

## The principles

| Principle | One-line | Governs | Doc |
|---|---|---|---|
| **Deep Modules** | Depth is leverage — hide a lot of behaviour behind a small interface, and give every module an explicit public surface. | Module *shape* and layout | [deep-modules/](./deep-modules/README.md) |
| **Pure Core, Persistent Shell** | Business logic transforms data into data; persistence is a caller decision at the edge. | A single *computation* | [pure-core-persistent-shell/](./pure-core-persistent-shell/README.md) |
| **Detachable Domain** | Each domain owns its entities and exposes them only through a data-shaped service; the model sits behind that interface and nothing outside touches it. | Dependency *topology* (ownership, boundaries) | [detachable-domain/](./detachable-domain/README.md) |
| **Config and Record** | Every entity is authored-and-portable (Config — keyed, no primary key on the value) or a context-bound row (Record — primary key inline as an opaque handle). | A data class's *identity* (and portability) | [config-and-record/](./config-and-record/README.md) |
| **Data Minimization** | Durable records hold references, not copies of personal data; keep only what the result depends on; privacy mechanisms fail closed. | What may *endure* (retention, copies, side-channels) | [data-minimization/](./data-minimization/README.md) |
| **Framework and Implementation** | The framework defines the shape of contracts and offers lockers for implementation data; implementations own all the semantics; found deliberately, then grow only on evidence. | The framework/implementation *boundary* (where behaviour lives) | [framework-and-implementation/](./framework-and-implementation/README.md) |
| **Single Chokepoint per Fact** | Each piece of stored data has exactly one place in the code that creates, changes, or deletes it; every button, job, and webhook calls that one place. | How many code paths may *change* a piece of data | [single-chokepoint-per-fact/](./single-chokepoint-per-fact/README.md) |
| **Acting on Behalf** | Every read and write an actor asks for goes through one thin on-behalf service that decides what this actor may see and do, over services that don't know who is asking. | *Who* may see and do what, and where that is decided | [acting-on-behalf/](./acting-on-behalf/README.md) |
| **Data View** | Every view of the data (a list, an overview, a section) is produced by exactly one data view that composes on-behalf services' answers into one presentation-agnostic view shape; pages, API endpoints and assistant tools only present it. | *What a view contains*, and where that is decided | [data-view/](./data-view/README.md) |
| **Explicit Names** | A variable is named after its declared type, a method starts with its action, and length is never a reason to shorten a name, so one line read on its own says what happens. | What a variable, property or method is *called* | [explicit-names/](./explicit-names/README.md) |
| **Safe Deletion** | A user may delete something only when nothing depends on it: refuse while something live uses it, archive when only history refers to it, so the history keeps resolving. | Whether and how a thing may be *removed* | [safe-deletion/](./safe-deletion/README.md) |
| **Retire, Don't Erase** | Don't drop a column or table in a migration — retire it (rename it, keep the data). Back up existing values before a migration changes them. Always keep a way back. | Whether a migration can be *rolled back* with its data | [retire-dont-erase/](./retire-dont-erase/README.md) |
| **Testing** | Where a test lives says what it covers; what it costs to run is declared inside it — so one subject keeps one test file. | The test suite's *shape* | [testing/](./testing/README.md) |
| **Deterministic Tests** | A test gives the same answer every time it runs; every input it doesn't own — clock, randomness, network, shared state — is controlled by default in the base test case, and opting out is written down. | Whether a test's *answer* can be trusted | [deterministic-tests/](./deterministic-tests/README.md) |
| **Documentation Placement** | Documentation lives at the altitude that matches it — code-describing docs beside the code, cross-cutting concepts centralized, a directory earning structure only as it grows. | Where documentation *lives* | [documentation-placement/](./documentation-placement/README.md) |
| **Discoverable Knowledge** | Knowledge no one can find might as well not exist — every document reachable from a known root and every reference self-describing. | The documentation *graph* | [discoverable-knowledge/](./discoverable-knowledge/README.md) |

## Which lens, when

| You are… | Reach for |
|---|---|
| Planning a feature or sprint that adds new public interface surface | Deep Modules (deletion test), then Detachable Domain |
| Creating a module / service / class, or asking "where does this go?" | Deep Modules → `decision-tree.md`, `directories.md` |
| Writing a computation (pricing, validation, transformation) | Pure Core, Persistent Shell |
| Letting code in one domain reach another domain's data | Detachable Domain |
| Designing a data class, an id, a reference, an export/import | Config and Record |
| Storing, copying, logging, or exporting anything that touches a person | Data Minimization |
| Building a host-with-plugins shape (engines, integrations, exporters) | Framework and Implementation |
| Adding a second code path that writes the same data (job + button, webhook + poller) | Single Chokepoint per Fact |
| Deciding who may see a field or take an action, adding a second way into the same data (API, assistant), or deciding what gets audited | Acting on Behalf |
| Building or reviewing a page, endpoint or tool that shows data, or a request handler that gathers data from several services | Data View |
| Naming a variable, property or method, or reading a line that only made sense after opening another file | Explicit Names |
| Adding a delete/remove action, or choosing between archive and delete | Safe Deletion |
| Writing a migration that drops a column or table, deletes rows, or changes existing data | Retire, Don't Erase |
| Adding or moving a test, or choosing what a test targets | Testing, then Deep Modules → `testing.md` |
| Writing a test that touches time, generated data or another service — or chasing a test that fails "for no reason" | Deterministic Tests |
| Writing or relocating a doc | Documentation Placement, then Discoverable Knowledge |
| Reviewing a diff | Walk the table top to bottom; name the lenses that apply and one finding each |

A useful order when designing something new: *Is the module deep?* (shape) → *Who owns this entity, and does everything reach it through that owner's data interface?* (topology) → *Is the inner computation pure?* (function) → *Is each entity a Config or a Record, and is its identity modelled accordingly?* (identity).

## How they relate

They compose rather than compete — each makes a different claim:

- **Deep Modules** is about the *interface*: how much a caller gains per unit of surface they must learn. Orthogonal to the others — a module can be deep and still let the database leak into its callers.
- **Pure Core, Persistent Shell** is about a *computation's insides*: no writes, no hidden reads, runs twice cleanly. A property of one function.
- **Detachable Domain** is about *dependency topology*: where a model is allowed to live and who may touch it, so the rest of the system depends on small data-shaped service interfaces rather than on models. It *uses* pure-core for its inner computations but makes a distinct claim — a querying service is not pure, yet its data interface still detaches its callers.
- **Config and Record** is about *a data class's identity*: whether a thing is portable authored configuration or a context-bound row, and how each carries (or withholds) its primary key. Pure-core and detachable-domain both defer their identity/reference questions to it.
- **Data Minimization** is about *what may endure*: whether a durable record, secondary store, or committed artifact is allowed to keep a copy at all. It leans on config-and-record for the snapshot-vs-reference mechanics and bounds the persistence decisions pure-core pushes to the shell.
- **Framework and Implementation** is about *a behaviour's home* in a host-with-plugins topology: the shared framework holds only what is invariant across implementations; each implementation owns its semantics; capability waits inside one implementation until a second consumer justifies promotion. It applies deep-modules' earned-not-speculative economics to that specific boundary.
- **Single Chokepoint per Fact** is about *how data gets changed*: however many ways the same piece of data can be created, changed, or deleted, they all call one shared place — built with the *first* caller (in deliberate contrast to framework-and-implementation's wait-for-the-second-consumer, because the write code is being written today either way). It sharpens detachable-domain one step finer: that lens stops outsiders touching a domain's models; this one stops the domain itself from growing two definitions of the same thing.
- **Acting on Behalf** is about *who may see and do what*: every read and write an actor asks for passes one thin on-behalf service that checks the actor, passes their limits down, and delegates. It builds on detachable-domain (the base service behind it is the entity's owning service) and stands in front of single-chokepoint (the on-behalf service calls the one writer and never writes itself). Where single-chokepoint says reads need no chokepoint for consistency, this lens gives them one for disclosure.
- **Data View** is about *what a view contains*: one data view per view composes the on-behalf services' answers (embed, never edit) into one view shape that any presentation can show. It builds on acting-on-behalf, which decides what each actor may see; a data view never looks at the actor itself.
- **Explicit Names** is about *what a line says on its own*: a variable is named after its declared type, a method after its action and what it acts on, so understanding one line needs no trip to another file. It complements deep-modules' naming page, which names the class itself; this lens names the variables, properties and methods that use it.
- **Safe Deletion** is about *removal*: whether a user may delete something, may only archive it, or is refused because something live uses it. It takes config-and-record's split as its vocabulary (records are the history it protects, frozen copies are how a configuration's past survives a change) and applies single-chokepoint to the question "may this go?" — one dependency check per entity, consulted by every remove path.
- **Retire, Don't Erase** is safe-deletion's counterpart for migrations: instead of dropping a column or table, retire it, and back up existing values before changing them, so a rollback brings the data back. Data-minimization bounds it: a backup keeps only what the rollback needs.
- **Testing** insists that where a test lives is derived from its subject, and that everything that *isn't* the subject — how expensive the test is to run — moves out of the path and into a declaration inside the test. It leans on deep-modules for *what* a test should target (a module's public promise, not its internals).
- **Deterministic Tests** is about *whether a test's answer can be trusted*: it may depend only on the code and on what the test sets up. It makes testing's move — the safe choice is the one you get by declaring nothing — for a test's inputs, borrows single-chokepoint's (each control lives once, in the base test case), and has least to police where pure-core has done its work, since a pure computation is deterministic by construction.
- **Documentation Placement** and **Discoverable Knowledge** are the documentation-side pair: the first decides where a doc lives, the second whether it can be found. They are to docs what deep-modules (shape) and detachable-domain (topology) are to source.

The code lenses share one tool — the data class as the medium across boundaries — which is why they look overlapping. The division: deep-modules shapes the surface, pure-core keeps a computation clean inside, detachable-domain decides what may cross the surface and who owns the model behind it, and config-and-record decides what identity the things crossing it carry.

## Stacks and bindings

The principle docs use an illustrative, language-neutral vocabulary for a module's parts — `modules/{domain}/` with `public/` (the surface), `services/`, `models/`, `data/`, `enums/`, `entrypoints/{http,cli,jobs,listeners}/`, `modules/` (sub-modules), `framework/` (variants), and a wiring file. Real directory names, the wiring mechanism, and the enforcement tool differ per stack. That mapping is a **binding**, and it lives beside the principle it binds, one directory per stack:

```
<principle>/bindings/<stack>/README.md      e.g. deep-modules/bindings/laravel/README.md
```

Bindings exist today for: **laravel** (`deep-modules`, `testing`, `retire-dont-erase`, `deterministic-tests`) and **nestjs** (`deep-modules`, `testing`).

How to use them:

1. Detect the stack from the repo (`composer.json` → laravel/php, `pyproject.toml` → python, `package.json` → node/typescript, `go.mod` → go, `Cargo.toml` → rust, …).
2. When you read a principle, check whether `<principle>/bindings/<stack>/` exists. If it does, read it alongside the principle — it tells you the real names and the enforcement mechanism.
3. If it does not, apply the principle directly: use the language's native visibility mechanism for the public surface (package-private, `internal/`, `pub`, index re-exports, `__all__`), the stack's idiomatic wiring, and the test runner's tagging for cost tiers. At the end of the task, propose a new binding file for that stack in the same shape as the laravel one — but only from what you actually verified in that codebase; do not invent conventions.

## Rules for editing these docs

- Principles are stack- and project-agnostic. Nothing outside `bindings/` may name a language, framework, tool, company, or product. The repo's `check.sh` enforces this.
- Every stack-specific mechanic goes into a binding, never inline.
- A new principle earns a place here when it is a **reusable lens** — a way of evaluating many designs, not a rule about one feature or framework. Keep examples generic, add a directory, and add a row to both tables above.
