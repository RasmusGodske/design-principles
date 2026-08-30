---
type: concept-explainer
title: Documentation Placement
description: Where a document should live and at what altitude — beside the code, centralized, or not at all — and how a doc directory earns structure as it grows.
---

# Documentation Placement

Where a piece of documentation lives — beside the code it describes, or in a central tree — and how a body of docs is organized as it grows, so a reader finds the right *altitude* of knowledge without having to read the source to recover it.

## Why this exists

Documentation ends up wherever was convenient in the moment. A README bloats until no one reads the part they need; a concept that the whole team should understand hides next to one class; the same explanation is pasted into three trees and they quietly drift apart; a folder of "01-, 02-, 04-" files implies an order that doesn't exist. None of this is cosmetic. Placement decides whether a reader — or an agent — lands on the right knowledge at the right level of detail, or has to fall back to reading the code to recover what a document should have told them.

This principle answers two questions: **where does a given document live**, and **how is a directory of documents organized as it grows**.

## The altitude rule

The single most useful idea here: **documentation has an altitude, and knowledge belongs at the altitude that matches it.**

| The knowledge | Its home |
|---|---|
| Feature / module **behavior, intent, constraints** — what you'd otherwise have to read the code to learn ("how does pricing work?", "what *is* this module?") | a `README.md` (or a `Docs/` directory) |
| **Local, code-specific rationale** — "why this one choice" ("we key by string so the value is id-type-agnostic") | the code's own **doc-comment** |
| **Self-evident** code — a plain data object, a standard CRUD controller | **nothing** |

The deciding question, for any fact you're tempted to write down:

> *Is this feature behavior you'd otherwise dig through code to learn (→ README/`Docs/`), a local why-decision (→ doc-comment), or self-evident (→ write nothing)?*

This rule does double duty: it tells you *where* a fact goes, and it guards against over-documenting — a README whose entire content restates what a single class and its doc-comment already say is a shallow node that adds noise, not knowledge.

Altitude has a *temporal* side, too: capture what **won't change** — the *why* and the contract, not volatile state. The "behavior, intent, constraints" worth a README are the ones the code can't tell you and that survive a refactor — not the current count, list, or signature the code already states (and will change). The staleness test ("would a plausible change to the code or process make this false?"), and how to keep a doc from going stale, is in [growing-a-doc-home.md](growing-a-doc-home.md).

## Two placement modes: co-locate or centralize

Every document that earns a README/`Docs/` home goes to one of two places:

- **Co-locate** — a document that *describes a specific piece of code* lives **beside that code**, so a developer (or agent) working there finds it without leaving. This is the default for anything anchored to one code area.
- **Centralize** — a document that explains a *cross-cutting concept* not tied to one code location lives in a **central docs tree**.

The wrinkle is legacy code organized by technical type (controllers in one tree, services in another), where no single folder owns a whole concept and co-location is impossible. The rule for that, plus how audience can override proximity, is in [where-docs-live.md](where-docs-live.md).

## Growing a doc home

A doc home is not designed up front; it **earns structure as it grows**:

- Start as a single `README.md`.
- Split into a `Docs/` directory only when one file has genuinely grown large enough to force readers past sections irrelevant to them — never as pre-emptive structure.
- Give a directory level its own README **only where it's a domain concept worth a *plaque*** — something orienting (what this is, why it exists) *and* routing (where to go next), not a bare signpost. A generic technical bucket (`Services/`, `Enums/`) earns nothing; a one-child level with nothing novel to say earns nothing — link its content straight through from the real plaque above.

The full rules — the *plaque, not a signpost* test, the `Docs/` graduation test, index-file naming, when numeric `NN-` prefixes are legitimate, and keeping shared assets single-sourced — are in [growing-a-doc-home.md](growing-a-doc-home.md).

## Relationship to Discoverable Knowledge

Documentation Placement and [Discoverable Knowledge](../discoverable-knowledge/README.md) are siblings that compose:

- **Placement** decides *where* a document lives and how its directory is organized.
- **Discoverable Knowledge** decides that the result is *reachable and self-describing* — wired into the trail, with frontmatter.

They meet at one concrete move: when an overgrown README splits into a `Docs/` directory, Placement says *when and how to split*, and Discoverable Knowledge says *the new files must be referenced by the README — now an index — or they're orphans*. Splitting without wiring just trades a bloated doc for a pile of lost ones.

## Reading map

| Doc | Read when |
|---|---|
| [where-docs-live.md](where-docs-live.md) | Deciding co-locate vs centralize, elevating docs for scattered legacy code, or when audience (business vs engineer, human vs machine) should drive placement |
| [growing-a-doc-home.md](growing-a-doc-home.md) | A README is getting large, you're adding directory levels, naming index files, numbering files, or placing templates and generated docs |

## What this is not

- **Not about whether a doc is findable.** That a doc is reachable and self-describing is [Discoverable Knowledge](../discoverable-knowledge/README.md)'s job. Placement decides *where*; discoverability decides *wired*.
- **Not a mandate to write more docs.** The altitude rule is as much about *not* writing a doc (self-evident code, a one-class folder) as about writing one.
- **Not a fixed folder taxonomy.** It gives rules for deciding placement, not a directory template every project must adopt.
