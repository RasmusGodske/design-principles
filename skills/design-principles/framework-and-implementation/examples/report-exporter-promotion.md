---
type: concept-explainer
title: "Example: The Report Exporter — Growth by Promotion"
description: A full walkthrough of how a framework legitimately grows — including the two classic first-implementation leaks (a vendor column in the shared schema, a framework branch on implementation type), their corrections, and retry logic that waits inside one destination until a second consumer reveals the real invariant.
---

# Example: The Report Exporter — Growth by Promotion

*The growth rule of [framework-and-implementation](../README.md) in motion. The mistakes are the most instructive part, so this example makes them on purpose — twice — before showing the promotion that waiting earns.*

## The scenario

A reporting module lets customers export generated reports to external destinations. The first destination is a cloud spreadsheet service; a data-warehouse destination is on the roadmap but unscoped. The framework is founded small, from experience with export pipelines:

```text
interface ExportDestination:
    key() -> string                          // permanent: 'spreadsheet'
    send(file: ExportFile) -> ExportResult   // delivered? failed? why?

// export_destination_configs
destination_key  string
enabled          boolean
locker           json     // destination-owned; framework never reads it
```

One contract, one outcome, a locker. Then real life starts.

## Leak #1: the vendor column

Mid-build, the spreadsheet destination needs to remember which remote folder it uploads into. The author is inside a framework migration file anyway, and the tempting move is one line:

```text
// framework migration — WRONG
spreadsheet_folder_id  string, nullable
```

Walk this forward to see the rot. The warehouse destination arrives; it has *datasets*, not folders. Its author finds a shared table with a column that is `NULL` for them, meaningful to someone else, and named in a vendor's vocabulary. They add `warehouse_dataset` beside it. The next destination adds its own. Two years later the shared schema is a museum of every vendor's private concepts, and no reader can say which columns the *framework* actually uses. That is the **vocabulary test** failing in slow motion — one nullable column at a time.

The correction is mechanical once the sorting question is asked — *does the framework consume `folder_id`?* No; only the spreadsheet destination reads it. So it lives in that destination's locker:

```text
// inside the spreadsheet destination only
data SpreadsheetLocker:
    folderId:    string
    accessToken: string
```

The shared schema stays vendor-free, and the concept "folder" exists only where it means something. One caveat the token makes visible: opacity is about *interpretation*, not protection — the framework can (and for credentials should) encrypt the locker at rest without ever reading it, and [`data-minimization`](../../data-minimization/README.md) still governs what may land in a locker at all.

## Leak #2: the framework branch

Next, exports need formatting: the spreadsheet wants cell-typed rows, but CSV is fine for everything else. The tempting implementation, in the framework's export runner:

```text
// framework runner — WRONG
payload = switch destination.key():
    'spreadsheet' -> toTypedRows(report)
    otherwise     -> toCsv(report)
```

The framework now *knows things* about one implementation — and every future destination must edit **framework code** to describe its format, which means the boundary no longer protects anyone. A `switch` on implementation type inside a framework is always the same diagnosis: **an interface method waiting to be declared.** The framework has discovered it consumes an outcome ("what payload shape do you accept?") — the [new-demand growth move](../README.md#3-found-deliberately-grow-on-evidence), same as the notification example's `describeSender()` — so it asks for it honestly:

```text
interface ExportDestination:
    // ...
    // Convert a report into whatever this destination accepts.
    preparePayload(report: Report) -> ExportPayload
```

The branch disappears; each destination owns its formatting; the runner is generic again.

## The wait: retry logic that looks "obviously reusable"

Uploads to the spreadsheet service flake — rate limits, transient 503s. The destination's author builds retry-with-backoff and immediately feels the pull: *this is obviously useful for every future destination; it belongs in the framework.*

Under the growth rule, it does not — not yet. It has **one consumer plus imagination**. So it is built to wait well, per the **lift test**: inside the destination, in its own well-named, documented class, not entangled with spreadsheet specifics:

```text
// inside the spreadsheet destination — separated, liftable
class RetryWithBackoff:
    // Retries a callable on transient failure. Kept framework-free on purpose:
    // promote when a second destination needs retries.
```

## The payoff: promotion shaped by two real consumers

The warehouse destination ships — and it also needs retries. Now there are two data points, and they disagree in exactly the way that proves waiting was right: the warehouse loads data in batches, and **retrying a partially-committed batch duplicates rows**. "Always safe to retry" — the invariant the spreadsheet case alone would have baked into the framework — was never an invariant. It was one vendor's property.

The promoted feature is shaped by both consumers:

```text
// promoted into the framework — with two real consumers as evidence
interface RetryPolicy:
    // Classify a failure: retryable (after how long) or terminal.
    classify(failure: DeliveryFailure) -> RetryDecision
```

Each destination supplies its own policy — the spreadsheet's is a simple backoff, the warehouse's refuses retry after partial commit. The framework runs the loop; the semantics stayed with the owners. Promotion was a mechanical refactor because the code had been waiting in liftable shape.

**The counterfactual is the lesson.** Founded speculatively in month one, framework-level retry would have hard-coded retry-always; the warehouse author would have had to fight, disable, or work around a shared behavior — the over-founded failure, arrived at with the best intentions.

## Litmus audit

| Test | This design's answer |
|---|---|
| Second-implementer | The warehouse destination shipped against unchanged contracts — after the two leaks were corrected. |
| Vocabulary | `spreadsheet_folder_id` was evicted to a locker; the schema and runner name no vendor. |
| Evidence | `preparePayload` and `RetryPolicy` each entered the framework with named consumers demanding them — none arrived by speculation. |
| Locker | Folder id, tokens, dataset names: all in their owners' lockers; the framework round-trips JSON it cannot read. |
| Lift | `RetryWithBackoff` waited as a documented standalone class — its promotion into `RetryPolicy` touched no spreadsheet internals. |
| Conformance | One destination suite (send → result shape, payload preparation, retry classification) runs against both destinations with no destination-specific branches. |
