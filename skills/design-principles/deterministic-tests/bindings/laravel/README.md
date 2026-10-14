---
type: binding-rule
title: Deterministic Tests — Laravel binding
description: How to give a Laravel test suite a fixed clock, seeded randomness and no real network by default — one trait in the base test cases — and the traps that keep a suite non-deterministic even then.
---

# Deterministic Tests — Laravel binding

This file maps [`../../README.md`](../../README.md) onto Laravel (PHPUnit or Pest). It adds no rules; it only says how each control is spelled here and where the traps are.

## One trait in the base test cases

```php
namespace Tests\Concerns;

use Carbon\Carbon;
use Carbon\CarbonImmutable;
use Illuminate\Support\Facades\Http;

trait DeterministicTestEnvironment
{
    // A weekday, mid-month, at midday: far from every date and time boundary.
    public const FIXED_NOW = '…';

    protected function setUpDeterministicTestEnvironment(): void
    {
        // The clock: starts at FIXED_NOW; every reading is a millisecond after the last.
        $start = CarbonImmutable::parse(self::FIXED_NOW);
        $readings = 0;
        Carbon::setTestNow(static function () use ($start, &$readings): CarbonImmutable {
            return $start->addMilliseconds($readings++);
        });

        // Randomness: seeded from the test's own name, so it differs per test and repeats per run.
        $seed = crc32(static::class.'::'.$this->name().'#'.$this->dataName());
        mt_srand($seed);
        fake()->seed($seed);
        fake()->unique(reset: true);

        // The network: a request no fake answers throws, naming the URL.
        Http::preventStrayRequests();
    }

    protected function tearDownDeterministicTestEnvironment(): void
    {
        Carbon::setTestNow();
        mt_srand();
    }
}
```

| Base class | How the trait runs |
|---|---|
| Extends Laravel's `Illuminate\Foundation\Testing\TestCase` | Automatically: Laravel calls `setUp{TraitName}()` and `tearDown{TraitName}()` for every trait a test case uses. Just `use` it. |
| Extends PHPUnit's `TestCase` and boots the application itself | Call `setUpDeterministicTestEnvironment()` after creating the application, and the tear-down before flushing it. |
| Browser tests | Leave the clock out: the browser runs its own JavaScript clock, which a fixed PHP clock would contradict. Seeding and blocking stray requests still apply. |

**Why a clock that advances per reading.** A frozen clock (`freezeTime()` for the whole suite) makes every `created_at` equal, so "latest first" orderings tie. A clock that follows real elapsed time from a fixed start makes results depend on how fast the machine runs: a test generating dates "in the last 30 days" gets different dates on a busy CI runner. One millisecond per reading keeps timestamps ordered and depends only on what the test does.

## Stating an input in a test

| The test is about | Write |
|---|---|
| A particular moment | `$this->travelTo(now()->endOfMonth()->setTime(23, 59))`, or `$this->freezeTime()` |
| A remote answer | The provider's fake server, or `Http::fake([...])` for that URL |
| The network itself (rare) | `Http::allowStrayRequests()`, with a comment saying why |
| Generated variety | Reseed explicitly — `fake()->seed(...)` — and keep the seed in the failure message |

## Traps that survive the defaults

- **`Collection::random()`, `Arr::random()`, `Collection::shuffle()`, `Str::random()`, `random_int()`** use PHP's cryptographic generator, which cannot be seeded. In a factory or test that decides something an assertion depends on, use the seeded Faker (`$this->faker->randomElement(...)`) — or better, no randomness: assign in turn, spread dates evenly.
- **`new \DateTime('now')`, `new \DateTimeImmutable()`, `time()`, `date()`** read the system clock, outside Carbon's test clock. Anything a test relies on — including fake API servers that stamp `updatedAt` — reads the time through `now()` / `Carbon`.
- **A token refresh or other implicit call** in a client's constructor or retry path reaches the network even when the test faked the call it cared about. `preventStrayRequests()` is what makes it visible.
- **Order-dependent results with identical seeds** mean code consumed a different number of random values because of state an earlier test left in the process (static caches, framework caches). The fix is in the test's data, not in the seed: build what the assertion depends on explicitly.

## Checking it

Run the whole suite twice with JUnit output (`--log-junit=…`) and compare each test's result and assertion count. Any difference is a hidden input. Run a suspect file alone and after the file that precedes it in the worker: a difference is shared state.
