---
type: binding-rule
title: NestJS binding for Deep Modules
description: How the deep-modules roles map onto a NestJS / TypeScript application — src/modules/ as the root, index.ts as the public surface, Nest's file suffixes for roles, the module descriptor as wiring, and a conventions test as enforcement.
---

# NestJS binding for Deep Modules

The [Deep Modules](../../README.md) convention names **roles**. This binding says what each role is called in a NestJS application written in TypeScript, how wiring works, which classes are a module's faces, and how to enforce the boundary. Everything the principle says still applies; this file only adds the NestJS spelling. It was written from a codebase that verified each item, not from the framework's documentation.

## Role → NestJS

| Role (neutral name) | NestJS |
|---|---|
| Modules root | `src/modules/` — never loose under `src/` |
| Module README | `src/modules/{domain}/README.md` |
| Public surface | `src/modules/{domain}/index.ts` — the only file another module may import from; it re-exports the module descriptor, the public services, published types and decorators |
| Public services | `{name}.service.ts` classes that `index.ts` re-exports **and** the module descriptor lists under `exports` |
| Internal services | `{name}.service.ts` classes not re-exported (a calculator, a lock, a cleanup sweeper) |
| Persistence | `{name}.repository.ts` — one class owning all SQL / ORM access for the module's tables |
| Data classes | `dto.ts` (or `dto/`), one class per shape, built from the schema library the project uses |
| Entry points | `{name}.controller.ts` (HTTP), `{name}.guard.ts`, `{name}.middleware.ts`, scheduled services; a CLI entry point is a plain script at `src/` |
| Wiring | `{domain}.module.ts` — the `@Module()` descriptor: `imports`, `providers`, `controllers`, `exports` |
| Sub-modules | `src/modules/{domain}/modules/{sub}/` — same template |
| Variants | `framework/` + one directory per variant |
| Junk drawers | `common/`, `shared/`, `utils/`, `helpers/`, `misc/` forbidden anywhere under `src/` |

Directory names are lowercase to match Nest's file naming. Nest's `{name}.{role}.ts` suffix already encodes the role, so the neutral `services/`, `models/`, `entrypoints/` sub-directories are **not** added — a flat module directory with suffixed files is the Nest idiom and reads the same way.

The template in NestJS spelling:

```
src/modules/{domain}/
├── README.md                 ← what this module hides
├── index.ts                  ← the public surface (re-exports only)
├── {domain}.module.ts        ← wiring
├── {domain}.service.ts       ← primary public service
├── {name}.service.ts         ← further services, public if re-exported
├── {name}.repository.ts      ← persistence
├── {name}.controller.ts      ← HTTP entry point
├── {name}.guard.ts           ← other entry-point pieces
├── dto.ts
└── *.spec.ts                 ← tests, co-located (see the testing binding)
```

Framework glue stays at fixed paths outside the modules root: `src/main.ts` (bootstrap), `src/app.module.ts` (the root descriptor that imports every module), and any standalone scripts.

## The module's faces (naming)

Per [`naming-and-placement.md`](../../naming-and-placement.md), only a module's faces carry its name. Nest designates two:

| Face | Class | Toward whom |
|---|---|---|
| Module descriptor | `BillingModule` in `billing.module.ts` | the DI container |
| Primary public service | `BillingService` in `billing.service.ts` | other modules |

Controllers are **not** faces: a module may have none or several, and the descriptor registers a list. Nest's file idiom does name a module's primary controller after it (`billing.controller.ts` → `BillingController`); that is permitted as idiom, not required by the rule. Any further controller is named for its resource (`InvoiceController`, `RefundController`), never for the module. Everything else is named for what it is: `InvoiceCalculationService`, `InvoiceAccessGuard`, `ExpiredDraftSweeperService`, `ChargeResultDto`, `TransportError`.

Data-class layer suffixes in this binding: `*Dto` for domain values and published shapes, `Create*Dto` / `*QueryDto` for one handler's payload, `*ViewDto` for shared presentational projections.

## Wiring: the module descriptor

Unlike stacks where wiring is optional, **every Nest module has a descriptor** — the framework requires it. That is not shallow ceremony; it is the registration point. The rules that matter:

- `exports` lists exactly the providers other modules may inject — it is the DI-level twin of `index.ts`. Keep the two in step: a service re-exported from `index.ts` but missing from `exports` fails at boot with an unresolved-dependency error, which is the enforcement you want.
- `imports` names the modules this module depends on. Cross-module *type* imports may bypass the container, so the descriptor alone does not enforce the boundary — the conventions test below does.
- A module that only the root imports (an HTTP-contract module providing global pipes, filters and interceptors via `APP_PIPE`, `APP_FILTER`, `APP_INTERCEPTOR`) is a legitimate leaf with an empty `exports`.
- Mark a module `@Global()` only when nearly every module would otherwise import it (configuration, the database connection, the audit log). Global is a convenience, not a licence to skip `index.ts`.

## Things NestJS makes specific

- **Circular imports crash at boot, silently as `undefined`.** CommonJS resolves cycles by returning a half-initialised module object, so an `index.ts` barrel that is part of a cycle exports `undefined` for whatever has not loaded yet. Keep the dependency graph a DAG at the module level; the conventions test checks it. The base-layer module (the HTTP contract) must import nothing.
- **Decorated classes must be imported as values**, never `import type`, or Nest's dependency resolution sees `undefined`.
- **Constructor parameters are all injected.** A service constructor with an optional convenience parameter (`constructor(source = process.env)`) makes Nest try to resolve it. Read such things inside the class instead.
- **Raw streams** (a large upload piped straight to storage, a generated report streamed back) use `@Req()` / `@Res()` for that handler; the handler then owns the whole response and the framework's interceptors do not run on it.

## Enforcement

TypeScript has no package-level visibility inside one package, so the `index.ts` **file is the boundary**, and a conventions test guards it. The rule to encode: *any relative import whose target lies inside `src/modules/{x}/` from a file outside that module must resolve to `src/modules/{x}` itself (the index)*, plus no cycles between modules and no junk-drawer directory names.

Sketch, with the built-in test runner and no framework:

```ts
// test/conventions/module_boundaries.spec.ts
for (const file of sourceFiles) {
  for (const spec of relativeImportsOf(file)) {
    const target = path.resolve(path.dirname(file), spec);
    const [targetModule, ...rest] = path.relative(MODULES, target).split(path.sep);
    if (moduleOf(file) !== targetModule && rest.length > 0) offenders.push(`${file} -> ${spec}`);
  }
}
assert.deepEqual(offenders, []);
```

Walk every `src/modules/*` directory and assert it has `README.md` and `index.ts` in the same file. An import-linter (`eslint-plugin-boundaries`, `dependency-cruiser`) can replace the hand-written walk once the rule set grows; the test costs nothing to keep meanwhile.

## Test placement

Tests are **co-located** as `{subject}.spec.ts` beside their subject, with the cost tier declared inside the file. Rules about the codebase live in `test/conventions/`. See the [Testing principle's NestJS binding](../../../testing/bindings/nestjs/README.md).

## See also

- [`../../README.md`](../../README.md) — the principle this binds
- [`../../naming-and-placement.md`](../../naming-and-placement.md) — the faces rule
- [`../../directories.md`](../../directories.md) — role reference, including the wiring rule
- [`../../public-surface.md`](../../public-surface.md) — why the boundary is explicit and how it is enforced
