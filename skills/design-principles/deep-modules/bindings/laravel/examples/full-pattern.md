---
type: concept-explainer
title: "Example: Variants AND Sub-Modules — PaymentGateways with Stripe sub-modules"
description: A worked variant module where one variant has its own sub-modules — the convention applied recursively at full depth.
---

# Example: Variants AND Sub-Modules — PaymentGateways with Stripe sub-modules

A variant module where one of the variants has its own internal complexity, decomposed into sub-modules. This shows the convention applied recursively.

## Shape

```
app/Modules/PaymentGateways/
├── README.md
├── Framework/                               ← shared across variants
│   ├── README.md
│   ├── Public/Contracts/
│   │   └── PaymentGatewayContract.php
│   ├── Public/
│   │   └── Services/
│   │       └── PaymentGatewayDispatcher.php
│   └── Data/
│       └── ChargeRequestData.php
├── Stripe/                                  ← variant — has its own sub-modules
│   ├── README.md
│   ├── StripeServiceProvider.php
│   ├── Public/
│   │   └── Services/
│   │       └── StripeGateway.php            ← orchestrates Stripe sub-modules
│   ├── Models/
│   │   └── StripeAccount.php                ← shared across Stripe sub-modules
│   └── Modules/
│       ├── Charges/
│       │   ├── README.md
│       │   ├── Public/
│       │   │   └── Services/
│       │   │       └── ChargeService.php
│       │   ├── Services/
│       │   │   └── StripeChargeApiClient.php
│       │   └── Data/
│       ├── Webhooks/
│       │   ├── README.md
│       │   ├── Public/
│       │   │   └── Services/
│       │   │       └── WebhookProcessor.php
│       │   ├── Services/
│       │   │   └── SignatureVerifier.php
│       │   ├── Http/Controllers/
│       │   │   └── StripeWebhookController.php
│       │   └── Data/
│       └── Refunds/
│           ├── README.md
│           ├── Public/
│           │   └── Services/
│           │       └── RefundService.php
│           └── Data/
└── Paypal/                                  ← variant — flat, simpler
    ├── README.md
    ├── Public/
    │   └── Services/
    │       └── PaypalGateway.php
    └── ...
```

## Stripe README content

```markdown
# Stripe

Stripe-specific implementation of the PaymentGatewayContract. Decomposes into Charges (one-time payments), Webhooks (inbound notifications from Stripe), and Refunds (cancellations and partial refunds), unified by StripeGateway as the contract entry point.

Public surface:
- StripeGateway — implements PaymentGatewayContract for Stripe

Sub-modules:
- Charges — one-time payment processing
- Webhooks — receives and verifies Stripe webhook callbacks
- Refunds — issues full or partial refunds

Guarantees:
- StripeGateway delegates to the appropriate sub-module based on the contract method
- Webhook signature verification runs before any sub-module processes payload
```

## Why this shape

This combines what the previous examples showed:

- **Top level uses the variant pattern** because PaymentGateways has multiple providers (`Framework/` + `Stripe/` + `Paypal/`).
- **Stripe variant uses sub-modules** because Stripe has three independent areas of complexity — charges, webhooks, refunds — each with its own services and (for webhooks) HTTP entry. Inlining them would bloat `Stripe/Public/Services/StripeGateway`.
- **Paypal variant stays flat** because Paypal's implementation is simpler. A flat module is enough.
- **Stripe's parent has `Public/Services/`** because `StripeGateway` orchestrates the sub-modules to fulfill `PaymentGatewayContract`. The contract requires a single entry point per variant.
- **Stripe has `Models/StripeAccount`** at the variant root because both Charges and Refunds reference it. Promoting to the parent avoids cross-sub-module model imports.

## What this demonstrates

- **Recursion of the convention.** A variant is a module; a module can have sub-modules. The same template applies at every level.
- **Asymmetric variants.** Don't force Paypal to have `Modules/` just because Stripe does. The convention is "shape earned by complexity" — Paypal's code didn't earn it.
- **The contract drives the parent shape.** `PaymentGatewayContract` requires a single entry point per variant, which is why `StripeGateway` exists at `Stripe/Public/Services/` even though it mostly delegates. The orchestration enforces the contract; that earns the parent's public service.

## Where alternative shapes would be wrong

- **Forcing both variants into the same shape** — uniformity for its own sake adds ceremony without value.
- **Stripe sub-modules as siblings of Stripe** (e.g., `app/Modules/PaymentGateways/StripeCharges/`, `StripeWebhooks/`) — that hides the variant relationship and makes "is this a Stripe thing?" hard to answer at a glance.
- **No `Modules/` for Stripe** — three independent areas (charges/webhooks/refunds) all crammed into one `Services/` directory makes the module hard to navigate.
- **`StripeAccount` placed inside one sub-module** — both Charges and Refunds need it. Putting it inside one creates a cross-sub-module dependency; promoting to the variant root is correct.
