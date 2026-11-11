---
type: index
title: Examples
description: Worked examples of the module convention applied to realistic modules — which one to read for the shape you are building.
---

# Examples

Worked examples of the convention applied to realistic modules. Each example shows the file tree, the parent module's README, why the shape was chosen, and where alternative shapes would be wrong.

The trees use a neutral spelling — lowercase directories named by *role* (`public/services/`, `services/`, `models/`, `entrypoints/`), no file extensions, pseudocode for snippets. Your stack spells these roles its own way; see [`bindings/`](../bindings/) for the mapping (e.g. the [Laravel examples](../bindings/laravel/examples/README.md) are these same scenarios in that stack's spelling).

| File | Pattern | When to read |
|---|---|---|
| [`flat-domain.md`](flat-domain.md) | Leaf module, no decomposition | Building a small/medium domain (~80% of cases) |
| [`domain-with-submodules.md`](domain-with-submodules.md) | Leaf module decomposed into sub-modules with parent orchestration | A domain has grown internal complexity that needs hiding |
| [`family.md`](family.md) | A family module with its member modules | Multiple kinds of the same thing (vendors, providers, formats, engine versions) |
| [`full-pattern.md`](full-pattern.md) | A family whose member has sub-modules of its own | A family where one member is itself complex enough to decompose |
| [`contract-module.md`](contract-module.md) | Contract module — publishes a shared abstraction | Multiple independent modules need the same contract; no single owner |

Read the example closest to the shape you're building. The examples are independent — they don't need to be read in order.

> **Changed 11 November 2026.** The "variant framework" example is now the family example, `family.md`, and the full pattern follows it. Reason: the variant layout (`framework/` plus variant directories at a module's root) is retired; a family is a module under `modules/` and its members are modules under it.
