---
type: concept-explainer
title: "Example: The Versioned Pricing Engine"
description: A full walkthrough of the versioned-engine founding pattern — a core pricing capability whose future shape is unknowable, founded as a seam with permanently-identified engines, so a wholesale rethink ships beside the original while every signed contract keeps pricing exactly as sold.
---

# Example: The Versioned Pricing Engine

*The founding limit-case of [framework-and-implementation](../README.md): implementations plural in **time**. This example walks the [versioned-engine](../versioned-engine.md) pattern end to end — why normal founding fails, what the seam looks like, and what happens when the capability is rethought wholesale.*

## The scenario

A subscription product prices customer contracts. Pricing is the heart of the business — and the business is young: nobody knows whether next year's model is flat tiers, usage-based, seat-based, or something the market hasn't taught them yet. Meanwhile, every contract signed today is a promise: **it must price exactly as sold for its entire life**, whatever the product does next.

Check the three certainties that justify this pattern:

1. **Core?** Yes — pricing will be developed for the life of the product.
2. **Unpredictably evolving?** Yes — the *model itself* is undiscovered, not just its parameters.
3. **Authored records must survive reinvention?** Yes — signed contracts cannot re-price.

All three hold. (If any didn't, this pattern would be overhead — see [when not](#when-this-would-have-been-wrong).)

## Why normal founding fails here

The main principle says: found the invariants you have evidence for. But the founder's honest inventory comes up almost empty. Is pricing per-seat? Metered? Tiered? Does a "discount" exist as a concept? Every candidate contract method — `tiers()`, `unitPrice()`, `discountFor()` — is a guess that the future will have to fight. Founding rich contracts here *is* the over-founded failure mode.

The only defensible invariants are about the **seam**, not the semantics:

- pricing is computed by *something* from a contract's authored terms;
- that something will exist in multiple versions over time;
- every contract must be permanently tied to the version that sold it.

So that is all the framework founds.

## The seam

```text
interface PricingEngine:
    // Permanent key, e.g. 'pricing.flat.v1'. Minted at founding; never renamed, never reused.
    key() -> string

    // Price a contract from its authored terms. All semantics live below this line.
    price(terms: ContractTerms) -> PriceBreakdown
```

```text
// contracts table — the framework's entire opinion about pricing
engine_key  string   // 'pricing.flat.v1' — the binding
terms       json     // authored input, shaped by (and only readable by) that engine
```

```text
class PricingEngineRegistry:
    // throws UnknownPricingEngine — a missing engine is a data bug, never a fallback
    get(engineKey: string) -> PricingEngine
```

Three details carry the whole pattern:

- **`engine_key` is authored into the record at creation** and never rewritten by deploys. The binding is data, not code — which is what lets two engines serve production simultaneously.
- **`terms` is the engine's locker, record-sized.** The framework stores what was authored; only the owning engine can interpret it. A v1 `terms` blob would be gibberish to v2 — and is never shown to it.
- **Unknown key throws.** Deleting an engine while its records exist must explode loudly in the first test run, not silently re-price contracts through a "default".

Year one ships one engine. `pricing.flat.v1` owns everything semantic: its tier structure, its settings UI, its `PriceBreakdown` line items. The framework routes and displays outcomes; it could not describe a "tier" if asked.

## Year two: the rethink

The market answers: customers want usage-based pricing with committed minimums. This is not an evolution of flat tiers — different inputs (meter readings), different breakdown (overage lines), different settings. Under an in-place design this is the nightmare migration: transform every live contract's data into a new shape while proving the old prices still come out. Under the seam, it is **founding a second engine**:

```text
class UsageCommitEngine implements PricingEngine:
    key() -> string:                              return 'pricing.usage.v2'
    price(terms: ContractTerms) -> PriceBreakdown: // its own world
```

- v2 registers beside v1. Nothing about v1 is touched — not its code, not its records, not its tests.
- New contracts author against v2 (the authoring flow's default engine changes — one line).
- The 2,000 existing contracts still read `engine_key = 'pricing.flat.v1'` and price identically forever. The promise to those customers is kept *structurally*, not by regression-test vigilance.

**Promotion happens on schedule — and pays the stability price.** Both engines turn out to need proration ("what does half a month cost?"). Under the main principle's growth rule the bar is met — two real consumers — but a versioned engine adds a constraint the ordinary case doesn't have: v1's byte-for-byte promise now *depends on* the shared code, so a future "improvement" to shared proration would silently re-price v1 contracts. The promoted piece therefore inherits the engines' own discipline: it is versioned (`proration.v1`), both current engines pin to it forever, and a behavior change mints `proration.v2` for engines founded later. Had proration instead been founded in year one, it would have encoded flat-tier assumptions v2 would fight — and had it been promoted *unversioned*, the structural guarantee would have quietly degraded to regression-test vigilance. (When this ceremony isn't worth it, duplicating the math inside each engine is the cheaper honest choice — see [the pattern's rules](../versioned-engine.md#the-rules-that-make-it-work).)

**Retirement is a project, not a deploy.** When the business later wants v1 gone, someone renegotiates or migrates its remaining contracts, and only when the last `pricing.flat.v1` record is gone does the engine leave the registry. Coexistence was the normal state the entire time.

## When this would have been wrong

Honesty about the pattern's narrowness — the same product has capabilities where the versioned engine would be pure overhead:

- **Invoice numbering** — well-understood domain, real invariants known on day one. Found normal contracts.
- **A contact-form router** — peripheral; if it changes, migrate it. The registry and coexistence discipline would never pay for themselves.
- **The integrations layer** — plural in *vendors*, not versions: that's the ordinary case (contracts + lockers, as in the [notification example](./notification-framework.md)), not this one.

## Litmus audit

| Test | This design's answer |
|---|---|
| Second-implementer | The second implementer arrived *from the future* (v2) and required zero framework change — the seam's entire purpose. |
| Vocabulary | The framework knows `engine_key` and `terms`; "tier", "meter", and "commitment" appear only inside engines. |
| Evidence | The founding contract traces to the only invariants honestly known: computed pricing, versions over time, permanent binding. |
| Locker | `terms` is authored data only its engine interprets; the framework never reads into it. |
| Lift | Proration waited inside v1 until v2 made it promotable — then moved with two consumers' evidence, versioned and pinned so the move cost no stability. |
| Conformance | One seam suite runs against every engine: resolve by key, price authored terms, return a `PriceBreakdown` — no engine-specific branches needed. |
