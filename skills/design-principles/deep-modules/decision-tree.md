---
type: how-to-guide
title: Decision Tree
description: Where does this class go — a sequence of questions to answer when actively placing a new class under the module convention.
---

# Decision Tree

"Where does this class go?" — answered as a sequence of questions. Use this when actively placing a new class and unsure where it belongs.

For broader principles see the [README](README.md). For directory descriptions see [`directories.md`](directories.md). For how naming influences placement see [`naming-and-placement.md`](naming-and-placement.md). Directory names below are the neutral defaults — substitute your [binding](bindings/)'s names.

## Quick lookup

Most placements are mechanical. Use this table first; only fall through to the questions below when none of these match.

| What you're adding | Where it goes |
|---|---|
| A service that outsiders call | `{Module}/public/services/` |
| A service only this module calls | `{Module}/services/` |
| A persistence entity / ORM model | `{Module}/models/` |
| A data class other modules consume | `{Module}/public/data/` |
| A data class only this module uses | `{Module}/data/` |
| An enum referenced by the published contract | `{Module}/public/enums/` |
| An enum only this module uses | `{Module}/enums/` |
| An exception outsiders catch | `{Module}/public/exceptions/` |
| An event other modules listen to | `{Module}/public/events/` (in the *producer* module — the one that fires it) |
| An HTTP handler / controller | `{Module}/entrypoints/http/` |
| Request validation / middleware | `{Module}/entrypoints/http/` |
| A CLI command | `{Module}/entrypoints/cli/` |
| A queueable job | `{Module}/entrypoints/jobs/` |
| An event listener | `{Module}/entrypoints/listeners/` (in the *consumer* module) |
| An interface for ≥2 implementations | `{Module}/public/contracts/` (for a family: the family module's `public/contracts/`) |
| A new kind of something that already has kinds (a member of a family) | A new member module: `{Owner}/modules/{Family}/modules/{Member}/`, copied from a sibling |

## Step-by-step questions

If the lookup table doesn't resolve it, walk through these.

### 1. Which module owns this?

Identify the module first. Ask: *"What domain does this class's behaviour belong to?"* Then:

- **Clear answer?** Place it there.
- **Multiple plausible modules?** Pick the strongest by asking who *owns* the behaviour. Usually one is the producer (defines the concept) and the other is a consumer; the producer keeps it.
- **No clear answer?** Stop — this is a smell. See "When nothing fits" below.

### 2. Is this a value or behaviour?

- **Value** — data class, enum, exception, event. Goes in the matching kind directory; *which* one depends on the next question.
- **Behaviour** — changes state, performs an action, runs a query. Goes in `services/` or `public/services/`.

### 3. Public or internal?

Ask: *"Will outside modules use this directly?"*

- **Behaviour, yes** → `public/services/`. **Behaviour, no** → internal `services/`. **Unsure** → start in `public/services/`; demote later if outsiders never call it. Demoting is cheaper than promoting.
- **Value, yes** → the matching `public/{data,enums,events,exceptions}/` directory — placing it there is the explicit act of publishing it as contract.
- **Value, no** → the matching root-level directory (`data/`, `enums/`, …), internal to the module. When another module later needs it, *move* it onto the public surface — that move is the publication decision, made deliberately.

### 4. If it's an entry point (handler, command, listener, job)?

Always in the entry-point role of the module that owns the entry point:
- HTTP handlers / request validation / middleware → `entrypoints/http/`
- CLI commands → `entrypoints/cli/`
- Queueable jobs → `entrypoints/jobs/`
- Event listeners → `entrypoints/listeners/` (in the *consumer* module — the one that reacts)

Entry points are always thin — they delegate every mutation to `public/services/`. The entry point itself is internal to its owning module.

### 5. If it's an interface?

- **One implementation today** → don't extract. The service class is the contract.
- **≥2 implementations today** → `public/contracts/`.
- **The contract of a family** → the family module's `public/contracts/`. Each implementation is a member module under the family module's `modules/`.

### 6. If it's a new kind of something that already has kinds?

That is a member of a family. Ask in order:

- **Does the family module exist?** Then the member is a new module under a `modules/{Family}/modules/`, made by copying a sibling, whatever its size. Never a loose class beside the others, and never a directory at a module's root.
- **Which `modules/{Family}/`?** The one in the module that owns what the member knows. A member that knows only the family's subject goes under the family's home. A member that knows another module's subject goes in that module, under a module of the same family name.
- **Is this the second kind, and the family has no module yet?** This is the moment the family is promoted: create the family module, and move the first kind into it as a member module too. See [`promotion-criteria.md`](promotion-criteria.md#family--kinds-of-the-same-thing).
- **Is it the first and only kind?** Not a family module yet: place the class by the questions above and write the family's name and one-row table down.

Everything the member needs (its tests, its fakes, its entry points) goes inside the member, even when a sibling has a similar piece.

### 7. If the module doesn't exist yet?

Create it. Start flat — a `README.md` and the new class, nothing else. Let the module accrue directories as code is added; never scaffold empty directories upfront.

## When nothing fits

If you can't answer "which module owns this?" cleanly, you have one of three problems:

1. **The class belongs in a module that doesn't exist yet.** Create the module.
2. **The class is two unrelated things stuck together.** Split it; place each piece separately.
3. **You're tempted to create a `helpers/`, `util/`, or `common/` directory.** Stop. Those are forbidden. Place each piece in the module that owns the behaviour. If there genuinely is no owner, you're missing a module — create one.

## Pre-placement check

Before committing to a placement, perform this check:

> **Name 1–2 alternative homes for the class. Pick the strongest.**

The first home that comes to mind is often shaped by the class's name. Listing alternatives reveals when the name is leading you astray. The check is mechanical, takes 10 seconds, and catches placement-gravity bugs before they ship. See [`naming-and-placement.md`](naming-and-placement.md).

## Worked examples

> **Adding `RoundCurrencyService`** — a helper for rounding currency to two decimals.
>
> Lookup: a service. Owner: rounding currency is a primitive used by Billing's calculation logic. Public or internal? Only Billing's own services call it — internal. Place: `modules/Billing/services/RoundCurrencyService`.

> **Adding `IssueCode`** — an enum of validation issue codes.
>
> Lookup: an enum → `{Module}/enums/`. Owner: validation issue codes are produced by Billing's calculation logic; other modules consume them. Producer wins. Place: `modules/Billing/enums/IssueCode` — and since other modules consume it, publish it: `modules/Billing/public/enums/IssueCode`. (Note the name: `IssueCode`, not `BillingIssueCode` — the namespace already says Billing.)

> **Adding `PaymentReceivedListener`** — a listener that reacts to a Billing event from inside Analytics.
>
> Lookup: a listener → `{Module}/entrypoints/listeners/`. Owner: this lives with the *consumer* (the module that reacts), not the producer. Place: `modules/Analytics/entrypoints/listeners/PaymentReceivedListener`.

> **Adding a bank-transfer payment gateway** — a third gateway beside two existing ones; it is a single class.
>
> Lookup: a member of a family. The family module exists: `modules/Payment/modules/PaymentGateway/`. A gateway knows only about taking payments, so it lives under the family's home. Place: `modules/Payment/modules/PaymentGateway/modules/BankTransfer/public/services/BankTransferPaymentGateway`, with a README, copied from a sibling. One class is not a reason to put it anywhere else.

> **Adding `RefundService`** — a service that issues refunds.
>
> Lookup: a service. Owner: refunds are a Billing operation. Public or internal? Refunds are user-facing — outsiders (handlers, commands) trigger them. Public. Place: `modules/Billing/public/services/RefundService`. (Note: `RefundService`, not `BillingRefundService` — the namespace already encodes the module.)

> **Changed 11 November 2026.** The variant branch (`framework/public/contracts/`) became the family branch, and question 6 was added. Reason: every child module now lives under `modules/`, a family is a module, and a member is always a module, so placing a new kind is a lookup rather than a judgment about its size.

## See also

- [`directories.md`](directories.md) — what goes in each directory
- [`naming-and-placement.md`](naming-and-placement.md) — how naming influences placement
- [`promotion-criteria.md`](promotion-criteria.md) — when to add structural elements
