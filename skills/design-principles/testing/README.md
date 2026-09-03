---
type: concept-explainer
title: Testing
description: Why a test's location should be derived from what it covers while its cost is declared inside it — so one subject keeps one test file and a fast slice is always available.
---

# Testing

> **A test's location is derived from what it covers. A test's cost is declared inside it. Keep those apart and one subject keeps one test file — findable by looking, and cheap to run a slice of.**

Start with a story. You change one line in a pricing helper. You'd like to know whether you broke
anything, but the suite takes ten minutes — so you don't run it. Forty minutes later you finally do,
three things are red, and you've made six changes since the last green run. Now you're bisecting your
own afternoon.

Later someone asks a simpler question: *is the refund endpoint tested?* Nobody can answer. Not because
it's complicated, but because there is nowhere to look. You grep, find two files mentioning refunds,
and still don't know.

Both look like testing problems. Both are **structure** problems: there was no way to ask for a cheap
slice, and test files aren't where their subjects are. Both are normally papered over by someone who
has been there long enough to know which tests matter — which holds until the person touching the
code is new, or is a coding agent with no memory of why a given test matters.

## The rule underneath all of this

Every decision below is one question: **path, or declaration?**

> **Put a distinction in the path when the cost of misplacing it is the run itself. Put it in a
> declaration when the worst case is a test that is slower than it claimed.**

Get a tier wrong and one test is slower than advertised — recoverable. Get the runner wrong and a
browser test lands in the in-process suite and takes the whole run down. That asymmetry decides
everything that follows.

## What a "subject" is

Notice what you were asked about: the **refund endpoint** — not the pricing helper it happens to use.

A **subject** is something your code promises to outsiders. To keep that from being a matter of
opinion, pin it to something a script can see: bound to a route or a command, listed in a module's
public surface, whatever your language uses to mark "callable from outside". Everything else —
helpers, values, internal steps — is reached *through* a subject, is covered by that subject's tests,
and normally gets no test file of its own. The exception is genuinely combinatorial logic — a state
machine, a parser, a table of rules — where enumerating cases directly gives signal an end-to-end
test can't; file it under its owning subject's prefix so it stays adjacent.

This answers **"is every promise tested?"** Not "does every file have a test?", which produces
busywork and mock-heavy tests of things nobody calls directly.

## The four rules

### 1. A test's path is derived from its subject's path

Two shapes do this. **Co-location** (`refunder` beside `refunder.test`) cannot drift, because
there is no second tree to fall out of step; prefer it where your language supports it. A **parallel
tree** is needed when tests must be excluded from the shipped artifact. The rest of this rule assumes
the parallel tree, which is the harder case.

```text
src/billing/refunder   →   tests/src/billing/refunder_test
```

(Paths here are written without extensions and in one casing; the exact suffix, extension and casing
follow your stack — see `bindings/`.)

The payoff: **coverage becomes visible.** Put the two directories side by side and the gaps are
missing files.

```text
src/billing/            tests/src/billing/
├── refunder            │                      ← a promise with no test. Now you know.
├── invoicer            ├── invoicer_test
└── rounding_helper                            ← reached only through the two above; no file expected
```

"Is this tested?" becomes a directory listing. And because subjecthood is pinned to something visible
(routes, exports, a public surface), a rule can walk that list and assert each one has a test file.

**The first segment names a source root, and nothing is implicit.** Code lives in more than one place
— the application, its tooling, its packages. If the application root is assumed, a tooling test at
`tests/support/` reads as a test for the application's own `support` directory. Name every root.
Two normalisations keep it mechanical: **every segment takes your test tree's casing convention**
(`tooling/module-graph/` → `tests/tooling/module_graph/`, or whatever casing your test tree uses),
and **a package's internal source segment is dropped**
(`packages/foo-bar/src/baz` → `tests/packages/foo_bar/baz_test`).

**A test covering several subjects belongs to the one that *initiates* it** — the entry point a
caller actually invokes. A checkout test exercising cart, pricing and payment is a test of checkout.
When two subjects both legitimately initiate a flow, file it under the one a reader would look for
first and say so in the test's name.

**When one subject outgrows one file**, split by behaviour, keeping the subject as the prefix so the
files sit together: `refunder_test`, `refunder_partial_refund_test`. Never split by cost — that is rule 2
sneaking back in through a filename.

**Scaffolding** — fixtures, scenario builders, fakes — has no subject, so it inherits one: it lives
in the test subtree of the area using it, under one reserved directory name (`support/`) so the
mirror-diff can ignore it. A fixture shared by two areas moves up to their nearest common ancestor,
never to the root. Root-level scaffolding is a drawer because nothing owns it; an owned parent is not.

### 2. Cost is declared in the test, not encoded in its location

The familiar layout puts speed in the path: `unit/`, `integration/`, `feature/`. It looks tidy and
quietly breaks rule 1.

These are properties of **different objects**. Where a test goes is a property of the *subject*, which
is stable. What a test costs is a property of the *test*, which changes. Encode both in the path and
they fight: one subject's tests scatter across three trees, you must classify a test's runtime
behaviour before writing it, and adding one fixture forces a file move — a rename in version control
for a one-line change.

```text
tests/src/billing/refunder_test     ← all of refunder's tests, one place

    (however your runner spells tags — its tagging/grouping mechanism:
     attributes, groups, annotations, markers)

    tag: database
        it records a refund against the original payment

    (untagged — the cheapest tier)
        it refuses a refund larger than the payment
```

A test file *does* still move when its **subject** moves. That move is meaningful: the subject changed
identity, and moving the test keeps the derivation true. Moving a file because it gained a fixture is
caused by something that has nothing to do with the subject.

