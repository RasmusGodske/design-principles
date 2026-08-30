---
type: concept-explainer
title: Framework and Implementation
description: How to decide which side of a framework/implementation boundary a behavior, field, or decision belongs on — the framework defines the shape of contracts and offers lockers for implementation data, implementations own all the semantics, and after a deliberately-founded start the framework grows only on evidence.
---

# Framework and Implementation

> **A shared framework defines the shape of contracts — named interfaces, lifecycle hooks, lockers. Implementations own all the semantics. Found the framework deliberately from experience; after that it grows only on evidence — a new contract when the framework itself starts consuming a new outcome, a promotion when a second implementation needs the same code.**

Any host-with-plugins design faces the same recurring decision: a framework (integration host, payment abstraction, notification dispatcher, import pipeline, report renderer) with multiple concrete implementations behind it — and a steady stream of "where does this go?" questions. The failure mode is always the same and always quiet: **one implementation's needs leak into the framework.** Its vendor's vocabulary becomes a shared column. Its pagination style becomes the pagination interface. Its connection-test flow becomes *the* connection-test flow. Nothing breaks — until the next implementation arrives and has to fight abstractions that were never generic, only generalized-looking.

This lens is the sorting question, asked of every behavior, field, and decision near the boundary: **is this true of *all* implementations, and does the *framework* consume it?** The framework holds only what is invariant across implementations *and consumed by the framework itself* — something can be true of every implementation and still belong inside each of them. Everything else lives in the implementation, even when it looks reusable.

## 1. Contracts define shape, never semantics

The framework declares *that* something happens; the implementation decides *how* and *what it means*:

- The framework declares that a connection can be tested — an interface with a result shape. It never prescribes what "testing a connection" involves; every vendor authenticates differently.
- The framework declares that results can be fetched page-by-page — but not *how* pagination works. Some APIs use cursors, some use offsets; a framework that hardcodes `CursorPage` has silently adopted one vendor's paradigm as everyone's.
- The framework declares that an implementation may offer filters — but the filter options, their storage shape, and how they are evaluated belong wholly to the implementation. The framework passes them through; it does not understand them.

The test for a good contract: it names an *outcome* the framework needs (connected? next page? included by filter?), not a *procedure* any particular implementation follows. The executable form of "shape" is a **conformance suite**: the framework can ship one test suite that every implementation must pass, with no implementation-specific branches in it.

**Every implementation carries a permanent key.** The key is minted when the implementation is founded and is never renamed or reused; the framework's registry resolves keys to implementations and **fails loudly on an unknown key** — a missing implementation is a data or configuration bug, never a silent fallback. (Minted permanent keys, and records referencing by key, are exactly [`config-and-record`](../config-and-record/README.md)'s subject — identity guidance lives there.)

**Partial capabilities are modeled honestly.** Some outcomes exist for only some implementations (not every notification channel has a "sender"; not every destination supports retries). When the framework consumes such an outcome, the contract says so — a nullable return, or a capability interface the framework checks — so an implementation without the capability answers *"I don't have one"* in the type system. The two dishonest alternatives are both boundary failures: peeking into a locker for it, or branching on implementation key. Demanding a non-nullable answer from implementations that must fabricate one is the same guess as a universal column, wearing an interface.

## 2. Implementation data goes in the locker, not shared columns

Implementations need to persist their own state — vendor account identifiers, sync cursors, feature toggles. The framework's answer is the **locker**: an opaque metadata field it offers to every implementation but never opens. The implementation puts its properties in its locker; no one else accesses them, cares what they are, or validates their shape. The framework just offers the locker — it never holds a key.

The locker exists so that one implementation's concept is never promoted into a first-class shared column. The tell is vocabulary: a field named after one vendor's concept (`external_tenant_id`, `workspace_key`, `site_ref`) sitting in a shared schema is one implementation's worldview imposed on all future ones — chosen when the sample size was one. A first-class column is justified only when **the framework itself consumes the value** (it branches on it, queries by it, displays it generically). If only the implementation reads it, it belongs in that implementation's locker.

The discipline cuts both ways: a locker stays locked. The moment the framework reads into it, branches on its contents, or validates its shape, the locker has become a contract in disguise — worse than a declared one, because nothing documents it.

Three practicalities that follow from locker ownership:

