---
type: concept-explainer
title: Deterministic Tests
description: Why a test must give the same answer every time it runs — whatever the time, the order, the machine, or the tests beside it — and how base-class defaults for the clock, randomness and the network make that the path of least resistance. Open when writing or reviewing a test, a test base class or fixtures, or a test that failed "for no reason".
---

# Deterministic Tests

> **A test gives the same answer every time it runs: at any date and hour, after any other test, on any machine, as often as you like. Control every input the test doesn't own — the clock, randomness, the network, shared state — and make that control the default, not a habit.**

Start with a story. A test checks that an order placed an hour ago counts towards today's sales. It passes all day. At half past midnight it fails: an hour ago was yesterday. Nobody broke anything; the test met a clock it never controlled.

A developer who hits this learns to rerun. An agent can't tell it apart from a real failure. It reads the code it just changed, "fixes" something, and the next morning the test passes again by itself, with the "fix" still in place.

That is the real cost of a non-deterministic test: not the failure, but the lie. A test that sometimes fails for no reason teaches everyone that red doesn't mean broken. A test that sometimes passes when it shouldn't is worse: it hides the bug it was written to catch. Tools that rerun only what changed and replay the rest from cache multiply both, because a lucky pass is remembered as a pass.

## The four rules

### 1. Control every input the test doesn't own

A test's result may depend on the code under test and on what the test itself sets up. Nothing else. The usual hidden inputs:

- **The clock**: the current time, today's date, the hour, the length of the month, time zones, daylight saving.
- **Randomness**: generated names, amounts, dates and counts in fake data; shuffles; random identifiers that decide an order.
- **The network**: a real HTTP call is slow, fails when the other service is down, and asserts on somebody else's data.
- **State shared within a process**: static caches, singletons, registries, leftover mocks — anything one test leaves behind that the next one reads. In a parallel run, which tests share a process changes from run to run.

### 2. Make control the default, in the base class

A rule every test must remember is a rule some test forgets. Put the controls where no test can miss them, in the base test case:

- **A fixed clock.** Every test starts at the same moment: a weekday, mid-month, at midday, far from any boundary. Each reading of the clock is a little later than the one before, so timestamps still order, but how far time moves depends on what the test does, never on how fast the machine runs it.
- **Seeded randomness.** Each test seeds the random generator from its own name. Data stays varied across tests, yet each test gets the same data on every run.
- **No real network.** An outgoing request that no fake answers throws, naming the URL.
- **Clean shared state.** Whatever a test can leave behind is reset after it.

Then the careful choice is the one you get by doing nothing.

### 3. Opting out is explicit and visible

Some tests are about the very thing a default controls: what happens at midnight, at month end, across daylight saving; whether a retry really waits. They don't switch the default off. They state the input they need: travel to 23:59 on the last day of the month, freeze time, answer a URL with a fake. A reader sees exactly which moment or response the test is about. Real time or a real network in a test is a decision someone wrote down, never an accident.

### 4. Assert on what you built, not on what happened to be generated

Fake data is for the parts of a record the test doesn't care about. Whatever the assertion depends on, the test sets explicitly.

```text
✗  How much is checked — and what — depends on random data
   orders = create a random number of orders, each with a random due date
   for each order the service calls overdue:
       assert its due date is in the past

✓  The test builds exactly the rows it is about
   overdue  = create an order due yesterday
              create an order due tomorrow
   assert the service's overdue list is exactly [overdue]
```

The second test fails when the logic breaks. The first may loop zero times and pass.

## What you get for it

| | Because |
|---|---|
| **Red means broken** | A failure always has a cause in the code. Nobody — person or agent — learns to rerun and hope. |
| **A failure reproduces** | Run it again and it fails again, the same way: on your machine, on CI, tomorrow. |
| **Cached results stay true** | A tool that replays unchanged tests replays what they would really do. |
| **The numbers mean something** | Assertion counts and coverage change only when the code or the tests change. |

## Quick checks

1. **Another time**: would the test pass at 00:30, on the 31st, on 29 February, in another time zone? If the answer takes thought, the clock is an uncontrolled input.
2. **Twice**: run the suite twice. Every test should report the same result and the same number of assertions. A difference is a hidden input.
3. **Alone and in a crowd**: the test should give the same answer on its own and amid the whole suite. A difference is shared state.
4. **Unplugged**: would it pass without a network? If not, it tests somebody else's server.
5. **The assertion**: does what it checks depend on a value the test didn't set? Then set it.

## When it applies — and when not

**Use this lens** when writing or reviewing any test, when designing a test base class or fixtures, and whenever a test fails "for no reason". That failure is a hidden input announcing itself: find it instead of rerunning.

**Don't overdo it:**

- **Fixing the inputs is not faking the logic.** Control the clock and the data; don't mock the code under test into agreeing with itself.
- **Variety still has a place, on purpose.** A test that explores many generated inputs is valuable, as long as it records the seed it used so any failure can be replayed exactly.
- **Not every random value matters.** A random email nobody asserts on is fine. A random amount the total depends on is not.

## Relation to the other lenses

- [`pure-core-persistent-shell`](../pure-core-persistent-shell/README.md): a pure computation receives everything it depends on as input, so it is deterministic by construction and needs no controls. The more logic lives in the pure core, the less this lens has to police; the shell's hidden inputs — the clock, the database, the network — are exactly the ones rule 1 lists.
- [`single-chokepoint-per-fact`](../single-chokepoint-per-fact/README.md): the same move, applied to tests. Put each control in one place every test passes through, instead of trusting every test to remember it.
- [`testing`](../testing/README.md): that lens gives the suite its shape — where a test lives, what it costs — and makes the cheapest, safest tier the one a test gets by declaring nothing. This lens makes the same move for a test's inputs: the controlled clock, seeded data and blocked network are what a test gets by doing nothing. Shape says which tests to run; determinism is what lets you believe their answer, including an answer replayed from cache.

## Stack bindings

The rules above name roles (the clock, the random generator, the network, the base test case), not tools. How each is spelled in a concrete stack lives in `bindings/<stack>/README.md`. Today: [`bindings/laravel/`](bindings/laravel/README.md).
