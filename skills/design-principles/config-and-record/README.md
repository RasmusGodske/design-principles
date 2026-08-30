---
type: concept-explainer
title: Config and Record
description: How to tell whether an entity is an authored-and-portable Config or a context-bound Record, and how each models its identity and primary key.
---

# Config and Record

> **Every entity is one of two kinds. *Config* is authored, portable, and identified by a key you mint — it survives being copied into another environment. *Record* is a context-bound occurrence whose identity is its row. Model the primary key accordingly: keep it off Config, carry it inline on Record.**

This is the full convention: the test that splits the two kinds, how each models identity, and worked examples. The diagnostic questions and review red flags are collected in [The litmus tests](#the-litmus-tests) below.

This principle is about **a data class's identity and portability** — what makes a thing *what it is*, and whether that identity travels. It is *not* about a computation's insides ([`pure-core-persistent-shell`](../pure-core-persistent-shell/README.md)) or about who may touch a model ([`detachable-domain`](../detachable-domain/README.md)). Both of those defer the question "how do I identify and reference things?" to *here* — this is the single home for identity, so the set never gives conflicting defaults.

## The test that splits them

One question separates the two kinds:

> **If I copied this and pasted it into a different environment (another tenant, another database, a fresh install), would it still mean something?**

```
        ┌───────────── COPY-PASTE TEST ─────────────┐
        │  "Paste this into another environment —    │
        │   does it still mean something?"           │
        └────────────────────────────────────────────┘
                 │  yes                    │  no
                 ▼                         ▼
            ┌─────────┐               ┌─────────┐
            │ CONFIG  │               │ RECORD  │
            │ authored│               │ a row,  │
            │ template│               │ an actor│
            └─────────┘               └─────────┘
        identity = a key you mint    identity = the row itself
        no primary key on the value  primary key carried inline
        wrap to attach a key: Persisted<T>
```

A report template, a pricing ruleset, a form definition, a workflow definition — paste any of these elsewhere and they still describe the same thing. A user, an order, a synced third-party contact, an audit event — pasting one into another environment is nonsense; it refers to a specific thing in *this* world.

## Config — authored, portable, key-free at rest

A **Config** is configuration or authored vocabulary. The system (or a person) *defines* it.

- **Its identity is its content plus an authored key** — a name you mint (`"region"`, `"net-revenue"`), unique within a scope, not a database row number. The key is part of the portable thing; the primary key is merely *where this copy happens to be stored*.
- **The pure value carries no primary key.** That key-free form *is the shareable artifact* — serialize it, hand it to another environment, instantiate it there. The whole object graph can be built in memory, cross-reference itself by authored key, be validated and simulated, and persisted in one transaction at the end — or thrown away at zero cost.
- **When a caller genuinely needs the stored primary key, wrap it** — `Persisted<T>` carrying `{ id, value }`. The wrapper exists precisely *because* the key is separable from the identity. It is a Config-only construct, and you build it only when a real consumer needs the key — not speculatively.

```jsonc
// A Config value — no primary key; references other things by authored key
{
  "key": "quarterly-summary",
  "group_by": "region",
  "columns": ["net-revenue", "order-count"]
}
```

## Record — a context-bound occurrence, key inline

A **Record** is a specific occurrence or actor: a user, an order, a synced document, a logged event.

- **Its identity is the row.** There is no meaningful authored key — its primary key (optionally an external-origin pointer) *is* what it is. So the key lives **inline** on the value as a plain `id`.
- **That `id` is an opaque correlation handle, not a value to compute on.** Real primary key in production, a synthetic one in a simulation or sandbox; used only for *attribution* in outputs ("item #1 contributed X to actor #2") and for *grouping/equality* ("partition by actor"). Logic never does arithmetic on it and never dereferences it against a database. A synthetic handle must be indistinguishable from a real key to everything downstream — that is what lets a sandbox feed the same logic real and fictional input alike.
- **No `Persisted` wrapper.** There is no portable identity to separate the key *from*; the key is the identity.
- **An external-origin pointer (e.g. a third-party system's id) is an orthogonal attribute some Records carry** — a backward pointer to where the row was synced from. It is *not* a portable identity: it only means something pointing back at its source system, so it never makes a Record into a Config.

## Both are buildable with zero rows — for different reasons

This is the payoff that ties the principle to [`pure-core-persistent-shell`](../pure-core-persistent-shell/README.md). A computation `f(config, input) → result` can run entirely on hand-built data, no database, because **both kinds are purely constructible** — but the reasons differ:

- **Config** is constructible because its identity is a portable authored key the logic reads by name.
- **Record** is constructible because its `id` is an opaque handle the logic only passes through — fabricate a synthetic one and nothing downstream can tell.

The resolving shell hydrates Records from the database (real keys) or a sandbox fabricates them (synthetic ones); the same pure logic runs either way.

## Referencing other things — by key, never by row number

What crosses a data contract refers to other things **by authored key (Config) or by handle (Record)** — never by a raw database row number used as the reference language.

```jsonc
// ❌ environment-bound — "17" only resolves in one database
{ "source": 4182, "group_by_field": 17 }

// ✅ portable — resolves anywhere the named things exist
{ "source": "orders", "group_by_field": "region" }
```

- **Prefer a genuine natural key** when the domain already names the thing.
- **When nothing has a natural name, mint a generated id at authoring time** (UUID/ULID) — created by the code authoring the data, *before any row exists* — not a database-assigned key at insert time. The distinction is the whole point: a creator-minted key lets part A reference part B in memory, with no persist-first dependency cycle and no live database participating in authoring.
- **Database-assigned primary keys are not banned** — they are fine as internal storage (joins, foreign keys *between rows*). The rule is only about the *reference language inside data contracts*.

## The rules

1. **Classify every entity by the copy-paste test** — Config (paste = meaningful) or Record (paste = nonsense).
2. **Config carries no primary key in its pure form.** Identify it by an authored key. To attach the stored key, wrap it (`Persisted<T>`), and only when a caller needs it.
3. **Record carries its `id` inline as an opaque handle** — real or synthetic, used for attribution and grouping only, never computed on, never dereferenced in logic. No wrapper.
4. **Reference other things by key or handle, never by a raw row number** as the reference language inside a data contract. Mint creator-side ids when no natural key exists.

## The litmus tests

- **The copy-paste test** — paste it into another environment; still meaningful? Yes → Config; no → Record.
- **The authoring test** (Config) — can the whole graph be built in memory, cross-referencing itself by key, with zero rows, and persisted in one transaction at the end? If authoring needs a live database in dependency order, a database-assigned key has leaked into the reference language.
- **The synthetic-handle test** (Record) — replace every `id` with a fabricated one; does any logic break? If it does, an opaque handle is being treated as a value.

## Relationship to the other principles

- [`pure-core-persistent-shell`](../pure-core-persistent-shell/README.md) — a **computation's insides** (no writes, no hidden reads). It depends on this principle for *why* its inputs are portable: Config keys and Record handles are exactly what let a core run on hand-built, JSON-serializable data. Pure-core states the constraint ("no models, no row-numbers as reference language") and defers the *how* of identity to here.
- [`detachable-domain`](../detachable-domain/README.md) — **dependency topology** (where a model lives, who may touch it). It requires that things crossing a boundary are "data classes or stable identifiers"; *which* identifier — authored key vs minted id, and why a row number or third-party id is unsuitable across a boundary — is this principle's answer, which it defers to.
- [`deep-modules`](../deep-modules/README.md) — the **interface surface**. Orthogonal: a module can be deep regardless of how its entities model identity.

## A note on scope

Applies to entities as they are designed, written, or touched. Existing code that mixes the two kinds (a primary key inlined on something that is really a Config, a portable thing pinned to one database) is grandfathered — classify and correct as you pass through, not in a dedicated rewrite. The classification is near-universal and cheap; the `Persisted<T>` wrapper and the full pure-construction apparatus are only worth it where there is real logic to test, a boundary to cross, or a portability/sandbox need.