Name tiers for **what a test may touch**, ordered by cost — yours to name as suits your stack:

| Tier | May touch | Typical example |
|---|---|---|
| Isolated | nothing beyond the code under test | a subject whose promise is a calculation |
| Database | persistence | a service that reads and writes records |
| Full | the whole application wired together | request handling, commands |

### 3. Some tests ask a different question, and need a different runner

A browser test needs a browser. A test that only reads your source files never boots the app at all.
Those aren't cheap and expensive versions of the same thing — they are different **kinds**, and by
the rule underneath, a different runner belongs in the path.

```text
tests/
├── src/  tooling/  packages/   one kind — executes your code — one root per source root
├── interface/                  drives the real UI; a different runner
└── conventions/                reads your source, never runs it
```

So the first segment names **either a kind or a source root**, and the two never collide: kind wins
when the test needs a different runner, and the root nests inside it —
`tests/interface/tooling/…`, `tests/conventions/…`, `tests/src/…`.

Kind and tier are independent. **A kind with uniform cost declares its tier once at the branch** — a
base class, a suite-level default — not per file. The untagged-means-cheapest default applies inside
the mirrored kind, where cost genuinely varies test by test.

The UI branch also tends to derive its paths from something else — routes, or the front end's own
structure. That's fine, but **pick one and record it in that branch's own README**. One rule per
branch means one rule, chosen and written down; not one rule per person.

### 4. Rules about the codebase get their own branch

Some tests have no subject to mirror because their subject is the codebase: *every endpoint that
changes data has a test*, *no module reaches into another's internals*, *every new table carries a
comment*.

Group them by the area of the codebase the rule polices, one file per rule, named for the assertion:

```text
tests/conventions/
├── routes/       every_mutating_endpoint_is_tested_test
├── modules/      no_module_reaches_into_another_test
└── migrations/   every_new_table_has_a_comment_test
```

**A rule that must *run* something does not belong here.** "Every migration is reversible" is a rule
about the codebase, but checking it means executing migrations — so it goes in the mirrored tree under
what it runs (`tests/src/database/migrations_are_reversible_test`), tagged for its real cost. Putting it
in `conventions/` would break that branch's one guarantee: nothing in it boots the application.

This branch is what turns "are we testing the right things?" from an opinion into a gate.

## Make the safe choice the default

If a test must *declare* that it needs the database, then a test declaring nothing should get **less**
access, never more.

The cheapest tier is the one tier you never declare — absence of a declaration is itself the
declaration, and it is the safe one. Every step up is explicit and greppable. Forgetting becomes a
loud failure rather than a silent upgrade.

## Enforce it three ways

A convention that only lives in a document decays.

1. **Write it down.** Necessary, insufficient.
2. **A rule test** catches violations at inspection speed, before anything runs.
3. **A runtime guard**: whatever a cheap test may not touch must fail **at the moment it is touched**,
   with a message naming the fix. The mechanism is yours — a connection factory that throws when the
   isolated tier asks for one, a fixture installing a poisoned client, a base class that refuses. The
   timing is the point.

Layer 3 is the one that holds. Static rules see imports; they don't see a database call reached through
three layers of indirection. A suite that drifts into "half the fast tests aren't fast" is usually one
where nothing failed at the moment it happened.

## Tiers are options, not a schedule

A tier doesn't say when to run anything. It gives you a **handle** — a way to ask for a subset whose
cost you already know.

> **You declare what a test costs. Something else decides when it runs.**

That matters because *when to run which tests* is tacit knowledge, and the people and agents touching
your code increasingly don't have it — nor can they be told cheaply, since some of it isn't even local
(work inside module A has no way to know module B depends on it, and that changes as the code changes).
So don't teach the judgement, make it **derivable**: when a changed file maps mechanically to a subset
of tests, a harness computes and runs it unprompted. Cost is what decides the automation you can hang
on it:

| Kind | Tier | Fast enough to attach to |
|---|---|---|
| Conventions | isolated | every file edit |
| Mirrored | isolated | every step of a task |
| Mirrored | database | a checkpoint, before handing work back |
| Interface | full | a gate — pre-push or CI |

None of this has to be wired up; the option just doesn't exist unless cost is declared and the subset
is derivable. An automated subset may be approximate — missing a transitive dependency is fine when a
complete gate runs before the work lands. Fast and approximate early, slow and complete at the boundary.

## Adopting it late

Almost nowhere starts from scratch. Quarantine everything old in a single `legacy/` branch rather than
reshuffling gradually; make it a ratchet — a rule test that fails when its file count goes *up* — so
"nothing new is added here" is a fact rather than a hope. Then migrate one subject area at a time,
leaving the remainder running untouched.

## Diagnostic questions

- Can a script map a changed source file to the tests covering it, with no human in the loop?
- Does one subject have one test file, or are its tests spread across trees by cost?
- If a test gains a database dependency, is that a one-line edit or a file move?
- When someone puts an expensive test in the cheap tier, what fails — and when?
- Where do fixtures and scenario builders live, and who owns them?

## See also

- [Documentation Placement](../documentation-placement/README.md) — the same location-follows-subject reasoning, applied to docs
- [Deep Modules](../deep-modules/README.md) — for *what* to test under a module convention, see its [testing note](../deep-modules/testing.md)

## Stack bindings

The rules above name roles (source roots, kinds, tiers, the tagging mechanism), not files. How each
role is spelled in a concrete stack lives in `bindings/<stack>/README.md`. Today: [`bindings/laravel/`](bindings/laravel/README.md), [`bindings/nestjs/`](bindings/nestjs/README.md).

