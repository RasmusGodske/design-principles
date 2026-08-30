---
type: concept-explainer
title: "Example: The Notification Framework"
description: A full walkthrough of the vendor-plural steady state — founding a notification framework from experience, keeping channel semantics out of the shared layer, using lockers for channel-owned config, and converting a framework temptation into an honest contract.
---

# Example: The Notification Framework

*The ordinary case of [framework-and-implementation](../README.md): implementations plural in **space** — one per external channel. This example shows founding from experience, contracts that name outcomes, the locker in daily use, and the moment the framework is tempted to peek.*

## The scenario

A product must notify users. Email ships now; the roadmap has SMS next quarter and mobile push after that. One team owns the shared plumbing; feature teams will say "notify this user about X" without caring how it travels.

This is a textbook founding situation: the founder has built notification systems before. That experience is **evidence** — it names real invariants (every channel delivers, fails, and has moments of unavailability) and real variance (every channel authenticates, formats, and addresses differently).

## The tempting design — and why it rots

The naive shape grows from the first implementation outward:

```text
// notifications table, grown email-first — WRONG
to_email     string
subject      string
html_body    text
smtp_status  string, nullable
```

Nothing here is wrong *for email*. But `subject` means nothing to SMS, `html_body` is actively hostile to it, and `smtp_status` is one vendor's diagnostic in everyone's schema. When SMS arrives, its author faces a schema that speaks email — so they add `phone_number` and `segment_count` beside it, and every future reader must know which columns belong to whom. The framework has become an archive of every channel's private vocabulary.

## Founding it instead

**Sort every piece of knowledge:** *is this true of all channels, or of this one?*

| Knowledge | Verdict | Home |
|---|---|---|
| A notification is requested, attempted, accepted or failed | Invariant | Framework: lifecycle + result contract |
| A channel can be unavailable (provider outage, expired credentials) | Invariant | Framework: health contract |
| How a channel authenticates, formats, addresses | Per-channel | The implementation |
| What configuration a channel needs to operate | Per-channel, *shape unknown to host* | The **locker** |

The framework founds two contracts — both name **outcomes it consumes**, never procedures:

```text
interface NotificationChannel:
    // Permanent key, e.g. 'email'. Never renamed, never reused.
    key() -> string

    // Attempt delivery; report what happened.
    deliver(notification: Notification) -> DeliveryResult

    // Is this channel usable right now?
    healthCheck() -> ChannelHealth

data DeliveryResult:
    status:        DeliveryStatus      // accepted | failed | rejected
    failureReason: string | null       // human-readable, channel-authored
```

Note the status is `accepted`, not `delivered` — a deliberate contract decision, and itself an application of the second-implementer test. Email and SMS are asynchronous in reality: SMTP acceptance is not delivery, and bounces or delivery receipts arrive later. A contract that promised `delivered` would encode a synchronous paradigm the very first channels can't honor; `accepted` names the outcome the dispatcher can actually consume, and later-arriving delivery reports stay channel-owned semantics.

And a schema that passes the **vocabulary test** — explainable without naming any channel:

```text
// notification_channel_configs
channel_key  string    // 'email', 'sms', 'push'
enabled      boolean
locker       json      // channel-owned; the framework NEVER reads it
```

The locker's **write path** belongs to the channel too: each channel supplies its settings form and validation to the host through a contract (that's shape — "give me your settings surface"), and the framework renders the form and stores the result without interpreting it. Nothing in the host knows that `smtp_host` must be a hostname; the email channel validates its own locker.

The framework's dispatcher shows why this stays generic — it consumes only contract outcomes:

```text
for channel in registry.enabledChannelsFor(user):
    result = channel.deliver(notification)
    log.record(notification, channel.key(), result)      // outcomes only
```

## Two implementations, opposite semantics, same contract

```text
class EmailChannel implements NotificationChannel:
    deliver(n: Notification) -> DeliveryResult:
        settings = EmailLocker.from(config.locker)     // smtp_host, from_address
        // renders an HTML template, speaks SMTP, maps bounce codes to failureReason

class SmsChannel implements NotificationChannel:
    deliver(n: Notification) -> DeliveryResult:
        settings = SmsLocker.from(config.locker)       // gateway_url, sender_id
        // truncates to segments, calls an HTTP gateway, maps carrier errors
```

Note where the locker's *type* lives: `EmailLocker` and `SmsLocker` are data classes **inside their channels**. The framework stores the JSON; only the owner gives it meaning. The two channels disagree about everything — rendering, transport, failure taxonomy — and the framework cannot tell, because disagreement lives entirely below the contract line.

## The temptation — and the honest contract

Months later, the settings UI wants to display each channel's sender ("no-reply@acme.com", "+1 555 0100"). The sender lives in each locker. Two tempting fixes, both wrong:

1. **Peek:** `config.locker['from_address'] or config.locker['sender_id']` in the UI handler. The locker is now a contract in disguise — the framework depends on undocumented keys, and the next channel breaks the settings page by naming its key differently.
2. **Promote a column:** add `sender` to the shared table. Better — but now the framework has guessed that every future channel *has* a sender (does a webhook channel?).

The honest fix: the framework has discovered it **consumes a new outcome**. This is the [second growth move](../README.md#3-found-deliberately-grow-on-evidence) — not a promotion (nothing was proven in a channel and lifted), but a **new demand**, justified by the framework's own consumption and paid for visibly: every channel must now answer it.

And the demand must be honest about being **partial**: the objection to the shared column — "does a webhook channel have a sender?" — applies just as hard to a required method. A non-nullable `describeSender(): string` would force sender-less channels to fabricate a string: the universal-column guess wearing an interface. So the contract models absence:

```text
interface NotificationChannel:
    // ...
    // Human-readable sender identity for settings/audit display, or null if
    // this channel has no meaningful sender.
    describeSender() -> string | null
```

Each channel that has a sender answers from its own locker; a channel without one answers `null` and the UI renders accordingly. The dependency is now visible in the type system, documented, and honestly answerable by every future implementation. Two general rules fall out: **the moment the framework wants something from inside a locker, that want is a contract trying to be born** — and **a capability only some implementations have is declared as partial, never universalized by force.**

## Litmus audit

| Test | This design's answer |
|---|---|
| Second-implementer | A postal-mail channel implements the three methods; zero framework change. `accepted` (not `delivered`) keeps async-reporting channels honest too. |
| Vocabulary | Schema and interfaces mention no channel; `smtp_status` never existed. |
| Evidence | Founding contracts trace to invariants known from experience — acceptance, failure, health. `describeSender()` entered post-founding as a demand: the framework itself consumes it. |
| Locker | The framework round-trips `locker` without reading it; the sender need became a declared (and honestly partial) contract. |
| Lift | Channel-internal helpers (template rendering, segment math) are separated per channel, promotable if a second channel ever wants them. |
| Conformance | One framework-shipped suite (deliver → result shape, health check, settings round-trip) runs against every channel with no channel-specific branches. |
