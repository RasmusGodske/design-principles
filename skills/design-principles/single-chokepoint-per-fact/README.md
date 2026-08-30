---
type: concept-explainer
title: Single Chokepoint per Fact
description: Why each piece of stored data needs exactly one place in the code that creates, changes, or deletes it — every button, job, and webhook calls that one place — and how to spot the sneaky second copy that lets the two definitions drift apart.
---

# Single Chokepoint per Fact

> **For each piece of data your system stores, there is exactly one place in the code that creates, changes, or deletes it. Every button, scheduled job, webhook, and import that wants to do so calls that one place. Build it when you write the *first* caller — not when the second one shows up.**

Start with a story. Your app creates invoices two ways: a scheduled job makes them at the end of the month, and an admin can click **"Create invoice"** to make one by hand. Six months later a new requirement lands: every invoice must now include a tax line.

- If both ways call one shared `InvoiceCreationService`, that's **one edit**. Done.
- If the scheduled job builds the invoice itself, and the admin controller *also* builds the invoice itself, you now have **two definitions of what an invoice is**. The tax line gets added to one of them. Which kind of invoice a customer receives depends on which button happened to be pressed — and nobody notices until the numbers disagree.

That shared, single place is the **chokepoint**. And a **fact** is simply each piece of data this applies to: "this invoice exists", "this order's total is 500", "this subscription is active". The principle in one line: **however many ways there are to trigger a change to some data, the code that actually makes the change exists once.**

## The four rules

### 1. One place to create it — no matter who's creating

Automatic and manual creation go through the same service. The scheduled job and the admin's button both call `InvoiceCreationService`. The warning sign is easy to spot in review: a controller building a record field-by-field while a creation service for that same record already exists somewhere else.

### 2. Data arriving through two doors is handled by one function

Sometimes the same information reaches you through more than one channel — an external system pushes events to your webhook, *and* a scheduled job polls for anything the webhook missed. Both channels must hand the data to **one shared function** that does the actual processing. Each channel keeps only what is truly channel-specific: unpacking the delivery format, confirming receipt.

Two almost-identical copies of the processing code is the most common way this goes wrong: a bug gets fixed in the webhook copy, the polling copy keeps the bug, and the data slowly stops agreeing. A related trap: making one channel's events *pretend* to be another's just to reuse its code path — share an honest common function instead.

### 3. Values that must match are computed together

Sometimes you store two values that have to agree: a document and its checksum, an order total and its line items. If one part of the code builds the document and a different part computes the checksum, sooner or later someone changes the document code and forgets the checksum code — and now the mismatch is invisible, because the checksum was supposed to be the thing that catches mismatches. The fix: **one function produces both values**, so they *cannot* be written separately.

### 4. No back doors

A chokepoint only works if there's no way around it. The usual back doors:

- **Logic hidden in model lifecycle hooks** ("whenever this record is deleted, also do X") — the hook runs no matter which code triggered the delete, and nobody reading the calling code can see it. Put the rule in the service where every reader finds it.
- **Direct `create()` / `save()` / `delete()` calls** sprinkled at call sites that should be calling the service.
- **Raw database queries** that change the data "just this once" for a fix or migration — a second, informal version of the rules.

Some stacks let you make the back doors physically impossible: a persistence base class whose models refuse to be saved or deleted unless the write originates in their owning service. Then the rule isn't a convention people remember — it's a wall.

## Build the chokepoint with the first caller

The [framework-and-implementation](../framework-and-implementation/README.md) principle says: don't build shared abstractions until a second user proves what shape they need. This principle deliberately says the opposite for creating/changing/deleting data: **put that code in its one shared place immediately, even while there's only one caller.**

There's no contradiction. An abstraction built early is a *guess* about future needs, and guesses go wrong. But the code that creates an invoice is not a guess — you're writing it today either way. The only choice is *where it lives*: in a named service anyone can find and call, or inline inside the first caller — where the second caller (and for data changes, a second caller almost always comes) won't find it, and will copy it instead.

## What you get for it

| | Because |
|---|---|
| **The two versions can't drift apart** | There is no second version. A rule change is one edit, and every button and job gets it at once. |
| **Anyone can answer "what does it take to create one of these?"** | The answer is in one file — not scattered across controllers, jobs, and hooks. |
| **Buttons, jobs, and webhooks stay small** | They translate their input and call the service. What's left in them is genuinely about that channel. |
| **Checks can't be skipped** | Validation, permissions, and logging live in the one place every change passes through. There is no route around them. |

## Quick checks

1. **Count the writers** — list every piece of code that creates, changes, or deletes this data (including hooks and bulk scripts). More than one implementation of the rules? Each extra one will eventually disagree with the others.
2. **Play out a rule change** — tomorrow a new field becomes required. How many places need editing? More than one means there is no chokepoint.
3. **Check the pairs** — for any two stored values that must agree: is there a code path that writes one without the other? If yes, they will someday disagree.
4. **Look for back doors** — can this data be changed without going through the service (a hook, a direct `save()`, a raw query)? A chokepoint with a back door is a suggestion, not a chokepoint.

## When it applies — and when not

**Use this lens** whenever the same data can be changed from more than one direction: creation that is both scheduled and manual, data arriving by webhook *and* by polling, deletion triggered by users *and* by cleanup jobs, stored values that duplicate or summarize other stored values.

**Don't overdo it:**

- **Reading needs no chokepoint.** Have as many queries as you like — this principle is about *changing* data.
- **One chokepoint per piece of data — not one giant service for everything.** A domain has many small, named services. Funneling a whole module through one mega-service is a junk drawer wearing this principle's clothes.
- **Channel-specific work stays in the channel.** Parsing a webhook's envelope or mapping a vendor's field names is honestly per-channel. The shared function starts where the data *means* something.
- **Tests may bypass on purpose.** Where models are guarded that way, they need a loud, explicit escape hatch for legitimate cases (seeding, the service's own internals). The point is that going around the wall is a visible decision, never an accident.

## Relation to the other lenses

- [`detachable-domain`](../detachable-domain/README.md) says: code *outside* a domain may only touch its data through the domain's service. This principle looks one level finer: even *inside* the domain, each piece of data has one write path. Detachable-domain stops a controller from reaching into the model; this stops the domain itself from quietly growing two definitions of the same thing.
- [`pure-core-persistent-shell`](../pure-core-persistent-shell/README.md) — the chokepoint is the *shell* (it saves things), but the rules it applies can be a pure function it calls. The two compose nicely: pure rules, one gate that persists.
- [`framework-and-implementation`](../framework-and-implementation/README.md) — the deliberate contrast explained above: shared *abstractions* wait for their second consumer; the code that writes data gets its one home on day one.
