---
type: concept-explainer
title: "Example: Contract Module — Presentation"
description: A worked contract module that publishes a shared abstraction implemented by independent modules, with no services or models of its own.
---

# Example: Contract Module — Presentation

A module whose entire purpose is to publish a shared abstraction. Multiple independent modules implement the contract; the contract module itself contains no services, models, or jobs.

This pattern applies when:

- Multiple **independent** modules need to share an abstraction
- The implementers are not kinds of one thing that someone chooses between; each is its own module's way of taking part (otherwise they are a family, and [`family.md`](family.md) is the right pattern)
- No single module is the natural owner of the abstraction
- The abstraction is small (one or a few interfaces) and stable

## Shape

```text
modules/presentation/
├── README.md
└── public/contracts/
    └── DataVisualization                 ← the published abstraction
```

That's the entire module. Just a README and one or more contracts. No services, no models — those live in the modules that implement the contract.

## How it gets used

Two unrelated top-level modules implement the contract:

```text
modules/reports/
├── README.md
├── public/services/
│   └── ReportPresenterService            ← implements DataVisualization
└── ...

modules/analytics/
├── README.md
├── public/services/
│   └── AnalyticsPresenterService         ← implements DataVisualization
└── ...
```

A consumer that wants to render either a report or an analytics view depends on the contract:

```text
function render(presenter: DataVisualization) -> string
    return presenter.renderHtml()
```

Whichever implementation is passed (or resolved by the stack's dependency mechanism) satisfies it.

## Presentation README content

```markdown
# Presentation

Publishes the abstraction that any module can implement to expose data for visualization. Modules with their own data (Reports, Analytics) implement the contract; consumers (the rendering pipeline, the export feature) depend on the contract rather than concrete classes.

Public surface:
- DataVisualization — every visualizable thing implements this interface

Implementers (across the codebase):
- reports/public/services/ReportPresenterService
- analytics/public/services/AnalyticsPresenterService

Guarantees:
- The contract is small and stable. Changing it is a coordinated change across all implementers.
- Implementers do not depend on each other; only on the contract.
```

## Why this shape (and not a family)?

A family is for kinds of one thing that are chosen between: Stripe and PayPal are both payment gateways, a charge goes through one of them, and each is a member module under the family module (see [`family.md`](family.md)). Making the implementers here a family would give this:

```text
modules/visualization/                    ← but this says a report and an analytics
└── modules/                                 view are two kinds of one thing, which
    ├── report/                              isn't the case — each is a capability
    └── analytics/                           of an independent domain
```

Reports and Analytics are independent domains that each *can be visualized*. Nobody picks between them, and neither is a member that could be copied to make the next one. Each implements the contract with a service it already has. Forcing them under a family module obscures that.

A contract module captures the right structure: a small, dedicated module publishes the abstraction; independent modules implement it.

A family can also have its members spread over several modules: each member then sits in the module that owns what it knows, under a module named after the family, and the family's home keeps the contract and a registry (see the family rules in the [README](../README.md#families--for-kinds-of-the-same-thing)). The difference from a contract module is the same: those members are kinds of one thing, listed in one table and chosen between.

## Why this shape (and not embedding the contract in one of the implementers)?

Putting the contract in `reports/public/contracts/` would imply Reports owns the abstraction. Then Analytics depends on Reports just to get the contract — which is asymmetric and arbitrary, and creates a false hierarchy where there is none. Promoting the contract to its own module avoids the false ownership.

## Where alternative shapes would be wrong

- **Putting the contract in `shared/contracts/`** — the convention forbids junk-drawer names. `shared/` is exactly the kind of dumping ground that grows uncontrollably.
- **Bundling unrelated contracts into one module.** Each contract module should publish one cohesive abstraction. If you find yourself adding `Metrics`, `Export`, and `Audit` contracts to the same module, they should each live in their own module — they're not the same abstraction.
- **Adding services "while we're here."** Once a contract module gains services or models, it's no longer a contract module — it's a leaf module. Either move services out into one of the implementing modules, or accept the module is becoming something more substantial and update the README to match.

## When to use this pattern

Add a contract module when ALL of these are true today:

- Two or more independent modules need to implement the same abstraction
- The implementers are not kinds of one thing chosen between (otherwise they are a family: use a family module)
- No single module is the natural owner of the abstraction
- The abstraction is small (one or a few interfaces) and stable

If only one implementer exists today, don't pre-create a contract module — wait for the second. The convention's "earned, not speculative" principle applies here: a contract module with one implementer is shallow ceremony.

> **Changed 11 November 2026.** The comparison with the `framework/` layout became a comparison with a family. Reason: the variant layout is retired, and a family's members may now live in several modules, so what separates a contract module from a family is whether the implementers are kinds of one thing that are chosen between, not where they sit.
