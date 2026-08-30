---
type: concept-explainer
title: Detachable Domain — Detaching from Other Domains
description: How a domain should reach a neighbour only through its published service and by stable identifier, never querying or mutating another domain's models.
---

# Detachable Domain — Detaching from Other Domains

> **A domain reaches a neighbour only through that neighbour's published service, referencing it by a stable identifier carried as data. It never queries another domain's tables, and never creates, mutates, or deletes another domain's models.**

This is the second of two axes of the [detachable-domain](./README.md) principle. The first — isolating an entity behind its owning domain's service — lives in [`database-dependency.md`](./database-dependency.md). This one governs how one domain depends on another. It is the cross-domain extension of the same ownership rule: each domain owns its entities; outsiders go through the owner.

## What it protects — reviewability first

The everyday payoff is a **legible dependency graph**, not a hypothetical microservice. When Domain A can reach Domain B only through B's published service, the edges in the dependency graph are few and named. Reviewing a change to A means reading the handful of B's surfaces it touches — not auditing whether A quietly reached into B's tables somewhere. The opposite (any domain querying or writing any other domain's models) makes the graph a dense mesh where every change is potentially global and nothing can be reviewed in isolation.

The secondary, longer-term payoffs follow from the same discipline:

- **Separate databases.** A and B need not share a schema, a connection, or an id space.
- **Separate services.** A domain can move into its own process, others reaching it over the network — because nothing in their logic assumed co-location.
- **Isolated tests.** A behaviour in A can be exercised with B represented as a few hand-built data classes, not a seeded sub-graph of B's tables.

The moment A's code looks up B's model by id and reads a field off it, joins across the boundary, or creates a row in B's table, all of this is lost at once: the domains now share a database, a process, and an id space, and neither can move or be reviewed without the other.

## Where the boundary is

A "domain" here is concrete: a top-level module directory under the modules root (see [`deep-modules`](../deep-modules/README.md)). The boundary between two domains is the boundary between two such directories. Two practical consequences:

- **Code that predates the convention counts as one grandfathered domain.** References among that code are *intra*-domain by default — this principle does not ask you to retrofit stable identifiers across a legacy codebase.
- **If you cannot point at two distinct top-level module directories, you are inside one domain.** Use local ids and direct (in-domain) references; the cross-domain rules below do not apply yet.

This keeps the central rule decidable: you locate a boundary by looking at the directory structure, not by adjudicating an abstract notion of "domain."

## Intra-domain vs cross-domain references

> **References *within* a domain may use local database ids. References that *cross* a domain boundary must use stable, environment-independent identifiers.**

Inside one domain everything shares an id space, so a local autoincrement id is the correct, preferred default — do not mint UUIDs for intra-domain references. Across a boundary a local id is a trap: `42` in A's id space is a different row (or none) in B's.

