---
type: concept-explainer
title: "Example: Contract Module — Presentation"
description: A worked contract module that publishes a shared abstraction implemented by independent modules, with no services or models of its own.
---

# Example: Contract Module — Presentation

A module whose entire purpose is to publish a shared abstraction. Multiple independent modules implement the contract; the contract module itself contains no services, models, or jobs.

This pattern applies when:

- Multiple **independent** modules need to share an abstraction
- The implementations live in those independent modules, not as siblings under a parent (otherwise [`variant-framework.md`](variant-framework.md) is the right pattern)
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

## Why this shape (and not `framework/`)?

A `framework/` + variants pattern would imply the implementers are siblings under one parent module:

```text
modules/visualizations/                   ← but this implies Reports and Analytics
├── framework/public/contracts/              are part of the same family, which
├── reports/                                 isn't the case — they're independent
└── analytics/                               top-level domains in the codebase
```

The variant pattern assumes the variants are *a family* — Stripe and PayPal are both payment gateways, and they live under `modules/payment-gateways/`. Reports and Analytics are independent domains that happen to need the same contract; forcing them under a fake umbrella module obscures that.

A contract module captures the right structure: a small, dedicated module publishes the abstraction; independent modules implement it.

## Why this shape (and not embedding the contract in one of the implementers)?

Putting the contract in `reports/public/contracts/` would imply Reports owns the abstraction. Then Analytics depends on Reports just to get the contract — which is asymmetric and arbitrary, and creates a false hierarchy where there is none. Promoting the contract to its own module avoids the false ownership.

## Where alternative shapes would be wrong

- **Putting the contract in `shared/contracts/`** — the convention forbids junk-drawer names. `shared/` is exactly the kind of dumping ground that grows uncontrollably.
- **Bundling unrelated contracts into one module.** Each contract module should publish one cohesive abstraction. If you find yourself adding `Metrics`, `Export`, and `Audit` contracts to the same module, they should each live in their own module — they're not the same abstraction.
- **Adding services "while we're here."** Once a contract module gains services or models, it's no longer a contract module — it's a leaf module. Either move services out into one of the implementing modules, or accept the module is becoming something more substantial and update the README to match.

## When to use this pattern

Add a contract module when ALL of these are true today:

- Two or more independent modules need to implement the same abstraction
- Those modules are not siblings under a natural parent (otherwise use `framework/`)
- No single module is the natural owner of the abstraction
- The abstraction is small (one or a few interfaces) and stable

If only one implementer exists today, don't pre-create a contract module — wait for the second. The convention's "earned, not speculative" principle applies here: a contract module with one implementer is shallow ceremony.
