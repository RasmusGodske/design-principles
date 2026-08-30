---
type: concept-explainer
title: Detachable Domain
description: Why each domain should own its entities and expose them only through a data-shaped service, and how that keeps the dependency graph reviewable.
---

# Detachable Domain

> **Each domain owns its entities and exposes them only through a data-shaped service. Isolating the model — and other domains — behind small, named interfaces makes the dependency graph reviewable today, and the domain relocatable tomorrow.**

This is the full convention: the model, the two axes in depth, and worked examples.

This principle is about **dependency topology** — where the model is allowed to live, who may touch it, and therefore what the rest of the system depends on. It is *not* "make every function pure"; that is [`pure-core-persistent-shell`](../pure-core-persistent-shell/README.md), which this principle uses for the computations that have real logic. The two are distinct: a service that issues a query is not pure, yet if it exposes a data-in/data-out interface, everything on the other side of it is detached from the model — which is the property this principle is after.

## The idea

A domain depends on two things it should hold at arm's length:

- **its database** — the rows that store its own entities, and
- **its sibling domains** — the other parts of the system it references.

In both cases the discipline is the same: **go through the owner's service, and speak in data classes.** A domain's own models are touched only by its own service; a neighbour's entities are reached only through the neighbour's service. Everything that crosses a boundary is a data class or a stable identifier — never a model, never a cross-domain query.

```
        Controller / another domain / job / test
                        │  speaks data classes (in and out)
                        ▼
        ┌──────────── OWNING DOMAIN (a module) ─────────────┐
        │  Service (public surface) ── the only code that    │
        │     touches this domain's models                   │
        │     · reads/writes rows  · runs pure inner logic   │
        │  Models (internal) ── never imported from outside  │
        └────────────────────────────────────────────────────┘
              ▲ detach from the DATABASE        ▲ detach from OTHER DOMAINS
              │ model isolated behind the       │ reach neighbours only through
              │ service's data interface        │ their service, by stable id
```

## What it buys you — ownership and reviewability first

- **Single-owner control.** Every change to an entity flows through one service, so invariants, validation, events, and audit live in one place — not re-implemented or forgotten at every call site that grabbed the model.
- **A reviewable dependency graph.** Reaching a domain only through its small public surface means reviewing a change is reading the surfaces it crosses, not auditing whether it reached into someone's tables. (Before clear boundaries, anything could read or write any model from anywhere; nothing was internal, so reviewing one change could mean reviewing everything.)
- **DB-free, fast tests.** Real logic takes data classes, so tests hand-build inputs; controllers are tested against a mocked service returning data classes.
- **Construct in memory; persist later — or never.** A valid entity graph can be built and reasoned about before any row exists — previews and "what-if" flows without throwaway rows.
- **Relocatable (the bonus, not the headline).** Because callers depend only on the service's data interface, the service can later fetch from another service instead of the local DB and its callers never know. Extraction stops being a rewrite — but it is not free; see [`domain-dependency.md`](./domain-dependency.md) for the honest cost.

## The two axes

- **[Detaching from the database](./database-dependency.md)** — an entity's models are internal to its owning domain and touched only by that domain's service; the service speaks data classes in and out, even when it queries inside. Covers the write path (create/mutate through the owning service), search/list (the query lives in the service, behind a data interface), DB-arbitrated invariants (uniqueness/FK/locking), and when *not* to add ceremony.
- **[Detaching from other domains](./domain-dependency.md)** — reach a neighbour only through its published service, by a stable identifier; resolve its reads at the edge, dispatch its writes as intent. Covers the operational domain boundary, intra- vs cross-domain references, and the real cost of a future service split.

The axes are worth assessing separately — a domain can be clean on one and coupled on the other.

## The rules

1. **Each entity is owned by one domain and changed only through that domain's service.** No HTTP handler and no other domain calls create / save / delete / query on an ORM model it does not own. This is near-universal — it holds even for plain CRUD.
2. **Services speak data classes — data in, data out — even when they query or write inside.** That data interface is what detaches callers from the model.
3. **Where there is real logic, the inner computation is pure** (`f(data) → data`, no queries, no model access) — this is [`pure-core-persistent-shell`](../pure-core-persistent-shell/README.md). Don't manufacture one for a row-to-row passthrough.
4. **Reach other domains only through their service, by stable identifier.** Resolve their reads at the edge and pass the data in; dispatch their writes as intent. Never query or mutate another domain's models. For *what* identifier to use, defer to [`config-and-record`](../config-and-record/README.md) — the single home for identity guidance — so the principles never conflict.

## The litmus tests

Assess each axis on its own:

- **Database axis** — *Could a caller of this domain be tested with the service mocked to return data classes, and could the inner logic run on a hand-built graph with zero rows?* If a caller needs real rows, it is reaching past the service to a model.
- **Domain axis** — *If a neighbour moved to a different database or service tomorrow, would anything but this domain's resolve/dispatch shell change?* If business logic or a stored reference would change, it is reaching across the boundary.

## Relationship to the other principles

- [`pure-core-persistent-shell`](../pure-core-persistent-shell/README.md) is about a **computation's insides** — no writes, no hidden reads, runs twice cleanly. Detachable-domain is about **dependency topology** — where the model lives and who depends on it. They share one tool (the data class) but make different claims; detachable-domain *uses* pure-core for its inner computations.
- [`config-and-record`](../config-and-record/README.md) is about **a data class's identity and portability** — what crosses a boundary is a "stable identifier", and *which* identifier (authored key vs minted id, never a raw row number across a boundary) is its answer. This principle defers all identity/reference guidance to it.
- [`deep-modules`](../deep-modules/README.md) provides the **mechanism**: a domain's service is its small public surface, its models are internal. Deep-modules says the surface should be small and powerful; detachable-domain says what crosses it is data and stable identifiers, never models or local ids.

## A note on scope

Applies to **new** domains (a top-level module directory under the modules root — see [`deep-modules`](../deep-modules/README.md)) and to code as it is written or touched. Code that predates the convention counts as one grandfathered domain; this convention does not mandate retrofitting it. Surface coupling when you are already in the area; do not rewrite a working domain solely to detach it. And do not over-apply: the *ownership* rule is near-universal, but the full data-class-twin-plus-pure-computation apparatus is only for where there is genuine logic, a boundary to cross, or a real testability need — see the "does not mean extra ceremony" guidance in [`database-dependency.md`](./database-dependency.md).
