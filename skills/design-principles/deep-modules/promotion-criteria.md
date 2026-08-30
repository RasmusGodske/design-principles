---
type: binding-rule
title: Promotion Criteria
description: When each optional structural element of the convention is earned rather than speculative, with the promotion rule and a worked example for each.
---

# Promotion Criteria

Every optional structural element in the convention is **earned**, not speculative. This file lists each one with its promotion rule and a worked example.

## The principle

A structural element earns its place when removing it would make the code noticeably worse. If you cannot articulate why something is needed, it is not needed yet.

The unifying lens is the **deletion test** — imagine deleting the element:

- If complexity reappears in callers, the element was hiding it. Keep it.
- If nothing changes, the element was a pass-through. Remove it.

This applies recursively — to modules, sub-modules, contracts, framework directories, and wiring files.

## Internal `services/`

**Default:** absent.

**Promote when:** `public/services/` accumulates internal helpers that would clutter its public surface, OR a service is genuinely module-private (only called by other services in the same module).

**Do not promote when:** the helper is one method long. Inline it.

> Example: A `BillingService` (public) accumulates a `CurrencyRoundingHelper` and a `LineItemAggregator` — neither of which outsiders should call. Move them to internal `services/` so the public surface stays clean.

## `modules/` — sub-modules

**Default:** absent.

**Promote when:** a piece of the module has enough internal complexity that hiding it behind a smaller interface improves the parent. Apply the deletion test: *if you inlined the sub-module back into the parent's `services/`, `data/`, and `models/`, would the parent get noticeably worse to navigate?*

**Do not promote when:** the candidate is one or two services. That is shallow ceremony — keep it flat.

> Example: `modules/Billing/` is growing. Calculation logic has its own data structures, services, and a state machine. Invoicing has its own template engine and a separate set of services. Both qualify — they get promoted to `modules/Calculation/` and `modules/Invoicing/`.
>
> Counter-example: A small "send a payment reminder" feature is just one service. It stays as `public/services/PaymentReminderService`. Wrapping it in `modules/Reminders/` would be ceremony with no payoff.

## `framework/` — variants

**Default:** absent.

**Promote when:** the module exists in multiple kinds or versions that need to evolve independently AND you can name the variant axis cleanly.

**Do not promote when:** the variant axis is hypothetical ("we might add another payment provider someday"). Promote when the second variant exists, not before.

> Example: `modules/PaymentGateways/` ships with both Stripe and Paypal integrations. The variant axis is "gateway provider" — clearly named. Shared infrastructure (a `PaymentGatewayContract`, services that operate on any gateway) goes in `framework/`. Each provider gets its own variant directory.
>
> Counter-example: `modules/Notifications/` sends emails today. There's a vague sense that SMS might come later. **Don't** promote yet — wait for the second variant. A `framework/` with one variant is harder to read than a flat module.

## `contracts/`

**Default:** absent.

**Promote when:** ≥2 implementations exist today, OR the module is a framework that variants plug into.

**Do not promote when:** there is one implementation. The service class IS the contract.

> Example: `framework/public/contracts/PaymentGatewayContract` defines what every gateway must implement. Stripe and Paypal both implement it. That qualifies.
>
> Counter-example: A `BillingService` with one method, `chargeCustomer()`. Wrapping it in a `BillingContract` interface "for testability" is shallow ceremony — mock the concrete class. Extract the interface only when a second implementation actually exists.

## Wiring file

**Default:** absent. Most modules don't need one.

**Promote when:** the module has something for the wiring to do — variant bindings, observers/hooks the stack doesn't discover, non-trivial singletons, or manual event wiring.

**Do not promote when:** the module is just services, models, and entry points using constructor injection.

See the [Wiring section of `directories.md`](directories.md#wiring) for the full rule and anti-patterns, and your [binding](bindings/) for the stack's mechanism.

## Parent-level `public/services/` when sub-modules exist

**Default:** absent. Sub-modules are public peers by default.

**Promote when:** there is real cross-sub-module orchestration to host:
- Transactions spanning multiple sub-modules
- Invariants only the parent can enforce
- A single point that enforces ordering between sub-modules

**Do not promote when:** the parent's only job would be to delegate. A facade with no logic is shallow ceremony.

> Example: `modules/Billing/public/services/BillingService` exists because invoicing a customer requires both `modules/Calculation/` and `modules/Invoicing/` to run in a specific order, inside a transaction, with a domain invariant ("never bill twice in the same period"). The parent service hosts that orchestration.
>
> Counter-example: A `modules/Reporting/` module with `modules/Sales/` and `modules/Inventory/`. Outsiders call them independently; nothing orchestrates between them. **Don't** add `public/services/ReportingService` — sub-modules are public peers, callers go to them directly.

## A note on compounding

Each "earned, not speculative" decision compounds. A module that adds nothing speculatively is small and easy to navigate. A module that adds everything speculatively is full of empty directories, one-implementation interfaces, and delegating facades — noise that obscures the real shape.

When in doubt: **leave it out.** It is much cheaper to add an element later than to remove one once it is wired up.

## See also

- [`default-shape.md`](default-shape.md) — the template
- [`directories.md`](directories.md) — directory reference, including wiring
- [`public-surface.md`](public-surface.md) — the public boundary
