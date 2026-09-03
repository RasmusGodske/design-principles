---
type: binding-rule
title: Naming and Placement
description: Why a class is named for what it is rather than where it lives, the one case where a class carries its module's name — being the module's face toward an outsider — and how naming choices drive placement.
---

# Naming and Placement

Names describe what a class IS, not where it lives. A class carries its module's name only when it *is* the module's face toward some outsider; everything the module merely contains is named for what it is.

This is one of the cheapest, highest-value rules in the convention. Names that encode location create *placement gravity* — once a class is named after a module, moving it later requires renaming and updating references across the codebase, and worse, the name answers the ownership question before anyone asked it.

## Why this matters

Naming creates implicit assumptions about ownership. Consider a class named `BillingIssueCode`. Where would you place it?

> Most readers say: the Billing module.

But the class might actually be a *Validation* concept that Billing happens to use — and other modules use it too. The name "BillingIssueCode" pulled it into Billing because the prefix forced placement. With the right name (`IssueCode`), the question of ownership stays open until you actually answer it — and you can place it where it genuinely belongs.

This is a common failure mode: validation primitives end up locked into the wrong module because their names told everyone where they belonged. The fix is the rule: drop the redundant module prefix.

## The rule

1. **Class names describe what the class IS.** A `Validator`, an `IssueCode`, a `PaymentRequest`, a `PriceCalculator`. The module name belongs in the namespace / package path.
2. **Services are named by what they DO.** Multiple services in the same module each describe a distinct action: `InvoiceCalculationService`, `RefundService`, `PaymentChargeService` — not `BillingInvoiceService`, `BillingRefundService`.
3. **A class carries the module's name only when it is the module's face toward an outsider.** A module presents itself to two kinds of outsider, and the classes that do the presenting are legitimately named after it:
   - **toward other modules** — the primary public service, the front door other modules call: `BillingService`;
   - **toward the framework** — the pieces the framework itself registers per module and nothing else calls: a module descriptor, a wiring file. Which pieces exist is a property of the stack, so each [binding](bindings/) lists them.

   These classes cannot move to another module, because the module cannot exist toward that outsider without them. Naming them after the module is accurate, not gravity.
4. **Everything else is named for what it is — published or not.** Being on the public surface is *not* the test. A published `InvoiceData` is still `InvoiceData`, and a public `RefundService` is still `RefundService`: they are things Billing contains, and either could in principle live elsewhere. Their names keep that question open.
5. **Reserve module prefixes for genuine disambiguation** beyond rule 3. If two `IssueCode` enums in different modules coexist in the same caller's scope, a prefix may be needed — but this is rare. Usually one of them belongs elsewhere.

### The test in one line

> **Is this class the module itself, or something the module contains?** The module's faces carry its name. Its contents do not.

### Worked example: one module, two stacks

The rule is the same everywhere; only the number of faces changes with the stack's idiom. The stack decides which framework-facing classes exist: one stack has a wiring file only when one is earned, another requires a module descriptor on every module.

| Class | Module prefix? | Why |
|---|---|---|
| the primary public service (`BillingService`) | yes | the module's face toward other modules |
| the module descriptor / wiring file, where the stack has one | yes | the module's face toward the container |
| a controller / HTTP handler | no | a module may have none or several; a stack's file idiom may name the primary one after the module, which is idiom, not a face |
| a secondary service (`RefundService`) | no | something the module contains, named for what it does |
| a value or enum (`IssueCode`) | no | could belong elsewhere; the name keeps that open |
| a data class (`InvoiceData`) | no | published or not, it is a thing, not the module |
| a guard, listener, job, or other internal entry point | no | named for what it checks or does |

## The pre-placement check

Before committing to a placement, perform this check:

> **Name 1–2 alternative homes for the class. Pick the strongest.**

The first home that comes to mind is often shaped by the class's name. Listing alternatives reveals when the name is leading you astray. The check is mechanical, takes 10 seconds, and catches placement-gravity bugs before they ship.

> **Worked example: adding `PaymentReceivedData`.**
>
> First instinct: `Notifications/data/` (it's used to render a payment notification).
> Alternative homes: `Billing/data/` (Billing produces the value when a payment is recorded), `Notifications/data/` (Notifications consumes it for a message template).
> Strongest: `Billing/data/`. The producer owns the value type. Notifications consumes it as a published reference.
> Place at `modules/Billing/public/data/PaymentReceivedData`.

The first instinct was driven by the consumer (Notifications) because that's where the developer was working when they thought of the class. The alternative-homes check rebalanced toward the producer, which is the right owner.

## Common smells and how to fix them

| Smell | Why it's a smell | Fix |
|---|---|---|
| `BillingPaymentService` (module prefix on a secondary service) | The namespace already says Billing, and the class is not the module's face | `PaymentService` |
| `DraftIssueCode` (module prefix on a value class) | Encodes location into the name | `IssueCode` |
| `PaymentReceivedNotificationData` (consumer suffix on a producer's value) | Names the consumer instead of what the class IS | `PaymentReceivedData` |
| `PriceHelper`, `BillingManager`, `InvoiceUtil` | "Helper", "Manager", "Util" describe nothing | Rename to describe what the class DOES (`PriceRounder`, `InvoiceDispatcher`) |
| `PaymentService` renamed to `BillingService` "because it is public" | Being published does not make a class the module's face; only the primary front door is | keep `PaymentService` |

## Why the rule lives in code, not memory

A naming rule that depends on individual discipline gets violated under deadline pressure. The pre-placement check is the rule made operational — it adds a mechanical step (name 1–2 alternatives) that is small enough to do every time but specific enough to catch the failure mode.

If you find yourself frequently rejecting alternatives that turned out to be obvious in hindsight, that's a sign the project's module ownership is unclear. The check is doing its job by surfacing the ambiguity.

## Data-class layers

Within a module's `data/`, a data class belongs to one of three layers, and the name should say which:

- a **domain** value — an entity value used by services and logic, at `data/` root;
- an **entry point's per-action payload**, under `data/entrypoints/{Handler}/`;
- a **shared presentational** projection reused across handlers, under `data/views/`.

The principle asks for one recognisable suffix per layer so the name alone tells you what it is. The *spelling* of those suffixes is a stack habit and lives in the binding (one stack may write `*Data` / `*PayloadData` / `*ViewData`, another `*Dto` / `*RequestDto` / `*ViewDto`). This is the layer axis, orthogonal to the module-prefix rule above: `InvoiceData`, not `BillingInvoiceData`, in either case. See [`directories.md`](directories.md#publicdata) for the placement rule.

## See also

- [`decision-tree.md`](decision-tree.md) — placement steps that include this check
- [`directories.md`](directories.md) — what goes where
- [`promotion-criteria.md`](promotion-criteria.md) — how speculative naming leads to speculative directories
- [`bindings/`](bindings/) — which classes are a module's faces in each stack, and how suffixes are spelled
