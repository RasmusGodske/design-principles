---
type: concept-explainer
title: Where Docs Live
description: How to choose between co-locating a doc beside its code and centralizing it, handle scattered legacy code, and when audience should override proximity.
---

# Where Docs Live

Choosing between co-location and centralization, handling code that's too scattered to co-locate, and the cases where *audience* overrides proximity.

> Read the [README](README.md) first for the altitude rule and the two placement modes in brief.

## Co-locate what describes code

A document that describes a specific piece of code lives **beside that code** — a `README.md` in the module's own directory. The reason is drift: a doc and its code stay honest only while they're edited together. The moment they're separated, the doc starts lying, and nobody editing the code is looking at the doc to notice.

So the default is strong: **if a document is about one cohesive code area, it lives in that area.** A developer or agent working there finds it without being told it exists.

The home is decided by what the document **primarily** describes — not by every symbol it happens to mention. A doc that explains a derived or pure shape may co-locate with that shape and *cross-reference* the source it mirrors, rather than being torn between two homes.

## Elevate when code is scattered

Legacy code organized by technical type defeats co-location: the controller for a concept lives in one tree, its service in another, its data shapes in a third. No single folder owns the whole concept, so there's nowhere to put a doc that's "beside the code."

The rule for this case:

> **Elevate one orientation document to the nearest folder that cohesively owns the whole flow, and have it enumerate the scattered locations it covers.**

One elevated doc that names all the homes ("the request enters at `…/Controllers/Pricing`, computes in `…/Services/Pricing`, and serializes through `…/Data/Pricing`") is the only honest placement when the code itself is dispersed. Do *not* scatter a doc-per-file to mirror the scattered code — that just multiplies orphans.

Mark an elevated doc as **elevated-because-scattered**, distinct from a doc that's central because it's genuinely cross-cutting. The two look identical in a central tree but mean opposite things: the elevated one *should migrate back beside the code* once that code consolidates into a module; the cross-cutting one belongs centrally forever. Without the distinction, elevated docs never find their way home and the central tree silently fills with code docs that have lost their code.

## Centralize what's cross-cutting

A document that explains a concept **not tied to one code location** — a domain idea, a product behavior, an architectural pattern spanning many modules — lives in a **central docs tree**, because there is no single code area that owns it.

When the same concept accrues two central homes over time, designate **one canonical home** and make the other a pointer to it. Two living copies of the same explanation drift; one canonical copy plus pointers does not.

## A concept can be both code-local and cross-cutting — that's fine

It's common for "the same concept" to deserve *both* a co-located doc and a central one — and this is not a conflict to resolve, because they are **different documents for different readers**:

- A **co-located** orientation doc, for the engineer about to work *in* the code: "what this module is, its contract, where things live."
- A **central** concept doc, for someone learning the domain with no code context: "what this concept means and why it exists."

Neither "wins." They coexist and **cross-link**. The duplication rule (one canonical home + pointer) fires only when the *same kind of document for the same audience* is genuinely copied into two places. A quick test: if you can't tell two docs apart by *who reads them and what they're trying to do*, it's duplication — collapse to one; if you can, they're legitimately separate.

## Audience can override proximity

Placement is driven not only by proximity-to-code but by **who or what reads the document**. Audience is an independent axis, and it can force a boundary that proximity wouldn't:

- **A distinct human audience** — a documentation set written for non-technical/business readers belongs in its **own segregated tree** that states, at its root, who it is for and who it is *not* for. Don't interleave business-audience explanation with engineer-audience reference just because they share a subject.
- **A human *and* a machine consumer** — when the same knowledge must serve both a person and an automated consumer (a code generator, a tool that parses a contract), split it into a **machine-readable contract file plus a human-reference file**, co-located and cross-linked. The contract stays terse and parseable; the prose stays readable; neither is bent to serve the other.

### Bridge code terms to domain terms when you elevate for a business audience

When scattered code is elevated into an audience-segregated (business/onboarding) home, the elevated doc should carry a **code-term → domain-term crosswalk** — a small table mapping the symbols a reader will meet in the source to the business words the doc uses (`PriceRule → Discount`, `Ledger → Statement`). This is distinct from merely listing the scattered locations: it lets a business reader who drops into the code, or an engineer who starts from the business doc, cross the vocabulary gap in either direction.
