---
type: how-to-guide
title: Working with Legacy Code
description: How to apply the module convention in a codebase that pre-dates it — what new code must follow and what existing code is grandfathered.
---

# Working with Legacy Code

How to apply this convention in a codebase that pre-dates it. The principle is gradual: new code follows the convention; existing code is grandfathered until there's a specific reason to migrate.

A half-converted codebase is workable. A half-converted codebase that keeps creeping is not. The point of these rules is to draw a clean line between what's expected of new code and what gets left alone.

**The modules root makes the line physical.** New convention modules live under the modules root (`modules/` in the neutral spelling — your [binding](bindings/) names the real path); the legacy, type-organized layout (`services/`, `models/`, `controllers/`, `jobs/`, …) stays where it was. You don't have to remember which directories are "modernized" — the path tells you. Legacy code never moves under the modules root except as a deliberate, scoped migration.

## The four rules

### 1. New domains follow the convention

A new top-level domain (`modules/NewFeature/`) goes in convention shape from line one, under the modules root. No discussion. The convention is the default for greenfield code.

### 2. Existing domains are grandfathered

Don't migrate as part of an unrelated feature task. Refactoring structure is its own work; it should not get smuggled into "add a new field" or "fix this bug" tickets. If migration is the goal, scope it as migration. Otherwise, leave the structure as you found it.

### 3. Match local conventions when adding to legacy areas

A new class added to a legacy `services/billing/` matches what's around it. Introducing a single `public/` directory to host one new file in a legacy area creates inconsistency that is *worse* than uniform legacy. Internal consistency at the local level beats partial conformance to the global convention.

### 4. Cheap wins are always fair game

These are zero-cost decisions and don't disrupt existing structure:

- **Naming.** Drop redundant module prefixes. A new class called `IssueCode` (in whatever directory the legacy area uses) is better than `BillingIssueCode`. The prefix is removable; the structural placement isn't.
- **Most-cohesive home.** When adding new related code, put it in the location that makes the most sense for the behaviour, not the path of least resistance.
- **Avoid junk drawers.** Even in legacy code, don't create a new `helpers/` or `util/` directory. Find an existing module that owns the behaviour. If genuinely none does, that is a sign of a missing module — surface it.

## What to decide alone vs. what to surface

Some calls are too big to make alone. Surface these in a design conversation or with a reviewer before acting:

- Any change that crosses files — extracting a module, introducing a `public/` directory in a legacy area, moving classes between top-level locations.
- Any change that touches more than the immediate task. *"I noticed five files that belong together"* is great information; *"I refactored them while you weren't looking"* is scope creep.
- Anything where you'd otherwise default to a junk-drawer placement — that's a sign the structure needs a real conversation.

The default for structural changes is **surface, then act on agreement**. A migration done without discussion is hard to review and easy to regret.

What you can decide alone:

- Naming a new class without a redundant module prefix.
- Choosing the most-cohesive existing home for new related code.
- Picking between two equally valid local placements when the legacy area is internally inconsistent.

## When the convention conflicts with the legacy area

There will be moments when adding code to a legacy area means the convention's prescription contradicts the local pattern. The default is **match the local pattern** (rule 3). Surface it for discussion if any of the following apply:

- The legacy pattern is actively unhelpful (e.g., scattering five related classes across `services/`, `models/`, `jobs/`).
- You're touching enough of the area that bounding the refactor scope is feasible.
- The cost difference between "match legacy" and "extract to convention" is small.

The framing for that conversation is the **dual-path option**:

> Working on this task, two paths:
>
> - **Quick path:** Match the existing scattered structure (~5 min).
> - **Convention path:** Extract these N files (plus the new one) into a new `modules/{Domain}/` module (~30 min, requires moving tests).

The dual path with effort estimates lets the call be made on context — tight deadline says quick; calmer week says convention.

## Triggers for "this might be worth extracting"

Specific signals that suggest a section is ripe for migration. These are signals to **surface**, not mandates to act:

- **Three or more files form a coherent group** but live across `services/`, `models/`, `jobs/`, etc.
- **A junk-drawer directory exists** (`helpers/`, `util/`, `common/`) and you can identify a module that should own its contents.
- **A class name encodes a module** (`BillingIssueCode`) but lives in a generic location (a root `enums/`) — placement gravity that wants to become a real module.
- **You find yourself wanting to call a "private" method from outside its current class** because the class is doing too much — usually a sign that the boundary needs to move.

## Patterns for actual migration

When a migration *is* the work (or part of it), these patterns bound the cost.

### Strangler fig — extract new behaviour, leave old in place

Sometimes the next major change in a legacy area is the moment to extract a deep module *for the new behaviour only*. The new code is in convention shape; the old code stays as-is. New callers go through the new module; old callers continue to work.

> Example: a new "subscription billing" feature is being added to a project where billing currently lives in a legacy `services/billing/`. Instead of restructuring the existing code, create `modules/Subscriptions/` in convention shape. Subscriptions calls into the legacy billing service via its existing public API; the legacy code does not change. Over time, if billing also gets restructured, both modules can talk through their public surfaces.

### Bounded refactor — when you're already touching all the files

If a feature task naturally touches every file in a legacy section, the marginal cost of extracting them into a module is low. This is the moment when a refactor pays its way without expanding scope. Surface and confirm before doing it.

### Greenfield extraction — pull a self-contained piece into a new module

When a piece of legacy code has minimal dependencies on the rest of the codebase, lifting it into a convention-shaped module is cheap. Identify by walking imports inward — if the candidate has 0–2 inbound dependencies and few outbound, it's a candidate.

## The trickiest cases

### Bug fixes in legacy code

Don't surface migration opportunities during a bug fix. Bug fixes have a tightly bounded scope; migration discussions are noise. Save them for feature work or explicit cleanup sessions.

### The half-converted module

When `modules/Billing/` (new convention) and a legacy `services/billing/` both exist, **new billing code goes to the new module** by default. The modules-root prefix makes the two homes unambiguous at a glance. Yes, this creates a window where two "billing" homes coexist — that friction is the cost of gradual migration. The alternative (letting new code go where the gravity is) makes migrations stretch indefinitely.

### Flat-vs-nested when extracting

When extracting from legacy, the new module starts **flat**. Promote to sub-modules later when complexity earns it. Starting with sub-modules from a legacy extraction is over-engineering — you don't yet know which pieces will grow.

## Anti-patterns

- **Silent refactors.** Restructuring without surfacing first. Even small structural changes deserve a one-line "I'm planning to…" before they happen.
- **Partial conversion.** Introducing `public/` for one new file in an otherwise legacy area. Either match the legacy or extract a real module — don't half-convert.
- **Scope creep during feature work.** *"While I was here, I also restructured X"* is a recipe for unreviewable diffs and scope arguments.
- **Treating the convention as universal.** The convention applies to new code and to deliberate migrations. It does not apply retroactively to every line of legacy code, and forcing it to creates more friction than it removes.

## See also

- [`promotion-criteria.md`](promotion-criteria.md) — the underlying "earned, not speculative" principle that governs whether something deserves to be a module
- [`directories.md`](directories.md) — the target shape that legacy code is migrating toward
