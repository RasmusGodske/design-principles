---
type: binding-rule
title: Testing — NestJS / node:test binding
description: How the Testing principle's roles — the mirror, test kinds, cost tiers and the tagging mechanism — are spelled in a NestJS / TypeScript codebase tested with Node's built-in test runner.
---

# Testing — NestJS / node:test binding

This file maps the stack-neutral roles in [`../../README.md`](../../README.md) onto a NestJS codebase using Node's built-in `node --test` runner. It adds no rules; it only says what each role is called here. Written from a codebase that verified each item.

## The mirror: co-location

TypeScript projects ship compiled output, not source, so tests can sit beside their subjects and be excluded from the build. This binding uses **co-location**, the shape the principle prefers because it cannot drift:

| Role | NestJS |
|---|---|
| Test file | `{subject}.spec.ts` beside `{subject}.ts` |
| Exclusion from the artifact | `"exclude": ["**/*.spec.ts", "test"]` in the build `tsconfig` |
| Split by behaviour | `billing.spec.ts`, `billing.refunds.spec.ts` — subject stays the prefix |
| Scaffolding | `test/support/` (fixtures, fakes, the client for a running stack); shared by every area, owned by the package |
| Runner | `node --test --import tsx 'src/**/*.spec.ts' 'test/**/*.spec.ts'` |

Worked derivations:

```text
src/modules/billing/rounding.ts      →  src/modules/billing/rounding.spec.ts
src/modules/billing/billing.service.ts (the subject is the module's promise)
                                     →  src/modules/billing/billing.spec.ts
packages/cli/src/client.ts           →  packages/cli/src/client.spec.ts
```

The subject of a module's behavioural test is the module's public promise, so its file is named for the module (`billing.spec.ts`), not for the service class.

## Kinds (first path segment)

```text
src/**/*.spec.ts       mirrored — executes your code, co-located
test/conventions/      reads the source tree, never boots the application
test/support/          scaffolding (not tests)
```

Convention tests are one file per rule, named for the assertion, e.g. `test/conventions/module_boundaries.spec.ts`.

## Cost tiers — the tagging mechanism

`node:test` has no group attribute, so a tier is declared **inside the test file** as a guard that skips the whole suite when its cost is not paid for. Untagged means the cheapest (isolated) tier and needs nothing.

```ts
// src/modules/billing/billing.spec.ts
import { stackTier, skipReason } from "../../../test/support/stack";
const stack = stackTier();               // null unless TEST_STACK_URL and TEST_STACK_TOKEN are set

describe("billing", { skip: stack ? false : skipReason }, () => { /* against a running application */ });
```

| Tier | Declares | Runs when |
|---|---|---|
| isolated | nothing | always (`npm test`) |
| stack | `stackTier()` guard | `npm run test:stack`, which exports the two variables and runs the same command |

The safe default holds: a file that declares nothing gets no stack, and a test that reaches for one without declaring it fails at the moment it tries, because the URL is simply absent.

## What each layer's test looks like

| Layer | Test |
|---|---|
| Module promise (behavioural) | `{module}.spec.ts`, stack tier: drive the running application over HTTP, assert outcomes |
| Pure, combinatorial logic (rounding rules, renderers, argument parsing) | `{subject}.spec.ts`, isolated: hand-built input, asserted output |
| Client error mapping | isolated, with `globalThis.fetch` replaced by a stub for the duration of the test |
| Rules about the codebase | `test/conventions/*.spec.ts`, isolated, file-system only |

## If the project uses Jest

Nest's CLI scaffolds Jest, and most Nest codebases keep it. The roles are spelled the same; only the tagging mechanism changes:

| Role | Jest |
|---|---|
| Runner | one `jest` config with `testRegex: '.*\\.spec\\.ts$'` and `roots: ['<rootDir>/src', '<rootDir>/test']`, so the mirrored tree and `test/conventions/` are collected by the same command |
| Tier guard | the same `stackTier()` helper; skip the suite when the tier is unpaid: `(stack ? describe : describe.skip)("billing", () => { ... })` |
| Tier by command | `npm test` runs everything unguarded; `npm run test:stack` exports the two variables and runs the same command |

Do not spell tiers as separate configs or path patterns — the scaffold's `test/jest-e2e.json` with its own `test/**/*.e2e-spec.ts` tree is exactly that. It puts cost back in the path, which the principle forbids. One config, one tree, the guard inside the file.

## See also

- [`../../README.md`](../../README.md) — the principle
- [`../../../deep-modules/bindings/nestjs/README.md`](../../../deep-modules/bindings/nestjs/README.md) — the module layout these tests sit in
