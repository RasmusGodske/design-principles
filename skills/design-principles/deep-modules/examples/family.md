---
type: concept-explainer
title: "Example: Family — Payment Gateways"
description: A worked family — several kinds of the same thing, each a member module under a family module that holds the contract, the shared code and the family's table. The shape for vendors, providers, formats or engine versions.
---

# Example: Family — Payment Gateways

A payment module that charges through several providers. The providers are kinds of the same thing, chosen between: a **family**. The family is a module named after it, in the singular; every provider is a member module under it; and the family module holds only what is true of every member.

## Shape

```text
modules/payment/
├── README.md
├── public/services/
│   └── PaymentService                    ← the payment's own services
└── modules/
    ├── payment-gateway/                  ← the family module
    │   ├── README.md                     ← holds the family's table
    │   ├── public/contracts/
    │   │   └── PaymentGateway            ← every member implements this
    │   ├── public/services/
    │   │   └── PaymentGatewayDispatcher  ← public — works on any member, names none
    │   ├── data/
    │   │   ├── ChargeRequestData
    │   │   └── ChargeResultData
    │   ├── enums/
    │   │   └── PaymentStatus
    │   ├── exceptions/
    │   │   └── GatewayUnavailable
    │   └── modules/
    │       ├── stripe/                   ← member
    │       │   ├── README.md
    │       │   ├── wiring                ← makes this member known to the family
    │       │   ├── public/services/
    │       │   │   └── StripePaymentGateway      ← implements PaymentGateway
    │       │   ├── services/
    │       │   │   ├── StripeApiClient           ← internal
    │       │   │   └── StripeSandboxStub         ← its own stand-in for the provider
    │       │   ├── entrypoints/http/
    │       │   │   └── StripeSandboxController   ← the stub's page for local runs
    │       │   └── data/
    │       │       └── StripeWebhookData
    │       ├── paypal/                   ← member — same shape
    │       │   ├── README.md
    │       │   ├── wiring
    │       │   ├── public/services/
    │       │   │   └── PaypalPaymentGateway
    │       │   ├── services/
    │       │   │   ├── PaypalApiClient
    │       │   │   └── PaypalSandboxStub
    │       │   ├── entrypoints/http/
    │       │   │   └── PaypalSandboxController
    │       │   └── data/
    │       │       └── PaypalNotificationData
    │       └── bank-transfer/            ← member — one class, a module all the same
    │           ├── README.md
    │           ├── wiring
    │           └── public/services/
    │               └── BankTransferPaymentGateway
    └── refund/                           ← not a gateway: another slice of payment
        ├── README.md
        └── public/services/
            └── RefundService
```

## The family module's README content

```markdown
# Payment Gateway

A uniform way to charge a customer through one of several payment providers. The gateway used is chosen at run time from configuration.

Public surface:
- PaymentGatewayDispatcher — performs a charge using the configured gateway
- PaymentGateway — the contract every gateway implements

Payment gateways:
| Member                        | What it does that the others don't       |
| Stripe payment gateway        | cards, with webhooks for late results     |
| Paypal payment gateway        | wallet payments, with redirect approval   |
| Bank transfer payment gateway | no provider call: issues a payment reference |

Guarantees:
- The dispatcher knows no gateway. Adding one is adding a member module; nothing in this module changes.
```

## Why this shape

- **The family is a module under `modules/`**, not directories at `payment/`'s root. The root of `payment/` holds only reserved directories, so the tree says which directories are structure and which are children, and `refund/` sits beside the family without being mistaken for a gateway.
- **The family module is named `payment-gateway`, singular**, like any module. It holds the contract, the code that works on any member (`PaymentGatewayDispatcher`, `ChargeRequestData`) and the family's table.
- **Every member is a module of the same shape**, including `bank-transfer/` with its one class. Nobody asks whether a small member "earns" a module: the deletion test was passed by the family as a whole, because callers learn only `PaymentGateway`. The next gateway is made by copying a sibling.
- **Directories drop the family's noun, classes keep it**: `stripe/`, and `StripePaymentGateway` inside it.
- **Each member carries its own sandbox stub.** Stripe and Paypal both need a stand-in for their provider for local runs, and the two look alike. They are still two stubs, each inside its member, with its own page, controller and canned answers. One shared stub in the family module that asks each member how to answer would make the family know its members.
- **Each member makes itself known.** A member's wiring registers it with the family's dispatcher; the family module's own wiring lists no member. Deleting `paypal/` removes the Paypal gateway and leaves nothing behind.

## Where alternative shapes would be wrong

- **`framework/`, `stripe/` and `paypal/` at the root of the module** (the retired variant layout) puts free names among reserved directories and leaves no place for `refund/` or for a second family.
- **Members as loose classes in the family module** (`payment-gateway/services/StripePaymentGateway`, …) works until one member needs a client, a stub and an entry point. Then the family mixes classes and modules, and each new member needs a judgment about which it is.
- **An enumeration of gateways with a method per question** (`supportsRefunds()`, `needsRedirect()`) spreads each member over every method. A member should be one place.
- **A shared `sandbox/` in the family module** because two members have similar stubs. Sharing by resemblance puts knowledge of the members above them.
- **Promoting before the second member exists.** With one gateway there is no family module: a name, a one-row table, and the class where it is.

> **Changed 11 November 2026.** This example replaces "Variant Framework — Payment Gateways" (a `framework/` directory plus one directory per variant at the module's root). The scenario is the same; the family is now a module under `modules/` and each member a module under it. Reason: a module's root holds only reserved directories, members are always modules of one shape, and a member brings everything it needs.
