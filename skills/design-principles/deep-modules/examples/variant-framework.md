---
type: concept-explainer
title: "Example: Variant Framework — Payment Gateways"
description: A worked module with multiple variants of the same thing sharing a framework/ — the shape for vendors, providers, or engine versions.
---

# Example: Variant Framework — Payment Gateways

A domain with multiple kinds of the same thing. Each gateway provider has a significantly different implementation but a shared interface. Shared infrastructure lives in `framework/`; each provider is its own variant directory.

## Shape

```text
modules/payment-gateways/
├── README.md
├── framework/
│   ├── README.md
│   ├── wiring                            ← binds the active variant to the contract
│   ├── public/contracts/
│   │   └── PaymentGateway                ← every variant implements this
│   ├── public/services/
│   │   └── PaymentGatewayDispatcher      ← public — works on any variant
│   ├── data/
│   │   ├── ChargeRequestData
│   │   └── ChargeResultData
│   ├── enums/
│   │   └── PaymentStatus
│   └── exceptions/
│       └── GatewayUnavailable
├── stripe/
│   ├── README.md
│   ├── public/services/
│   │   └── StripeGateway                 ← implements PaymentGateway
│   ├── services/
│   │   └── StripeApiClient               ← internal — used only by StripeGateway
│   └── data/
│       └── StripeWebhookData
└── paypal/
    ├── README.md
    ├── public/services/
    │   └── PaypalGateway
    ├── services/
    │   └── PaypalApiClient
    └── data/
        └── PaypalIpnData
```

## Top-level README content

```markdown
# Payment Gateways

Provides a uniform interface for charging customers across multiple payment providers. The active gateway is selected at runtime via configuration.

Public surface:
- PaymentGatewayDispatcher (in framework/public/services) — performs a charge using the active gateway
- PaymentGateway (in framework/public/contracts) — the interface every gateway implements

Variants:
- Stripe — Stripe-specific implementation
- Paypal — PayPal-specific implementation

Guarantees:
- The dispatcher is gateway-agnostic — adding a new gateway requires implementing the contract; the dispatcher does not change
```

## Why this shape

- **`framework/` exists** because the variant axis (gateway provider) is clearly nameable, and the variants need to evolve independently. New gateways can be added without touching existing ones.
- **`framework/public/contracts/`** holds the published interface every variant must satisfy. Outside callers depend on the contract; the wiring picks the active variant at runtime.
- **`framework/public/services/PaymentGatewayDispatcher`** is the gateway-agnostic entry point. Outsiders call this; they don't pick a variant directly unless they need provider-specific behavior.
- **Each variant has its own `public/services/`.** The variant *is* a module — outsiders may import it directly when they need gateway-specific behavior (e.g., a Stripe-specific webhook handler).
- **`framework/data/` holds shared values** (`ChargeRequestData`, `ChargeResultData`) that travel through the dispatcher. Variant-specific data (`StripeWebhookData`) stays inside the variant.
- **The framework's wiring file** binds the active variant to the contract — this is exactly the case where wiring is earned.

## Where alternative shapes would be wrong

- **Flat module with no `framework/`** would force every variant to live inside the same module, sharing `services/` and `models/`. Adding a new variant becomes a coordination problem.
- **Variants without `framework/public/contracts/`** would let outsiders depend on Stripe-specific signatures rather than the gateway-agnostic interface. The whole point of the variant pattern is the contract.
- **Single shared `public/services/` at the top level** would couple all variants into one mega-class, defeating the variant separation.
- **Promoting variants prematurely** (e.g., before the second one exists) — wait until you have ≥2 implementations. A `framework/` with one variant is harder to read than a flat module.