For *what* a stable cross-boundary identifier should be — natural key vs. minted id, and why a database autoincrement or a third-party id is unsuitable — follow the single source of truth in [`config-and-record`](../config-and-record/README.md). In short: prefer a genuine natural key when one exists (a Config's authored key), otherwise mint your own identifier (UUID/ULID) at creation time. Do not legislate identity separately here; defer to that principle so they never give conflicting defaults.

One consequence to state plainly: a cross-domain reference gives up **database-enforced referential integrity**. A foreign key cannot span two databases or two services. Once B is reachable only by a stable id behind a service, "the referenced thing still exists" is guaranteed by B's contract and your handling of its absence — not by an FK. Detaching trades an enforced invariant for one you now own.

## The rules

1. **Reach a neighbour only through its published service.** Never import, query, or mutate another domain's models. To *read*, ask its service; to *change* something it owns, tell its service.
2. **Cross-domain references are stable identifiers carried as data.** Logic passes them through input → output; it never dereferences them itself.
3. **Resolve cross-domain reads at the edge, then pass the data in.** When A needs a fact from B, A's shell asks B's service and hands the resolved data class to A's logic. A's logic does not call B.
4. **Express cross-domain writes as intent, dispatched to the owner.** When A needs B to change, A produces an intent (a data class, or a direct call to B's service method) that B's service executes against B's models. A never writes B's rows.
5. **No joins across a boundary.** A query spanning two domains' tables welds them into one database forever.

## Worked example — cross-domain read

Two domains: **Ordering** (places and prices orders) and **Catalog** (owns products and prices). Ordering needs a product's price.

**Coupled — Ordering reaches into Catalog:**

```text
// Inside Ordering's logic — queries Catalog's model directly.
function priceLine(productId: int, quantity: int) -> float:
    product = Product.find(productId)     // Catalog's model, from Ordering
    return product.price * quantity
```

Ordering now depends on Catalog's model, table, and database. Catalog can't move; Ordering can't be tested or reviewed without Catalog's rows.

**Detached — stable reference, resolved at the edge:**

```text
// Published by Catalog — its contract to the outside world.
data ProductPriceData:
    productRef: string      // Catalog's stable, portable product id
    unitPrice:  float
    currency:   string

// Inside Ordering's pricing logic — knows nothing of Catalog's storage.
function priceLine(product: ProductPriceData, quantity: int) -> LineTotalData:
    return LineTotalData(
        productRef: product.productRef,        // carried through, never dereferenced
        amount:     product.unitPrice * quantity,
        currency:   product.currency,
    )
```

Ordering's shell resolves prices through Catalog's service and passes `ProductPriceData` into the pure logic. The stored reference is `productRef` — stable whether Catalog is local or remote.

## Worked example — cross-domain write

Ordering must not insert or update Catalog's rows to reserve stock. It expresses the intent and lets Catalog's service execute it:

```text
// ❌ Ordering writing Catalog's model — the coupling this principle forbids.
product = Product.find(productId)
product.reserved += qty
product.save()

// ✅ Ordering tells Catalog's service; Catalog owns the write.
catalog.reserveStock(ReserveStockData(productRef: ref, quantity: qty))
```

Catalog's `reserveStock` is the only code that touches Catalog's models; it owns the invariants (enough stock? concurrency?) in one place. Ordering depends only on the call and its data — not on how Catalog stores stock. This is the exact failure mode to watch for: an agent told to "reserve stock" will reach for `Product.find(...).save()` from Ordering. The fix is always: find the owning domain's service and express the intent to it.

## What extraction does *and does not* buy you

The honest claim is narrow and real: **the business logic survives a service split unchanged.** `priceLine` does not change a line whether Catalog is a local call or a remote one — that is the win, and it is worth a lot.

What extraction does **not** make free, and what the *shell* must still do, is everything the network boundary introduces:

- **Batching.** A per-item contract (`getPrice(ref)`) becomes an N+1 the instant Catalog is remote — 40 line items, 40 calls. Design cross-domain contracts as **set-shaped from day one** (`getPrices(refs): Collection`), and resolve in bulk, once per request, not once per loop iteration or pipeline stage.
- **Failure semantics.** A local lookup either returns or fails the request cleanly. A remote one adds timeouts, retries, and partial failure — new shell code and new result states (`PriceUnavailableData`).
- **Consistency and freshness.** Co-located reads were one snapshot; split reads can disagree (a price changed mid-order), and the write can't share a transaction with the neighbour. If a result must be reproducible later, persist the resolved cross-domain snapshot alongside it — don't re-resolve.
- **Contract versioning.** A data class that is *also* a cross-service contract is no longer freely refactorable: independent deploys mean a renamed field breaks a consumer you can't update in lockstep. Once a contract spans a real service boundary, breaking changes need parallel old/new support.

So: extraction is mechanical *for the logic*, and real engineering *for the shell*. Treat "the boundary might become a service boundary" as a reason to keep references stable and contracts set-shaped — not as a promise that the split itself is a one-line edit.

## The extraction test

> **If this domain's neighbour moved to a different database or service tomorrow, what in this domain would have to change?**

The honest answer: only the shell code that *resolves* or *dispatches to* the neighbour — never the business logic, never the stored references. If business logic would change, it is reaching across the boundary; if a stored reference would break, it is a local id where a stable one was needed; if you'd face an N+1, the contract was per-item where it should have been set-shaped.

## Review red flags

- A domain importing, querying, or **mutating another domain's ORM model** (find / create / save / delete on B's model from inside A).
- A **join across two domains' tables** anywhere.
- A **local autoincrement id stored as a cross-domain reference**, or an **external-system id** used as your own.
- A **per-item cross-domain resolution** in a loop (an N+1 waiting for extraction) where a set-shaped contract belongs.
- A test for A that **seeds B's tables** to set up its scenario.
- A "shared" model or table that **two domains both write**, instead of one owning it and publishing a contract.
