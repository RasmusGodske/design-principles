---
type: binding-rule
title: Naming and Placement
description: Why class names must describe what a class is rather than where it lives, and how naming choices drive a class's placement.
---

# Naming and Placement

Names describe what a class IS, not where it lives. The module name belongs in the namespace / package path, not the class name.

This is one of the cheapest, highest-value rules in the convention. Names that encode location create *placement gravity* — once a class is named after a module, moving it later requires renaming and updating references across the codebase. Generic names that describe the class's nature are easier to relocate.

## Why this matters

Naming creates implicit assumptions about ownership. Consider a class named `BillingIssueCode`. Where would you place it?

> Most readers say: the Billing module.

But the class might actually be a *Validation* concept that Billing happens to use — and other modules use it too. The name "BillingIssueCode" pulled it into Billing because the prefix forced placement. With the right name (`IssueCode`), the question of ownership stays open until you actually answer it — and you can place it where it genuinely belongs.

This is a common failure mode: validation primitives end up locked into the wrong module because their names told everyone where they belonged. The fix is the rule: drop the redundant module prefix.

## The rule

1. **Module name belongs in the namespace / package path, not the class name.** `modules/Billing/enums/IssueCode` (`Billing.Enums.IssueCode`), not `modules/Billing/enums/BillingIssueCode`.
2. **Class names describe what the class IS.** A `Validator`, an `IssueCode`, a `PaymentRequest`, a `PriceCalculator`.
3. **Service classes are named by what they DO,** not by their module. Multiple services in the same module each describe a distinct action: `InvoiceCalculationService`, `RefundService`, `PaymentChargeService` — not `BillingInvoiceService`, `BillingRefundService`, etc.
4. **Reserve module prefixes for genuine disambiguation.** If two `IssueCode` enums in different modules coexist in the same caller's scope, a prefix may be needed — but this is rare. Usually one of them belongs elsewhere.

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
| `BillingPaymentService` (module prefix on a non-main service) | The namespace already says Billing | `PaymentService` |
| `DraftIssueCode` (module prefix on a value class) | Encodes location into the name | `IssueCode` |
| `PaymentReceivedNotificationData` (consumer suffix on a producer's value) | Names the consumer instead of what the class IS | `PaymentReceivedData` |
| `PriceHelper`, `BillingManager`, `InvoiceUtil` | "Helper", "Manager", "Util" describe nothing | Rename to describe what the class DOES (`PriceRounder`, `InvoiceDispatcher`) |

## When the prefix IS justified

Module prefixes are appropriate in narrow cases:

- **The single primary public service** for a module: `BillingService`, `NotificationsService`. This works because the name accurately describes the module's overall orchestration entry point — the class IS "the billing service" in a real sense.
- **Genuine disambiguation across modules** when two classes with the same generic name coexist in the same caller's scope. Rare in practice.

If neither applies: drop the prefix.

## Why the rule lives in code, not memory

A naming rule that depends on individual discipline gets violated under deadline pressure. The pre-placement check is the rule made operational — it adds a mechanical step (name 1–2 alternatives) that is small enough to do every time but specific enough to catch the failure mode.

If you find yourself frequently rejecting alternatives that turned out to be obvious in hindsight, that's a sign the project's module ownership is unclear. The check is doing its job by surfacing the ambiguity.

## Data-class layer suffixes

Within a module's `data/`, the suffix encodes the *layer* a data class belongs to, so the name alone tells you what it is and where it lives:

- `*Data` — a **domain** data class (an entity value used by services/logic), at `data/` root.
- `*PayloadData` — an **entry point's per-action payload**, under `data/entrypoints/{Handler}/`.
- `*ViewData` — a **shared presentational** projection reused across handlers, under `data/views/`.

This is the layer axis, orthogonal to the "drop the module prefix" rule above (`InvoiceData`, not `BillingInvoiceData`, in either case). See [`directories.md`](directories.md#publicdata) for the full placement rule.

## See also

- [`decision-tree.md`](decision-tree.md) — placement steps that include this check
- [`directories.md`](directories.md) — what goes where
- [`promotion-criteria.md`](promotion-criteria.md) — how speculative naming leads to speculative directories
