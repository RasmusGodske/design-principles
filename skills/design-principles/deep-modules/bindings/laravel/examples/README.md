---
type: index
title: Laravel Examples
description: The Laravel-shaped versions of the deep-modules worked examples — same scenarios as the language-neutral examples, spelled in app/Modules/, Public/, PHP classes and service providers.
---

# Laravel Examples

These are the [Laravel binding](../README.md)'s worked examples. Each one is the Laravel spelling of a language-neutral example in [`../../../examples/`](../../../examples/README.md) — same scenario, same lessons, but with the concrete `app/Modules/{Domain}/` tree, `Public/` surface, PHP classes, and service providers that the binding prescribes.

Read the neutral example first for the reasoning; read the one here when you want to see the exact files a Laravel project would contain.

| File | Pattern | Neutral counterpart |
|---|---|---|
| [`flat-domain.md`](flat-domain.md) | Leaf module, no decomposition | [`flat-domain.md`](../../../examples/flat-domain.md) |
| [`domain-with-submodules.md`](domain-with-submodules.md) | Leaf module decomposed into sub-modules with parent orchestration | [`domain-with-submodules.md`](../../../examples/domain-with-submodules.md) |
| [`variant-framework.md`](variant-framework.md) | `Framework/` + multiple variants | [`variant-framework.md`](../../../examples/variant-framework.md) |
| [`full-pattern.md`](full-pattern.md) | Both variants AND sub-modules within a variant | [`full-pattern.md`](../../../examples/full-pattern.md) |
| [`contract-module.md`](contract-module.md) | Contract module — publishes a shared abstraction | [`contract-module.md`](../../../examples/contract-module.md) |

The examples are independent — they don't need to be read in order.