- **The write path is the implementation's too.** The implementation authors and validates its own locker contents. When the host provides a generic settings surface, the implementation supplies its form and validation through a contract (that is shape: "give me your settings surface"), and the framework renders what it is given — it still never interprets the stored values.
- **A locker is record-attached config, not a database.** When an implementation needs data it can *query* — resolving an inbound webhook by a vendor account id, indexing sync state — the escalation path is an **implementation-owned private table**. That is legitimate and needs no apology: vendor-named columns are unobjectionable in a table the implementation owns outright. The locker rule constrains *shared* schema, not the implementation's own storage.
- **Opacity is mechanics, not a privacy loophole.** The framework may encrypt a locker at rest without reading it — protection is generic mechanics, interpretation is semantics; secrets and credentials should get exactly that treatment. And a locker is still a durable store: [`data-minimization`](../data-minimization/README.md) applies in full. "The framework never reads it" must never become "nobody audits what lands in it."

## 3. Found deliberately, grow on evidence

A framework is **founded, not accreted** — and founding is legitimate design work done up front. When the shared capability is genuinely needed, an experienced founder lays the foundation deliberately: the lifecycle, the core contracts, the registration story — a skeleton others can read, understand, and build within. **Experience is evidence, not speculation.** The systems the founder has built and seen before are real consumers, just in memory; designing the foundation from them is fundamentally different from generalizing from one implementation plus imagination.

Founding matters because the failure mode has **two poles**:

| Over-founded | Never-founded |
|---|---|
| The foundation encodes guessed semantics — one paradigm's pagination, one vendor's vocabulary — as if they were universal. | No skeleton exists, so every implementation invents its own structure. |
| Each new implementation must fight or work around abstractions that never fit. | Nothing converges; there is no shared shape to read, and nothing to promote *into*. |
| The wrong abstraction must be unwound while existing implementations already depend on it. | The "framework" arrives too late, as an archaeology project across divergent implementations. |

The discipline that keeps founding honest: **the foundation holds only invariants you have evidence for** — from experience or from the domain itself. Everything uncertain gets a contract or a locker, not a guess. And the founding era has a crisp end: **founding ends when the first concrete implementation exists.** From that moment, every addition to the shared layer is post-founding and must be justified by one of the two growth moves below — "we're still founding" is not an evergreen license.

**After founding, the framework grows through exactly two moves:**

1. **Promotion — implementation-proven code moves in.** New capability is built inside one concrete implementation first, even when it "will obviously be useful for others" — kept cleanly separated and documented, so lifting it later is cheap. Promotion happens when the **second consumer** actually arrives, because only then do two real data points show what is invariant and what was one vendor's quirk; the refactor has live implementations to validate the generalization against.
2. **A new demand — the framework starts consuming a new outcome.** When the host itself needs something from every implementation (a display value, a scheduling hint, a payload format), that need becomes a declared contract change — never a locker-peek, never an key-branch. Its evidence is the framework's own consumption, not implementation count. The cost is honest and visible: every implementation must be updated to answer the new demand, and that per-implementation cost being *seen and paid* is exactly what distinguishes a declared demand from a hidden branch. (If only some implementations can answer, model it as a partial capability — see discipline 1.)

The deletion-test economics of this — when an abstraction earns its existence at all — belong to [`deep-modules`](../deep-modules/README.md); this principle fixes *where the code waits* until that bar is met: in the implementation, separated, ready to lift.

**Founding under maximal uncertainty is its own pattern.** Sometimes there is no experience to found from at all — a core capability that will certainly evolve, in ways nobody can predict, while everything customers author today must keep working. There, the only invariant you can honestly found is the seam itself: implementations become permanently-identified **engines**, records bind to the engine they were authored under, and evolution means founding a new engine beside the old. That pattern — when it applies, its rules, and when it is the wrong tool — has its own page: [The Versioned Engine](./versioned-engine.md).

## Litmus tests

