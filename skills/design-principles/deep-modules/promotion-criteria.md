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

This applies recursively — to modules, sub-modules, families, contracts, and wiring files.

## Internal `services/`

**Default:** absent.

**Promote when:** `public/services/` accumulates internal helpers that would clutter its public surface, OR a service is genuinely module-private (only called by other services in the same module).

**Do not promote when:** the helper is one method long. Inline it.

> Example: A `BillingService` (public) accumulates a `CurrencyRoundingHelper` and a `LineItemAggregator` — neither of which outsiders should call. Move them to internal `services/` so the public surface stays clean.

## `modules/` — sub-modules

**Default:** absent.

**Promote when:** a piece of the module has enough internal complexity that hiding it behind a smaller interface improves the parent. Apply the deletion test: *if you inlined the sub-module back into the parent's `services/`, `data/`, and `models/`, would the parent get noticeably worse to navigate?*

**Do not promote when:** the candidate is one or two services. That is shallow ceremony — keep it flat. **This rule does not apply to a member of a family**: a member is always a module, even with one class, because the deletion test is applied to the family as a whole (see [Family](#family--kinds-of-the-same-thing) below).

**A sub-module is a slice of the domain, never a way of presenting it.** Its name is something the domain *has* (invoicing, calculation, invitations), not a place it is shown. A page, a screen, a tab, a report layout or a view of the module's data presents the parent's entities, so it belongs to the parent, however many classes it takes: its view shapes and the services that build them sit beside the parent's other public services. Two reasons:

- **A presentation owns nothing.** Ask what the sub-module would own. "The customer page" owns no entity and no rule; the customer module owns the customer, and the page only shows it.
- **Presentations multiply.** The same overview is shown on a page, returned by an API, handed to an assistant. A module named after one of them reads as if the others belong somewhere else.

A list, a search, a query endpoint or a picker's data is a presentation too, however much logic it holds. Write down what the candidate owns before creating it. If the sentence is "it owns only the list" (or "only the page", "only the export"), the sub-module fails this test: put its classes in the module that owns the entity being listed.

**When no module owns the entity yet**, that is the gap to fix: the first service the entity needs founds its owning module, named after the entity. Never name the new module after that first service or its class prefix (an `InvoiceListQueryService` does not make an `InvoiceList` module). If the domain is itself named after the entity, the domain owns it; see the parent-level section below.

> Counter-example: an invoice list query (search, sort and paging over the invoices a person may see) goes into `modules/InvoiceList/`, whose README says "nothing owns the invoice itself yet; this module owns only the list". That sentence is the failed test. The list belongs to the invoice's owner, as a payment list belongs to the payment's owner; if no module owns invoices, this is the moment to found the one that does.

> Counter-example: a customer page with five tabs gets a `modules/CustomerPage/` holding the five views and their controller. Inline it: the views go in the customer module's public services and public data, the controller in its entry points. The parent gets five more classes and no new concept, so it is not worse to navigate; the sub-module was a folder named after a screen.

> Example: `modules/Billing/` is growing. Calculation logic has its own data structures, services, and a state machine. Invoicing has its own template engine and a separate set of services. Both qualify — they get promoted to `modules/Calculation/` and `modules/Invoicing/`.
>
> Counter-example: A small "send a payment reminder" feature is just one service. It stays as `public/services/PaymentReminderService`. Wrapping it in `modules/Reminders/` would be ceremony with no payoff.

## Family — kinds of the same thing

**Default:** absent.

**Promote when:** a second member exists AND you can name the family cleanly (the question its members answer: "which payment gateway?", "which report format?"). The family then becomes a module named after it, in the singular, under the owning module's `modules/`, and every member becomes a module under the family module's `modules/`.

**Do not promote when:** the second member is hypothetical ("we might add another payment provider someday"). Until it exists, the family is a name and a one-row table ([`concept-families`](../concept-families/README.md), rule 4), and the single implementation stays where it is.

**A value or a family?** Kinds that are only labels, stored and compared, stay a value (an enumeration). Kinds become a family of member modules the moment any kind has behaviour of its own: code that branches on the value, including a method on the enumeration that answers per case. An enumeration that grows such methods (`needsRedirect()`, `supportsRefunds()`, …) is holding pieces of each member's behaviour with no module for them to live in.

Once the family module exists, three things hold without further judgment:

- **A member is always a module, and all members have one shape.** A one-class member is a module like its larger siblings; no family mixes loose classes and modules, and no member is promoted later. A new member is made by copying a sibling.
- **The deletion test is applied to the family, never to one member.** Callers learn only the family's contract, so a member adds nothing to what they must know, whatever its size. Asking "does this small member earn a module?" is the wrong question; ask whether the family earns its contract.
- **A member brings everything it needs.** Its tests, fakes, fixtures, entry points and pages live inside it, also when a sibling has similar ones. Only the contract and code that truly serves every member lives in the family module, and nothing in the family module names a member.

A member lives where what it knows lives: under the family module when it knows only the family's subject, otherwise in the module that owns what it knows, under a module of the same family name (`modules/Billing/modules/AuditCheck/modules/UnpaidInvoice/`).

> Example: `modules/Payment/` charges through both Stripe and Paypal. The family is "payment gateway" — clearly named. It becomes `modules/Payment/modules/PaymentGateway/`, holding the `PaymentGateway` contract and the services that work on any gateway. Each provider is a member module under its `modules/`, carrying its own client and its own sandbox stub.
>
> Example: a report can be written as CSV, PDF or JSON, each a single class. They are still three member modules under `modules/ReportFormat/modules/`, not three classes in a directory, and not an enumeration with a method per question.
>
> Counter-example: `modules/Notification/` sends emails today. There's a vague sense that text messages might come later. **Don't** promote yet — wait for the second member. A family module with one member is harder to read than a flat module.
>
> Counter-example: both gateways need a fake provider for local runs, so one shared fake goes into the family module and asks each member what to answer. Now the family knows its members. Give each member its own stub.

> **Changed 11 November 2026.** This section replaces "`framework/` — variants". The promotion test is unchanged (a second member, a clean name); what is new is that the family is a module under `modules/`, that members are always modules of one shape, and that the deletion test is applied to the family as a whole. Reason: the old layout had no shape for small members and left the "is this member big enough?" question open for every member.

## `contracts/`

**Default:** absent.

**Promote when:** ≥2 implementations exist today, OR the module is a family module whose members implement it.

**Do not promote when:** there is one implementation. The service class IS the contract.

> Example: `modules/PaymentGateway/public/contracts/PaymentGateway` defines what every gateway must implement. Stripe and Paypal both implement it. That qualifies.
>
> Counter-example: A `BillingService` with one method, `chargeCustomer()`. Wrapping it in a `BillingContract` interface "for testability" is shallow ceremony — mock the concrete class. Extract the interface only when a second implementation actually exists.

## Wiring file

**Default:** absent. Most modules don't need one.

**Promote when:** the module has something for the wiring to do — a family member making itself known to its family, observers/hooks the stack doesn't discover, non-trivial singletons, or manual event wiring.

**Do not promote when:** the module is just services, models, and entry points using constructor injection.

See the [Wiring section of `directories.md`](directories.md#wiring) for the full rule and anti-patterns, and your [binding](bindings/) for the stack's mechanism.

## Parent-level `public/services/` when sub-modules exist

**Default:** absent. Sub-modules are public peers by default.

**Promote when:** there is real cross-sub-module orchestration to host:
- Transactions spanning multiple sub-modules
- Invariants only the parent can enforce
- A single point that enforces ordering between sub-modules

Also **when the parent is named after an entity and owns it**: an `Order` domain owns the order, so the order's own services (its list query, its on-behalf service) sit in `modules/Order/public/services/`, beside the sub-modules for what an order has (its lines, its shipments, its refunds). This is not orchestration and needs none; it is the parent being a leaf for its own entity.

**Do not promote when:** the parent's only job would be to delegate. A facade with no logic is shallow ceremony.

> Example: `modules/Billing/public/services/BillingService` exists because invoicing a customer requires both `modules/Calculation/` and `modules/Invoicing/` to run in a specific order, inside a transaction, with a domain invariant ("never bill twice in the same period"). The parent service hosts that orchestration.
>
> Counter-example: A `modules/Reporting/` module with `modules/Sales/` and `modules/Inventory/`. Outsiders call them independently; nothing orchestrates between them. **Don't** add `public/services/ReportingService` — sub-modules are public peers, callers go to them directly.

## A note on compounding

Each "earned, not speculative" decision compounds. A module that adds nothing speculatively is small and easy to navigate. A module that adds everything speculatively is full of empty directories, one-implementation interfaces, and delegating facades — noise that obscures the real shape.

When in doubt: **leave it out.** It is much cheaper to add an element later than to remove one once it is wired up. Depth is not what this guards against: a long path that shows a real hierarchy costs nothing. The cost is an element that owns nothing.

## See also

- [`default-shape.md`](default-shape.md) — the template
- [`directories.md`](directories.md) — directory reference, including wiring
- [`public-surface.md`](public-surface.md) — the public boundary
