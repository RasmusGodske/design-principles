---
type: concept-explainer
title: "Example: A Family Whose Member Has Sub-Modules — Payment Gateways with Stripe sub-modules"
description: A worked family where one member has its own sub-modules — the convention applied recursively at full depth, and what "all members have the same shape" does and does not ask for.
---

# Example: A Family Whose Member Has Sub-Modules — Payment Gateways with Stripe sub-modules

The family from [`family.md`](family.md), where one of the members has its own internal complexity, decomposed into sub-modules. This shows the convention applied recursively.

## Shape

```text
modules/payment/
├── README.md
└── modules/
    └── payment-gateway/                      ← the family module
        ├── README.md
        ├── public/contracts/
        │   └── PaymentGateway
        ├── public/services/
        │   └── PaymentGatewayDispatcher
        ├── data/
        │   └── ChargeRequestData
        └── modules/
            ├── stripe/                       ← member — has its own sub-modules
            │   ├── README.md
            │   ├── wiring
            │   ├── public/services/
            │   │   └── StripePaymentGateway  ← orchestrates Stripe's sub-modules
            │   ├── models/
            │   │   └── StripeAccount         ← shared across Stripe's sub-modules
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
            │       └── disputes/
            │           ├── README.md
            │           ├── public/services/
            │           │   └── DisputeService
            │           └── data/
            └── paypal/                       ← member — a module with no sub-modules
                ├── README.md
                ├── wiring
                ├── public/services/
                │   └── PaypalPaymentGateway
                └── ...
```

## Stripe README content

```markdown
# Stripe

The Stripe member of the payment gateways. Decomposes into Charges (one-time payments), Webhooks (inbound notifications from Stripe), and Disputes (chargebacks raised by the card holder), unified by StripePaymentGateway as the contract entry point.

Public surface:
- StripePaymentGateway — implements PaymentGateway for Stripe

Sub-modules:
- Charges — one-time payment processing
- Webhooks — receives and verifies Stripe webhook callbacks
- Disputes — answers and tracks chargebacks

Guarantees:
- StripePaymentGateway delegates to the appropriate sub-module based on the contract method
- Webhook signature verification runs before any sub-module processes payload
```

## Why this shape

This combines what the previous examples showed:

- **The gateways are a family**, so there is a family module `payment-gateway/` under `payment/modules/`, and each provider is a member module under `payment-gateway/modules/`.
- **The Stripe member uses sub-modules** because Stripe has three independent areas of complexity — charges, webhooks, disputes — each with its own services and (for webhooks) an HTTP entry point. Inlining them would bloat `stripe/public/services/StripePaymentGateway`.
- **The Paypal member has none** because Paypal's implementation is simpler.
- **Stripe's root has `public/services/`** because `StripePaymentGateway` orchestrates the sub-modules to fulfill the `PaymentGateway` contract. The contract requires a single entry point per member.
- **Stripe has `models/StripeAccount`** at the member's root because both Charges and Disputes reference it. Placing it at the member's root avoids cross-sub-module model imports.

## What this demonstrates

- **Recursion of the convention.** A member is a module; a module can have sub-modules. The same template applies at every level.
- **Depth is not a cost.** `payment/modules/payment-gateway/modules/stripe/modules/webhooks/` is a long path, and each segment says something: whose it is, which family, which member, which slice. Nothing was flattened to save a level. Each level passes the deletion test on what it owns.
- **"The same shape" means every member is a module with the same face**, not that every member has the same directories. Stripe and Paypal are both modules, both implement `PaymentGateway` from `public/services/`, both make themselves known through their own wiring. What a member holds *inside* is earned by that member: Paypal gets no `modules/` because Stripe has one.
- **The contract drives the member's surface.** `PaymentGateway` requires a single entry point per member, which is why `StripePaymentGateway` exists at `stripe/public/services/` even though it mostly delegates.

## Where alternative shapes would be wrong

- **Stripe's sub-modules as siblings of Stripe** (e.g., `payment-gateway/modules/stripe-charges/`, `stripe-webhooks/`) — that makes them look like members of the family, and makes "is this a Stripe thing?" hard to answer at a glance.
- **Stripe's sub-modules lifted into the family module** "so Paypal can use them later" — the family module holds only what every member uses today.
- **No `modules/` for Stripe** — three independent areas all crammed into one `services/` directory makes the member hard to navigate.
- **`StripeAccount` placed inside one sub-module** — both Charges and Disputes need it. Putting it inside one creates a cross-sub-module dependency; the member's root is correct.
- **Paypal as a loose class in the family module because it is small** — a family never mixes classes and modules.

> **Changed 11 November 2026.** The example was "Variants AND Sub-Modules" on the `framework/` layout; it is now a family module whose member has sub-modules. The lesson on asymmetry is restated: members are always modules of one shape toward the family, and only their insides differ. Reason: the variant layout is retired and depth is no longer treated as a cost.
