---
type: concept-explainer
title: Pure Core, Persistent Shell
description: Why business logic should transform data into data while persistence stays a caller decision at the edge, and how to structure a capability that way.
---

# Pure Core, Persistent Shell

> **Business logic transforms data into data. Persistence is a decision the caller makes at the edge — never something the core does itself.**

A capability built this way has three parts:

```
            ┌─────────────────── SHELL (impure, thin) ───────────────────┐
            │                                                            │
 DB / APIs ─┼─▶ resolve input ─▶ ┌────── PURE CORE ──────┐ ─▶ persist? ──┼─▶ DB
            │   (reads only)     │ f(config, input)      │    caller's   │
            │                    │        → result       │    policy     │
            │                    │ no writes,            │               │
            │                    │ no hidden reads       │               │
            │                    └───────────────────────┘               │
            └────────────────────────────────────────────────────────────┘
```

- **Pure core** — a function (or service) of the form `f(config, input) → result`. Everything it needs arrives as an argument; it writes nothing, dispatches nothing, and reaches into no global state.
- **Resolving shell** — gathers the input: queries the database, calls APIs, snapshots configuration. Impure by nature, but **reads only**.
- **Persisting shell** — takes the core's result and stores whatever the *caller's policy* says to store. The core never knows whether its output was kept.

## The defining constraint: data in, data out

The core's inputs and outputs are **plain data contracts** — data classes / DTOs, fully serializable to JSON. Never persistence objects (ORM models, active records), never database ids as the primary way of referring to things.

This single constraint is what makes the pattern work. A persistence object dragged into business logic smuggles in everything the pattern exists to exclude: an open connection, lazy-loaded relations (hidden queries), global scopes, mutable shared state, and identity that only means something inside one particular database. A data class carries none of that — it is *just the facts*, and the type definition **is** the interface: a caller can see exactly what the core needs, and nothing can sneak in beside it.

## What the constraint buys you

These properties hold in any language or project, and each one is routinely lost the moment a database object crosses into the logic:

| Property | Why it falls out |
|---|---|
| **Testable without infrastructure** | Tests hand-build input and assert on output. No database to spin up, no factories-for-everything, no fixtures coupling tests to each other. |
| **Portable / exportable** | Input and output serialize to JSON, and nothing in them is a row id that only resolves in one environment. A configuration or result can be exported, imported elsewhere, archived, attached to a bug report, or replayed years later. |
| **Runs anywhere** | A core with no environment dependency can move runtimes — another service, a queue worker, a CLI, even the frontend — because "where it runs" stopped mattering when the dependencies became arguments. |
| **Simulation and sandboxes for free** | Run the core on draft config or fictional input: zero side effects, zero cleanup. Nothing was created, so nothing needs deleting. AI agents can build → run → inspect → iterate in a tight unsupervised loop, safely. A sandbox is not a feature you build; it is the pure core called with persistence set to "no". |
| **Safe replacement of high-stakes logic** | A new implementation runs in shadow beside the legacy one on identical input, diffing results, touching nothing. Prove equivalence, then swap. |
| **Reproducible, auditable** | Same config + same input → same result, forever. A frozen snapshot of both *is* the audit trail and the bug report: "run this JSON" beats "restore this database". |

## The caller persistence policies

The same pure core serves every context; only the shell's policy differs:

| Caller | Policy |
|---|---|
| Sandbox / simulation / draft preview | Persist **nothing** |
| Shadow run / parity validation | Persist **diffs only** |
| Production | Persist **per domain policy** |
| Tests | Persist nothing; assert on the returned result |

A corollary: "how often is this saved?" is never the core's concern and never constrains the design of the core's result type. Design the result for the richest consumer; let each shell keep less.

## Reads vs. writes

**Side-effect-free means no writes.** Reads are not side effects — but they belong in the *resolving shell*, not the core:

- A core that queries mid-computation cannot run on fictional input, cannot be tested without a database, and hides part of its input contract.
- Resolve everything first, pass it in. If the core needs exchange rates, they travel inside the input object — the core does not fetch them.

A practical guard: wrap a core call in a query log and assert zero queries were issued.

## Common dilemmas

Recurring questions when making something pure, and the practice that resolves them.

### "How do I reference other things without database ids?"

A row number only means something inside one particular database, so the moment a config or result says `"source": 4182` it stops being portable — and a core that consumes it can no longer run on hand-built or exported input. The fix is to reference things by an authored key or an opaque handle rather than by row number, and to mint creator-side ids when nothing has a natural name.

This is exactly the subject of [`config-and-record`](../config-and-record/README.md), which is the single home for identity guidance. Pure-core states the *constraint* — inputs and outputs carry no models and no row-numbers-as-reference-language; defer to config-and-record for the *how* (Config vs Record, authored keys vs minted ids, the persist-first cycle, and the `Persisted<T>` wrapper). Following it is what makes a core's input pass the JSON and fictional-input tests below.

## Litmus tests

1. **The double-run test** — can this run twice in a row with no consequence? If the second run behaves differently or leaves extra rows, something impure is inside the core.
2. **The JSON test** — can the entire input be serialized to JSON, shipped to another machine, and produce the same result there? If something would break — a model id that doesn't exist there, a connection that isn't open — that something is a hidden dependency.
3. **The fictional-input test** — can the core run on entirely hand-built input, zero rows in any database? If not, a hidden read is masquerading as logic.
4. **The agent-loop test** — could an AI agent call this in a `while` loop, unsupervised, and leave the system untouched? If you hesitate, name the side effect causing the hesitation and move it to the shell.

## Accepted impurities — document them loudly

Sometimes full purity is not economical (legacy semantics that must be preserved exactly, a dependency that cannot yet be resolved up front). The rule is not "never impure"; it is **never silently impure**:

- Every accepted impurity is listed in the module's docs, with the reason and the consequence for callers (e.g. "simulating with function X writes rows Y — sandbox callers must stub or reject it").
- An impurity that punctures a sandbox guarantee is handled at the sandbox boundary (stub, reject, or warn) — not discovered by the user.
- Accepted impurities are debt with a destination: each one names what would have to exist for it to be removed.

## When it applies — and when not

**Apply when designing** anything that computes, evaluates, decides, transforms, or aggregates: calculation engines, eligibility rules, pricing, scoring, validation pipelines, import/transform steps, report generation.

**Don't contort** these into the pattern:

- **CRUD glue** — a controller that validates and stores a form has no core worth extracting. Beware shallow "pure" wrappers created only for testability — see [`deep-modules`](../deep-modules/README.md).
- **Inherently temporal workflows** — an approval flow *is* state advancing over time; its configuration can be validated purely, but "running" it purely is meaningless.
- **Legacy code** — grandfathered, per the legacy policy in [`deep-modules/legacy-code.md`](../deep-modules/legacy-code.md). The principle guides *new* designs and *new seams* cut into old code (extract a pure core beside the legacy path; validate side-by-side; swap).

The honest summary: not everything has a pure core, but far more things do than typically get one. When logic computes something, default to giving it a data-class interface and pushing reads before it and writes after it — and treat every exception as a documented decision, not a drift.
