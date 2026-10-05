---
type: concept-explainer
title: Safe Deletion
description: How to decide whether a user may delete something, may only archive it, or is refused — so removing a thing never breaks what still uses it and never leaves history pointing at nothing. Open when designing a new entity's remove action, when a delete button is added or reviewed, or when deciding between archive and delete.
---

# Safe Deletion

> **A user may delete something only when nothing depends on it. If something live still uses it, refuse. If only history refers to it, archive it instead, so the history keeps resolving.**

Start with a story. An invoice from last year has a line pointing at product 412. The shop owner tidies up the catalogue and deletes product 412, since they stopped selling it months ago. A year later an accountant opens the invoice to answer a customer, and the line reads *unknown product*. Nothing broke on the day of the delete, and nothing warned anyone. The history simply stopped making sense, and there is no way back.

Users cannot be expected to know what depends on what. The system knows, so the system decides.

## Three answers

Every remove action ends in exactly one of these:

| | When | The user sees |
|---|---|---|
| **Refuse** | Something **live** uses it | "Can't remove: used by *Summer discount* and 2 more. Change those first." |
| **Archive** | Nothing live uses it, but **history** refers to it | It leaves lists and pickers; *Show archived* brings it back, and *Restore* undoes it |
| **Delete** | **Nothing** depends on it | It is gone |

## Two questions decide it

**1. Would deleting it break something live?**
Something that is in use right now and refers to it: a discount rule that names the product, a report that filters on a category, a form that offers a field. Deleting would make it fail, or worse, silently produce a different result. → **Refuse**, and name what uses it, so the user can change those first.

**2. Would deleting it leave history pointing at nothing?**
Something that already happened and refers to it: an invoice line, a payout, a sent message, a published result, a stored value. That history is not going to change, but someone may need to understand it later. → **Archive.** The thing stays, every reference to it still resolves, and it is out of the user's way.

If the answer to both is no, **delete**.

A single thing can be at any of the three answers depending on its situation. A product that was never sold can be deleted; the same product after its first invoice can only be archived; while a live discount rule names it, it cannot be removed at all. So decide **per item, at the moment of removing**, not once per kind of thing. Show the action that applies, and when the other one is not available say why ("Has invoices, archive it instead"). Never offer delete and then fail.

## Follow the chain

What depends on a thing is not always one step away. References form chains, and the questions apply to the whole chain.

**Versions and copies.** Many systems keep frozen copies of a thing: a revision saved on every change, a snapshot taken when an order is placed, a published version of a document. A copy points back at the thing it was copied from, and history usually points at the copy rather than the live thing: the invoice refers to *the product as it was when sold*. So to ask "does history depend on product 412?", ask it of 412 *and* of every copy of 412. If an invoice refers to any copy, the product is part of that history, and deleting it leaves the copy, and through it the invoice, with nothing to belong to. If no copy is referred to by anything, the copies alone are no reason to keep it.

**Parts and their whole.** Some things are only reached through a larger thing that owns them: the price tiers inside a product, the filter inside a report, the steps inside a workflow. History refers to the whole (often to a copy of the whole), not to its parts. So a part can usually be deleted once nothing live uses it, because the copy already captured how the whole looked; the whole itself is what history holds on to. Domain-driven design calls such a whole an *aggregate root*: the one entry point that outside things refer to.

The rule stays the same along the chain: **if anything at the end of the chain is live, refuse; if anything at the end is history, archive.**

## Archive is for users; soft delete is for the system

**Archived** is a state users see and control. It means "not in use any more, kept because something refers to it". The user can always restore it. Ask for a short reason when archiving, and record who did it and when: the next person to see it will want to know why.

**Soft delete** is the system's own safety net: the row survives so the people operating the system can recover from mistakes. It is not a feature. Users never see soft-deleted things and never browse a trash, and nothing in the product relies on soft-deleted rows. If a user should be able to bring something back, it should have been archived.

From the user's point of view a soft-deleted thing no longer exists, so it uses nothing: only **live** dependents block a removal, and only live dependents are shown.

## Answer it in one place

Every screen and every remove action must ask "what depends on this?" and get the same answer. Keep that knowledge in one place: the database's real foreign keys, plus a recorded index for the references the schema cannot express, such as an ID inside a JSON document or a name inside an expression. Every remove path consults it. A delete button that checks dependencies on its own will sooner or later disagree with the next one. This is [single chokepoint per fact](../single-chokepoint-per-fact/README.md) applied to the question "may this go?".

## Worked examples

| Thing | Why | Answer |
|---|---|---|
| Product never sold, no rule names it | nothing depends on it | delete |
| Product a live discount rule names | it would break the rule | refuse |
| Product with invoices behind it | invoices refer to copies of it | archive |
| Price tier inside a product | invoices refer to the product's copy, not the tier | delete, once nothing live uses it |
| Custom field definition | stored values are filed under it | archive (values never stop needing their definition) |
| Invoice that was sent or paid | it *is* history | never deleted; archive it at most |
| Invoice draft never sent | nothing happened because of it | delete |

## Quick checks

1. **List the dependents.** For this kind of thing, what live things can refer to it, and what history can, directly or through copies and wholes? If you cannot list them, you cannot offer delete safely.
2. **Play out the accountant.** Years from now someone opens the oldest record that touched it. After the user removed it, can they still see what it was?
3. **Play out the mistake.** The user removes it by accident. Can they undo it themselves (archive), or only by asking support (soft delete)? If it matters, they should be able to.
4. **Count the remove paths.** Every button, bulk action, import and cleanup job that removes it: do they all ask the same dependency question?

## When it applies, and when not

**Use this lens** when a kind of thing gets a remove action, when a remove action is reviewed, when a new kind of history starts referring to existing things, and when introducing copies, versions or snapshots.

**Don't overdo it:**

- **Not everything needs archive.** A throwaway draft or an internal link row that no history refers to can just be deleted. Archive earns its place where history accrues.
- **Archive is not a recycle bin.** It holds things kept on purpose. Archiving things "just to be safe" fills the list with noise until nobody trusts it.
- **Hard deletes still exist** for legal erasure, test data and closing an account, but as deliberate operations run outside the product with their own process. [Data minimization](../data-minimization/README.md) decides what must be erasable at all.

## Relation to the other lenses

- [`config-and-record`](../config-and-record/README.md) supplies the vocabulary: records are the history this lens protects, configuration is what may change or go, and frozen copies are how a configuration's past survives a change.
- [`single-chokepoint-per-fact`](../single-chokepoint-per-fact/README.md): removing is a write, so the remove path and its dependency check exist once per kind of thing.
- [`data-minimization`](../data-minimization/README.md) pulls the other way on purpose: it decides what must not be kept at all. Where the two meet, erasure wins, and history should hold a reference rather than a copy of personal data so erasure stays possible.
