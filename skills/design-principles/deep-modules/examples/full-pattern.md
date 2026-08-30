---
type: concept-explainer
title: "Example: Variants AND Sub-Modules — Payment Gateways with Stripe sub-modules"
description: A worked variant module where one variant has its own sub-modules — the convention applied recursively at full depth.
---

# Example: Variants AND Sub-Modules — Payment Gateways with Stripe sub-modules

A variant module where one of the variants has its own internal complexity, decomposed into sub-modules. This shows the convention applied recursively.

## Shape

```text
modules/payment-gateways/
├── README.md
├── framework/                            ← shared across variants
│   ├── README.md
│   ├── public/contracts/
│   │   └── PaymentGateway
│   ├── public/services/
│   │   └── PaymentGatewayDispatcher
│   └── data/
│       └── ChargeRequestData
├── stripe/                               ← variant — has its own sub-modules
│   ├── README.md
│   ├── wiring
│   ├── public/services/
│   │   └── StripeGateway                 ← orchestrates Stripe sub-modules
│   ├── models/
│   │   └── StripeAccount                 ← shared across Stripe sub-modules
│   └── modules/
│       ├── charges/
│       │   ├── README.md
│       │   ├── public/services/
│       │   │   └── ChargeService
│       │   ├── services/
│       │   │   └── StripeChargeApiClient
│       │   └── data/
│       ├── webhooks/
│       │   ├── README.md
│       │   ├── public/services/
│       │   │   └── WebhookProcessor
│       │   ├── services/
│       │   │   └── SignatureVerifier
│       │   ├── entrypoints/http/
│       │   │   └── StripeWebhookController
│       │   └── data/
│       └── refunds/
│           ├── README.md
│           ├── public/services/
│           │   └── RefundService
│           └── data/
└── paypal/                               ← variant — flat, simpler
    ├── README.md
    ├── public/services/
    │   └── PaypalGateway
    └── ...
```

## Stripe README content

```markdown
# Stripe

Stripe-specific implementation of the PaymentGateway contract. Decomposes into Charges (one-time payments), Webhooks (inbound notifications from Stripe), and Refunds (cancellations and partial refunds), unified by StripeGateway as the contract entry point.

Public surface:
- StripeGateway — implements PaymentGateway for Stripe

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

- **Top level uses the variant pattern** because Payment Gateways has multiple providers (`framework/` + `stripe/` + `paypal/`).
- **Stripe variant uses sub-modules** because Stripe has three independent areas of complexity — charges, webhooks, refunds — each with its own services and (for webhooks) an HTTP entry point. Inlining them would bloat `stripe/public/services/StripeGateway`.
- **Paypal variant stays flat** because Paypal's implementation is simpler. A flat module is enough.
- **Stripe's parent has `public/services/`** because `StripeGateway` orchestrates the sub-modules to fulfill the `PaymentGateway` contract. The contract requires a single entry point per variant.
- **Stripe has `models/StripeAccount`** at the variant root because both Charges and Refunds reference it. Promoting to the parent avoids cross-sub-module model imports.

## What this demonstrates

- **Recursion of the convention.** A variant is a module; a module can have sub-modules. The same template applies at every level.
- **Asymmetric variants.** Don't force Paypal to have `modules/` just because Stripe does. The convention is "shape earned by complexity" — Paypal's code didn't earn it.
- **The contract drives the parent shape.** `PaymentGateway` requires a single entry point per variant, which is why `StripeGateway` exists at `stripe/public/services/` even though it mostly delegates. The orchestration enforces the contract; that earns the parent's public service.

## Where alternative shapes would be wrong

- **Forcing both variants into the same shape** — uniformity for its own sake adds ceremony without value.
- **Stripe sub-modules as siblings of Stripe** (e.g., `modules/payment-gateways/stripe-charges/`, `stripe-webhooks/`) — that hides the variant relationship and makes "is this a Stripe thing?" hard to answer at a glance.
- **No `modules/` for Stripe** — three independent areas (charges/webhooks/refunds) all crammed into one `services/` directory makes the module hard to navigate.
- **`StripeAccount` placed inside one sub-module** — both Charges and Refunds need it. Putting it inside one creates a cross-sub-module dependency; promoting to the variant root is correct.
