---
type: concept-explainer
title: "Example: Variant Framework — PaymentGateways"
description: A worked module with multiple variants of the same thing sharing a Framework/ — the shape for vendors, providers, or engine versions.
---

# Example: Variant Framework — PaymentGateways

A domain with multiple kinds of the same thing. Each gateway provider has a significantly different implementation but a shared interface. Shared infrastructure lives in `Framework/`; each provider is its own variant directory.

## Shape

```
app/Modules/PaymentGateways/
├── README.md
├── Framework/
│   ├── README.md
│   ├── PaymentGatewaysFrameworkServiceProvider.php  ← binds the active variant
│   ├── Public/Contracts/
│   │   └── PaymentGatewayContract.php       ← every variant implements this
│   ├── Public/
│   │   └── Services/
│   │       └── PaymentGatewayDispatcher.php ← public — works on any variant
│   ├── Data/
│   │   ├── ChargeRequestData.php
│   │   └── ChargeResultData.php
│   ├── Enums/
│   │   └── PaymentStatus.php
│   └── Exceptions/
│       └── GatewayUnavailable.php
├── Stripe/
│   ├── README.md
│   ├── Public/
│   │   └── Services/
│   │       └── StripeGateway.php            ← implements PaymentGatewayContract
│   ├── Services/
│   │   └── StripeApiClient.php              ← internal — used only by StripeGateway
│   └── Data/
│       └── StripeWebhookData.php
└── Paypal/
    ├── README.md
    ├── Public/
    │   └── Services/
    │       └── PaypalGateway.php
    ├── Services/
    │   └── PaypalApiClient.php
    └── Data/
        └── PaypalIpnData.php
```

## Top-level README content

```markdown
# PaymentGateways

Provides a uniform interface for charging customers across multiple payment providers. The active gateway is selected at runtime via configuration.

Public surface:
- PaymentGatewayDispatcher (in Framework/Public/Services) — performs a charge using the active gateway
- PaymentGatewayContract (in Framework/Public/Contracts) — the interface every gateway implements

Variants:
- Stripe — Stripe-specific implementation
- Paypal — PayPal-specific implementation

Guarantees:
- The dispatcher is gateway-agnostic — adding a new gateway requires implementing the contract; the dispatcher does not change
```

## Why this shape

- **`Framework/` exists** because the variant axis (gateway provider) is clearly nameable, and the variants need to evolve independently. New gateways can be added without touching existing ones.
- **`Framework/Public/Contracts/`** holds the published interface every variant must satisfy. Outside callers can type-hint the contract; container binding picks the active variant at runtime.
- **`Framework/Public/Services/PaymentGatewayDispatcher`** is the gateway-agnostic entry point. Outsiders call this; they don't pick a variant directly unless they need provider-specific behavior.
- **Each variant has its own `Public/Services/`.** The variant *is* a module — outsiders may import it directly when they need gateway-specific behavior (e.g., a Stripe-specific webhook handler).
- **`Framework/Data/` holds shared values** (`ChargeRequestData`, `ChargeResultData`) that travel through the dispatcher. Variant-specific data (`StripeWebhookData`) stays inside the variant.
- **The framework's service provider** binds the active variant to the contract — this is exactly the case where a service provider is earned.

## Where alternative shapes would be wrong

- **Flat module with no `Framework/`** would force every variant to live inside the same module, sharing `Services/` and `Models/`. Adding a new variant becomes a coordination problem.
- **Variants without `Framework/Public/Contracts/`** would let outsiders depend on Stripe-specific signatures rather than the gateway-agnostic interface. The whole point of the variant pattern is the contract.
- **Single shared `Public/Services/` at the top level** would couple all variants into one mega-class, defeating the variant separation.
- **Promoting variants prematurely** (e.g., before the second one exists) — wait until you have ≥2 implementations. A `Framework/` with one variant is harder to read than a flat module.
