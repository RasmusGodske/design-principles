---
type: index
title: Framework and Implementation — Worked Examples
description: Which worked example of the framework-and-implementation principle to read for which situation — the vendor-plural steady state, the versioned-engine founding limit-case, and the growth-by-promotion story with its two classic leaks.
---

# Framework and Implementation — Worked Examples

Invented, self-contained walkthroughs of [the principle](../README.md) — one per way of using it. None reference any real codebase; each makes the disciplines concrete, includes the tempting-but-wrong design, and ends with a litmus-test audit.

| Example | The way of using the principle | Read it when |
|---|---|---|
| [The Notification Framework](./notification-framework.md) | **Vendor-plural steady state** — implementations differ in *space* (one per external channel). Contracts naming outcomes, lockers in daily use, and a framework temptation converted into an honest contract method. | Designing a framework whose implementations wrap different external systems; deciding what goes in a locker vs a contract. |
| [The Versioned Pricing Engine](./versioned-pricing-engine.md) | **Version-plural founding limit-case** — implementations differ in *time*. The [versioned-engine](../versioned-engine.md) pattern end to end: founding only the seam, a wholesale rethink shipping beside the original, records pinned forever. | Founding a core capability whose future shape is unknowable while authored records must keep working. |
| [The Report Exporter](./report-exporter-promotion.md) | **Growth by promotion** — how a framework legitimately gains features. The two classic leaks (vendor column, framework branch on implementation type), their corrections, and retry logic that waits until a second consumer reveals the real invariant. | Reviewing a diff that adds to a shared layer; feeling the pull of "this is obviously reusable". |

Reading all three: the notification framework is the principle's steady state, the pricing engine is founding under maximal uncertainty, and the report exporter is the growth rule in motion. The litmus audits at the end of each are the same six tests from [the main doc](../README.md#litmus-tests) — the examples are the tests wearing concrete clothes.
