---
type: concept-explainer
title: "Example: Domain with Sub-Modules — Billing"
description: A worked leaf module decomposed into sub-modules with parent orchestration, for a domain that has grown internal complexity worth hiding.
---

# Example: Domain with Sub-Modules — Billing

A billing domain that has grown enough internal complexity to warrant decomposition. Calculation and invoicing are independent enough to be sub-modules; the parent hosts the orchestration that ties them together.

## Shape

```text
modules/billing/
├── README.md
├── wiring                                ← earned: one listener needs manual registration
├── public/
│   └── services/
│       └── BillingService                ← orchestrates Calculation + Invoicing
├── models/
│   └── BillingCycle                      ← parent-owned, used by both sub-modules
├── enums/
│   └── BillingStatus
├── events/
│   ├── CycleStarted
│   └── CycleClosed
└── modules/
    ├── calculation/
    │   ├── README.md
    │   ├── public/services/
    │   │   └── CalculationService
    │   ├── services/
    │   │   ├── LineItemAggregator
    │   │   └── DiscountResolver
    │   ├── data/
    │   │   ├── CalculationRequestData
    │   │   └── CalculationResultData
    │   └── exceptions/
    │       └── CalculationFailed
    └── invoicing/
        ├── README.md
        ├── public/services/
        │   └── InvoiceService
        ├── services/
        │   └── PdfRenderer
        ├── models/
        │   └── Invoice
        ├── data/
        │   └── InvoiceData
        └── entrypoints/http/
            └── InvoicesController        ← Invoicing owns its HTTP entry
```

## Parent README content

```markdown
# Billing

Coordinates billing cycles by orchestrating calculation and invoicing for each customer. Owns the cycle lifecycle and enforces the invariant that a customer is never billed twice for the same period.

Public surface:
- BillingService — close a billing cycle for a customer

Sub-modules:
- Calculation — computes line items, discounts, totals
- Invoicing — renders and persists invoices

Guarantees:
- A BillingCycle can only be closed once
- Closing runs Calculation then Invoicing inside a single transaction
```

## Why this shape

- **Sub-modules earn their place.** Calculation and Invoicing each have their own services, data, and (for Invoicing) models. Inlining either back into `billing/public/services/` would noticeably bloat the parent.
- **Parent has its own `public/services/`** because `BillingService.closeCycle()` orchestrates Calculation + Invoicing inside a transaction with the "never bill twice" invariant. That orchestration *requires* a parent-owned home.
- **Parent has `models/`** (`BillingCycle`) because the value is used by both sub-modules. Placing it in either sub-module would create a cross-sub-module model dependency. Promoting it to the parent is the right call.
- **A wiring file exists** because Billing registers an event listener that the stack's auto-discovery can't infer. That is the one case wiring is earned.
- **Invoicing has its own HTTP entry point** — invoice display and download are user-facing concerns owned by Invoicing, not the parent.

## Cross-sub-module flow

```mermaid
sequenceDiagram
    participant C as Entry point
    participant B as BillingService
    participant Calc as Calculation
    participant Inv as Invoicing

    C->>B: closeCycle(cycle)
    B->>Calc: calculate(cycle)
    Calc-->>B: CalculationResult
    B->>Inv: render(cycle, result)
    Inv-->>B: Invoice
    B-->>C: ClosedCycleResult
```

Calculation and Invoicing don't talk directly. The parent orchestrates.

## Where alternative shapes would be wrong

- **Single flat module** would put `LineItemAggregator`, `DiscountResolver`, `PdfRenderer`, `CalculationService`, `InvoiceService` all in one `services/` directory. Two distinct concerns share a single namespace, and the public/internal split becomes harder to read.
- **No parent `public/services/`** would force callers to know they have to call Calculation, then Invoicing, in the right order, in a transaction, with the "never twice" check. That's exactly the orchestration the parent should hide.
- **Calculation calling Invoicing directly** would create cross-sub-module coupling. Sub-modules are public peers; their orchestration is the parent's job.
