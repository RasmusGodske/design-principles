---
type: concept-explainer
title: "Example: Family — Payment Gateways"
description: A worked family in Laravel spelling — several kinds of the same thing, each a member module under a family module that holds the contract, the shared code and the family's table.
---

# Example: Family — Payment Gateways

A payment module that charges through several providers. The providers are kinds of the same thing, chosen between: a family. The family is a module named after it, in the singular; every provider is a member module under it. The reasoning is in the [neutral example](../../../examples/family.md); this is the same tree in Laravel spelling.

## Shape

```
app/Modules/Payment/
├── README.md
├── Public/
│   └── Services/
│       └── PaymentService.php                       ← the payment's own services
└── Modules/
    ├── PaymentGateway/                              ← the family module
    │   ├── README.md                                ← holds the family's table
    │   ├── Public/
    │   │   ├── Contracts/
    │   │   │   └── PaymentGatewayContract.php       ← every member implements this
    │   │   └── Services/
    │   │       └── PaymentGatewayDispatcher.php     ← public — works on any member, names none
    │   ├── Data/
    │   │   ├── ChargeRequestData.php
    │   │   └── ChargeResultData.php
    │   ├── Enums/
    │   │   └── PaymentStatus.php
    │   ├── Exceptions/
    │   │   └── GatewayUnavailable.php
    │   └── Modules/
    │       ├── Stripe/                              ← member
    │       │   ├── README.md
    │       │   ├── StripeServiceProvider.php        ← makes this member known to the family
    │       │   ├── Public/
    │       │   │   └── Services/
    │       │   │       └── StripePaymentGateway.php ← implements PaymentGatewayContract
    │       │   ├── Services/
    │       │   │   ├── StripeApiClient.php          ← internal
    │       │   │   └── StripeSandboxStub.php        ← its own stand-in for the provider
    │       │   ├── Http/
    │       │   │   └── Controllers/
    │       │   │       └── StripeSandboxController.php
    │       │   └── Data/
    │       │       └── StripeWebhookData.php
    │       ├── Paypal/                              ← member — same shape
    │       │   ├── README.md
    │       │   ├── PaypalServiceProvider.php
    │       │   ├── Public/
    │       │   │   └── Services/
    │       │   │       └── PaypalPaymentGateway.php
    │       │   ├── Services/
    │       │   │   ├── PaypalApiClient.php
    │       │   │   └── PaypalSandboxStub.php
    │       │   ├── Http/
    │       │   │   └── Controllers/
    │       │   │       └── PaypalSandboxController.php
    │       │   └── Data/
    │       │       └── PaypalNotificationData.php
    │       └── BankTransfer/                        ← member — one class, a module all the same
    │           ├── README.md
    │           ├── BankTransferServiceProvider.php
    │           └── Public/
    │               └── Services/
    │                   └── BankTransferPaymentGateway.php
    └── Refund/                                      ← not a gateway: another slice of payment
        ├── README.md
        └── Public/
            └── Services/
                └── RefundService.php
```

## The family module's README content

```markdown
# Payment Gateway

A uniform way to charge a customer through one of several payment providers. The gateway used is chosen at run time from configuration.

Public surface:
- PaymentGatewayDispatcher — performs a charge using the configured gateway
- PaymentGatewayContract — the contract every gateway implements

Payment gateways:
| Member                        | What it does that the others don't       |
| Stripe payment gateway        | cards, with webhooks for late results     |
| Paypal payment gateway        | wallet payments, with redirect approval   |
| Bank transfer payment gateway | no provider call: issues a payment reference |

Guarantees:
- The dispatcher knows no gateway. Adding one is adding a member module; nothing in this module changes.
```

## Why this shape

- **The family is a module under `Modules/`**, not directories at `Payment/`'s root. The root of `Payment/` holds only reserved directories, and `Refund/` sits beside the family without being mistaken for a gateway.
- **The family module is named `PaymentGateway`, singular.** It holds the contract, the code that works on any member and the family's table.
- **Every member is a module of the same shape**, including `BankTransfer/` with its one class. The deletion test was passed by the family as a whole: callers type-hint `PaymentGatewayContract` and learn nothing else.
- **Directories drop the family's noun, classes keep it**: `Stripe/`, and `StripePaymentGateway` inside it.
- **Each member carries its own sandbox stub**, with its own controller, routes and canned answers, even though Stripe's and Paypal's look alike. A shared stub in the family module would have to know its members.
- **Each member's service provider makes it known** to the dispatcher (for instance by tagging its gateway class). The family module has no provider that lists members. Deleting `Paypal/` and its line in `bootstrap/providers.php` removes the Paypal gateway and leaves nothing behind.

## Where alternative shapes would be wrong

- **`Framework/`, `Stripe/` and `Paypal/` at the root of the module** (the retired variant layout) puts free names among reserved directories and leaves no place for `Refund/` or for a second family.
- **Members as loose classes in the family module** works until one member needs a client, a stub and a controller. Then the family mixes classes and modules.
- **An enum of gateways with a method per question** (`supportsRefunds()`, `needsRedirect()`) spreads each member over every method.
- **A shared `Sandbox/` in the family module** because two members have similar stubs.
- **Promoting before the second member exists.** With one gateway there is no family module.

> **Changed 11 November 2026.** This example replaces "Variant Framework — PaymentGateways" (`Framework/` plus one directory per variant at the module's root). The family is now a module under `Modules/` and each member a module under it; the binding of the active variant in a framework provider is replaced by each member's own provider. Reason: a module's root holds only reserved directories, members are always modules of one shape, and nothing above a member knows it exists.
