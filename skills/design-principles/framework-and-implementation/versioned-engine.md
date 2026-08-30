---
type: concept-explainer
title: The Versioned Engine
description: A framework-and-implementation founding pattern for maximal uncertainty — when a core capability must keep evolving but its future shape is unknowable, the seam itself becomes the only invariant. Implementations become permanently-identified engines that coexist, and every authored record stays bound to the engine it was created under.
---

# The Versioned Engine

> **When you cannot know what the implementation should look like — but you know the capability is core and will evolve — found only the seam. Implementations become permanently-identified engines; records bind to the engine they were authored under; evolution means founding a new engine beside the old, never rewriting the old in place.**

This is a *founding pattern* within [`framework-and-implementation`](./README.md) — one specific way to apply the principle, for one specific situation. Most frameworks don't need it; read [when it applies](#when-it-applies--and-when-not) before reaching for it.

## The situation it solves

The [main principle](./README.md) says a foundation holds only invariants you have evidence for. But sometimes there is a capability where you have **no evidence at all about the shape** — no prior systems to found from, and planning everything up front is infeasible — while three things are still certain:

1. The capability is **core** — it will be developed and iterated on for the life of the product.
2. It **will change** in ways you cannot predict — not just grow, but potentially be rethought wholesale.
3. What customers set up today **must keep working** exactly as configured, even after the capability is reinvented.

Trying to design the "right" implementation up front under these conditions produces exactly the over-founded failure: guessed semantics that the future has to fight. The versioned engine takes the opposite bet — **a bet on change itself**.

## The shape

The less you know, the smaller the framework — and this is the limit case. The framework declares almost nothing:

- **Engines exist.** An engine is a complete, self-contained implementation of the capability — not a strategy for one detail, but the whole thing: logic, settings, display, storage shape.
- **Every engine has a permanent key.** The key is minted at founding, never renamed, never reused. A registry resolves keys to engines; an unknown key is a data bug that fails loudly, not a null.
- **Every authored record binds to its engine.** A record (a configuration a user created, a running instance) stores the engine key it was authored under and is evaluated by that engine forever — unless deliberately migrated.

Everything else — every semantic decision — lives inside an engine. The framework has no opinion about what an engine does; it only routes each record to the engine that owns it.

## The rules that make it work

- **New version = new engine.** Evolution happens by founding engine v2 *beside* v1 with a new permanent key — never by rewriting v1 in place. v1 keeps running, byte-for-byte faithful to what its records were authored against.
- **Coexistence is the normal state, not a transition.** Old and new engines run side by side indefinitely. Retiring an engine is a deliberate migration project (move or expire its records), not a deploy.
- **Engines share through the framework only.** If two engine versions want common code, that code is promoted into the framework under the main principle's rules (it has two real consumers — the bar is met). Engines never reach into each other.
- **Migration is the one sanctioned bridge.** Migrating a record from v1 to v2 requires reading v1's authored terms and authoring v2's — which two engines that "never reach into each other" cannot do alone. The transform lives in a dedicated migration module *outside both engines*, depending only on their public surfaces (an export/read surface on the old engine, the normal authoring surface on the new). It is written for the migration project and retired with it.

**Promotion trades away part of the stability promise — price it consciously.** The byte-for-byte guarantee is *structural* only while everything a record's pricing depends on is frozen with its engine. The moment shared code is promoted (both engines want proration math), any future change to that shared piece can silently change v1's outputs — the guarantee just quietly degraded back to regression-test vigilance. So under a versioned engine, promoted code inherits **the strictest consumer's stability discipline**: version the promoted piece like an engine (`proration.v1` — the engines that adopted it stay pinned to it forever; a behavior change mints `proration.v2`, adopted only by engines founded after it), or don't promote at all. Duplication inside engines is not a failure here — it is often the cheapest honest price of the promise. What is never acceptable is a silent behavior change flowing into engines whose records were authored against the old behavior.

What this buys, concretely: big chunks of the capability can be swapped, improved, or completely rethought without being stuck on — or endangering — the previous version. The cost of a wrong guess drops from "unwind an abstraction everything depends on" to "found a better engine and stop authoring new records on the old one."

## The founding gradient

This pattern completes the founding story in the main principle into a gradient:

| What you know | What you found |
|---|---|
| The domain well, from experience | Rich contracts — the invariants you have evidence for |
| Some invariants, uncertain details | Contracts for the invariants; lockers for the rest |
| Almost nothing about the shape — only that it's core and will evolve | The seam alone: engines, permanent keys, record binding |

It also sharpens the second-implementer litmus test: here, **the second implementer arrives from the future.** Even while only one engine exists, the seam must let a wholly different v2 exist without the framework changing — that is the entire point of having it.

## When it applies — and when not

**Reach for it when all three certainties above hold**: core capability, unpredictable evolution, and authored records that must survive reinvention untouched. Calculation and rules engines, pricing models, scoring or eligibility rules — domains where the *product itself* is still being discovered.

**Don't reach for it when:**

- **The domain is well understood** — found real contracts from experience instead; a versioned seam adds indirection where knowledge was available.
- **Records can be migrated cheaply** — if updating existing data to a new shape is routine and safe, in-place evolution is simpler than eternal coexistence.
- **The capability is peripheral** — the seam, registry, and coexistence discipline are overhead only a long-lived core feature pays back.
- **The plural is vendors, not versions** — a framework whose implementations differ in *space* (one per external system) is the main principle's ordinary case; it needs contracts and lockers, not engine versioning. The two can combine, but don't confuse them.