1. **The second-implementer test** — imagine a wholly different implementation (different vendor, opposite paradigm). Could it satisfy this contract *without the framework changing*? If you can already name the change it would force, the semantics are in the wrong layer.
2. **The vocabulary test** — read the framework's schema, interfaces, and enums. Does any name come from one implementation's vernacular? The framework should be explainable without mentioning any specific implementation.
3. **The evidence test** — for each framework feature: what justifies it living in the shared layer? Founding-era contracts answer "an invariant, known from experience or the domain." Post-founding features answer "N implementations consume it" (a promotion) or "the framework consumes it from every implementation" (a demand). A feature with none of these answers — added for imagined future consumers — is speculation.
4. **The locker test** — does the framework ever read, branch on, or validate the contents of an implementation's locker? If yes, it isn't a locker — extract the honest contract it's hiding.
5. **The lift test** — for capability living inside an implementation: if a second consumer appeared tomorrow, is it separated and documented well enough that promoting it is a mechanical refactor? "Prove first" is only cheap when the proof is kept liftable.
6. **The conformance test** — could the framework ship a single test suite that every implementation passes, with no implementation-specific branches in the suite? Whatever forces a branch is semantics that leaked into shape.

## Review red flags

- A migration adding a vendor-flavored column (`external_tenant_id`, `workspace_key`, `site_ref`) to a framework-owned table
- Framework code that `switch`es or branches on the implementation key — that branch is an interface method waiting to be declared
- An interface that prescribes a procedure (cursor pagination, a specific auth dance) rather than an outcome
- A required contract method that only some implementations can honestly answer — a partial capability wearing a universal signature
- A shared base class or framework helper added post-founding with exactly one implementation using it
- "This will be useful for future implementations" as the justification for building in the shared layer after the first implementation exists
- Framework code reading into an implementation's locker — including UI code displaying "just this one" locker key
- An implementation working around the framework because a contract encodes another vendor's paradigm

## When it applies — and when not

**Apply when designing** any shared host with multiple concrete implementations behind a common boundary: integration frameworks, payment or notification provider abstractions, import/export pipelines, report or document renderers, storage drivers — and when reviewing a diff that adds a field, method, or branch to any shared layer of one. When a *core* capability must keep evolving in unpredictable ways while existing configurations keep running, apply the [versioned engine](./versioned-engine.md) variant.

**Don't contort:**

- **The framework's own concerns are legitimately opinionated.** Registration, orchestration, scheduling, error surfacing, audit — how the *host* runs is the framework's domain, and it may be as opinionated there as it likes. The boundary rule governs implementation semantics, not framework mechanics.
- **A required interface is not an "opinion".** Demanding that every implementation *can* report connection health is shape; prescribing how it checks is semantics. Don't weaken contracts to hollow pass-throughs in the name of neutrality — the framework should demand every outcome it genuinely consumes (and model the partial ones honestly).
- **The second-consumer bar is a bar, not a ceremony.** When the second consumer genuinely exists on the roadmap *and* both are understood, designing the shared piece directly can be right. What the principle forbids is generalizing from one implementation plus imagination.
- **Existing frameworks are grandfathered.** The principle does not mandate retrofitting what already ships — but every *new* field on a shared table, method on a shared interface, or branch in shared code is new code, and the rules apply to it in full.

## Going deeper

- **[Worked Examples](./examples/README.md)** — three invented, self-contained walkthroughs, one per way of using the principle: a vendor-plural notification framework (contracts and lockers in daily use), a versioned pricing engine (founding under maximal uncertainty), and a growth-by-promotion story (the two classic leaks and the promotion that waiting earns). Read these when the disciplines feel abstract.
- **[The Versioned Engine](./versioned-engine.md)** — the founding pattern for maximal uncertainty: a core capability that must evolve unpredictably while authored records keep working. Read it before founding a framework where you cannot know the implementation's future shape.

## Relation to the other lenses

- [`deep-modules`](../deep-modules/README.md) owns the economics of abstraction — whether an interface earns its existence at all (deletion test, earned-not-speculative). This lens applies those economics to a specific topology: it decides *which side of the framework/implementation line* code and data wait on, and *when* they cross it.
- [`config-and-record`](../config-and-record/README.md) is the identity home this lens defers to: an implementation's identity is a **minted permanent key**, and records bind to implementations **by key, not row id** — the mechanics (minted vs natural keys, reference language) live there. The two are also naming siblings: both govern a recurring either/or sorting decision, and the directory name names the two piles — config-and-record sorts an *entity's identity*; this lens sorts a *behavior's home*.
- [`data-minimization`](../data-minimization/README.md) governs what may land in a locker at all — opacity to the framework is not opacity to scrutiny; a locker is a durable store like any other.
