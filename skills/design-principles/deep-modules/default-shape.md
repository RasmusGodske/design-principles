---
type: lookup-reference
title: Default Shape
description: The full module template — every role/directory it can contain and which are required versus optional when creating or sanity-checking a module.
---

# Default Shape

The full template for a module under this convention. Every role is described in [`directories.md`](directories.md); this file shows how they fit together and what is required vs. optional.

Directory names below are the convention's neutral defaults. Your stack's [binding](bindings/) may spell them differently (casing, an `entrypoints/` split into `http/`, `cli/`, `jobs/`, …) — the *roles* and the *rules* are what transfer.

## The minimum viable module

The smallest valid module is a README and one public service:

```
modules/Billing/
├── README.md
└── public/
    ├── services/
    │   └── BillingService
    └── contracts/
        └── BillingServiceContract     ← optional — if the module exposes a reusable interface
```

That is a complete, valid module. No models, no data classes, no entry points — just one service that does something.

## The full template

A module that needs more fills out the template:

```
modules/{Domain}/
├── README.md                              ← REQUIRED
├── {wiring file}                          ← optional — only if bindings/registration earn it
│
├── public/                                ← REQUIRED — the ONLY importable surface (the contract)
│   ├── services/                          ← optional — public services (mutations, orchestrating queries)
│   ├── data/                              ← optional — published data classes (the contract vocabulary)
│   ├── enums/                             ← optional — published enums
│   ├── events/                            ← optional — published events (fired inside, listened to outside)
│   ├── exceptions/                        ← optional — published exceptions (caught by outsiders)
│   └── contracts/                         ← optional — published interfaces others implement
│
├── modules/                               ← optional — every child module: sub-modules and family modules
│
├── services/                              ← optional — internal services
├── models/                                ← optional — persistence entities (internal)
├── data/                                  ← optional — internal data classes
├── enums/                                 ← optional — internal enums
└── entrypoints/                           ← optional — HTTP handlers, CLI commands, jobs, listeners (internal)
```

## What is required

Every module has:

1. **`README.md`** at the module root — one paragraph: what does this module hide?
2. **One of three shape minimums**, depending on the module's purpose:
   - At least one service in `public/services/` — a **leaf module** (the most common case)
   - A `modules/` directory containing sub-modules — a **container module** that exists purely to organize sub-modules
   - A contract in `public/contracts/` that other modules implement — a **contract module** that publishes a shared abstraction

Everything else is optional. A directory exists only when the module has something to put in it. **Never create empty directories as scaffolding** — they quietly become noise and signal nothing.

### The three minimum shapes

```
Leaf module — has services, does work
   modules/Billing/
   ├── README.md
   └── public/services/BillingService

Container module — organizes sub-modules
   modules/Reporting/
   ├── README.md
   └── modules/
       ├── Sales/...
       └── Inventory/...

Contract module — publishes a shared abstraction
   modules/Presentation/
   ├── README.md
   └── public/contracts/DataVisualizationContract
```

## How a module grows

A small module starts with the minimum and adds directories as code accrues. There is no fixed "first add X, then Y" order — directories appear when the code needs them.

```
1. Start
   modules/Reporting/
   ├── README.md
   └── public/services/ReportingService

2. First persistence entity
   modules/Reporting/
   ├── README.md
   ├── public/services/
   └── models/

3. Data classes and an HTTP entry point
   modules/Reporting/
   ├── README.md
   ├── public/services/
   ├── models/
   ├── data/
   └── entrypoints/http/

4. Internal services emerge
   modules/Reporting/
   ├── README.md
   ├── public/services/
   ├── services/                            ← internal helpers split out from public/services
   ├── models/
   ├── data/
   └── entrypoints/http/
```

The ordering above is illustrative, not prescriptive.

## Decomposed shapes

When a module needs to decompose, every child goes under `modules/`: a sub-module for a slice, a family module for the kinds of one thing (see the [README](README.md) "Decomposing a module" section for the rationale and [`promotion-criteria.md`](promotion-criteria.md) for the rules).

### With sub-modules

```
modules/Billing/
├── README.md
├── public/services/                  ← only if cross-sub-module orchestration exists
└── modules/
    ├── Calculation/                  ← full template, recursively
    │   ├── README.md
    │   ├── public/services/
    │   └── ...
    └── Invoicing/                    ← full template, recursively
        ├── README.md
        ├── public/services/
        └── ...
```

### With a family

A family is a module named after the family, in the singular. Its members are modules under its `modules/`, all of one shape.

```
modules/Payment/
├── README.md
├── public/services/                  ← the payment's own services
└── modules/
    ├── PaymentGateway/               ← the family module
    │   ├── README.md                 ← holds the family's table
    │   ├── public/contracts/         ← interface every member implements
    │   ├── public/services/          ← code that works on any member
    │   └── modules/
    │       ├── Stripe/               ← member — a module
    │       │   ├── README.md
    │       │   ├── public/services/  ← StripePaymentGateway
    │       │   └── ...               ← its client, its sandbox stub, its entry points
    │       └── Paypal/               ← member — same shape as its sibling
    │           ├── README.md
    │           ├── public/services/
    │           └── ...
    └── Refund/                       ← an ordinary sub-module beside the family
```

A family of small members has the same shape. Each member is a module even when it is one class:

```
modules/Reporting/modules/ReportFormat/
├── README.md
├── public/contracts/ReportFormat
└── modules/
    ├── Csv/
    │   ├── README.md
    │   └── public/services/CsvReportFormat
    ├── Pdf/
    │   ├── README.md
    │   └── public/services/PdfReportFormat
    └── Json/
        ├── README.md
        └── public/services/JsonReportFormat
```

### With members in other modules

A member lives where what it knows lives. When that is another module, that module holds its members under a module of the same family name, and the family's home keeps only the contract, the registry and the table.

```
modules/Audit/                               ← the family's home
├── README.md
├── public/contracts/AuditCheck
└── public/services/AuditCheckRegistry

modules/Billing/modules/AuditCheck/          ← Billing's members
└── modules/
    ├── UnpaidInvoice/
    └── DuplicateCharge/
```

### A member with sub-modules

A member is a module, so the template applies inside it too.

```
modules/{Domain}/modules/{Family}/    ← e.g. Payment, PaymentGateway
└── modules/{Member}/                 ← e.g. Stripe
    ├── README.md
    ├── public/services/
    └── modules/{SubModule}/          ← e.g. Webhook, Dispute
        ├── README.md
        ├── public/services/
        └── ...
```

Depth is not a cost to limit: a long path that shows the hierarchy is a summary read without opening a file. What each level must pass is the deletion test on the thing it owns. See [`promotion-criteria.md`](promotion-criteria.md).

> **Changed 11 November 2026.** The "With variants" and "With both" shapes (a `framework/` directory and variant directories at the module's root) are replaced by the family shape. A module's root now holds only reserved directories, so the tree itself says what is structure and what is a child, and one module can hold several families.

## Where to go next

- [`directories.md`](directories.md) — what each role/directory is for, who may import from it
- [`promotion-criteria.md`](promotion-criteria.md) — when each optional element earns its place
- [`examples/`](examples/README.md) — full worked examples for each shape
- [`bindings/`](bindings/) — what these directories are called in your stack
