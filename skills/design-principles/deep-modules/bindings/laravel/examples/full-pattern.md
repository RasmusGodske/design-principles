---
type: concept-explainer
title: "Example: A Family Whose Member Has Sub-Modules — Payment Gateways with Stripe sub-modules"
description: A worked family in Laravel spelling where one member has its own sub-modules — the convention applied recursively at full depth.
---

# Example: A Family Whose Member Has Sub-Modules — Payment Gateways with Stripe sub-modules

The family from [`family.md`](family.md), where one of the members has its own internal complexity, decomposed into sub-modules. The reasoning is in the [neutral example](../../../examples/full-pattern.md); this is the same tree in Laravel spelling.

## Shape

```
app/Modules/Payment/
├── README.md
└── Modules/
    └── PaymentGateway/                              ← the family module
        ├── README.md
        ├── Public/
        │   ├── Contracts/
        │   │   └── PaymentGatewayContract.php
        │   └── Services/
        │       └── PaymentGatewayDispatcher.php
        ├── Data/
        │   └── ChargeRequestData.php
        └── Modules/
            ├── Stripe/                              ← member — has its own sub-modules
            │   ├── README.md
            │   ├── StripeServiceProvider.php
            │   ├── Public/
            │   │   └── Services/
            │   │       └── StripePaymentGateway.php ← orchestrates Stripe's sub-modules
            │   ├── Models/
            │   │   └── StripeAccount.php            ← shared across Stripe's sub-modules
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
            │       │   ├── Http/
            │       │   │   └── Controllers/
            │       │   │       └── StripeWebhookController.php
            │       │   └── Data/
            │       └── Disputes/
            │           ├── README.md
            │           ├── Public/
            │           │   └── Services/
            │           │       └── DisputeService.php
            │           └── Data/
            └── Paypal/                              ← member — a module with no sub-modules
                ├── README.md
                ├── PaypalServiceProvider.php
                ├── Public/
                │   └── Services/
                │       └── PaypalPaymentGateway.php
                └── ...
```

## Stripe README content

```markdown
# Stripe

The Stripe member of the payment gateways. Decomposes into Charges (one-time payments), Webhooks (inbound notifications from Stripe), and Disputes (chargebacks raised by the card holder), unified by StripePaymentGateway as the contract entry point.

Public surface:
- StripePaymentGateway — implements PaymentGatewayContract for Stripe

Sub-modules:
- Charges — one-time payment processing
- Webhooks — receives and verifies Stripe webhook callbacks
- Disputes — answers and tracks chargebacks

Guarantees:
- StripePaymentGateway delegates to the appropriate sub-module based on the contract method
- Webhook signature verification runs before any sub-module processes payload
```

## Why this shape

- **The gateways are a family**, so there is a family module `PaymentGateway/` under `Payment/Modules/`, and each provider is a member module under `PaymentGateway/Modules/`.
- **The Stripe member uses sub-modules** because Stripe has three independent areas of complexity — charges, webhooks, disputes — each with its own services and (for webhooks) an HTTP layer. Inlining them would bloat `Stripe/Public/Services/StripePaymentGateway`.
- **The Paypal member has none** because Paypal's implementation is simpler.
- **Stripe's root has `Public/Services/`** because `StripePaymentGateway` orchestrates the sub-modules to fulfill `PaymentGatewayContract`. The contract requires a single entry point per member.
- **Stripe has `Models/StripeAccount`** at the member's root because both Charges and Disputes reference it.

## What this demonstrates

- **Recursion of the convention.** A member is a module; a module can have sub-modules. The same template applies at every level.
- **Depth is not a cost.** `app/Modules/Payment/Modules/PaymentGateway/Modules/Stripe/Modules/Webhooks/` is a long path and a long namespace, and each segment says something: whose it is, which family, which member, which slice.
- **"The same shape" means every member is a module with the same face**, not that every member has the same directories. Both members implement the contract from `Public/Services/` and register through their own provider. What a member holds inside is earned by that member.

## Where alternative shapes would be wrong

- **Stripe's sub-modules as siblings of Stripe** (`PaymentGateway/Modules/StripeCharges/`, `StripeWebhooks/`) — that makes them look like members of the family.
- **Stripe's sub-modules lifted into the family module** "so Paypal can use them later" — the family module holds only what every member uses today.
- **No `Modules/` for Stripe** — three independent areas crammed into one `Services/` directory makes the member hard to navigate.
- **`StripeAccount` placed inside one sub-module** — both Charges and Disputes need it; the member's root is correct.
- **Paypal as a loose class in the family module because it is small** — a family never mixes classes and modules.

> **Changed 11 November 2026.** The example was "Variants AND Sub-Modules" on the `Framework/` layout; it is now a family module whose member has sub-modules. Reason: the variant layout is retired and depth is no longer treated as a cost.
