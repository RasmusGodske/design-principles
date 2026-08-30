---
type: concept-explainer
title: Data Minimization
description: Why durable records, secondary stores, and repo artifacts should hold references instead of copies of personal data, keep only what a result depends on, and scrub by default — so privacy failures break tests instead of leaking data.
---

# Data Minimization

> **Persist the minimum. Durable records hold references to people and secrets, not copies of them; a value is snapshotted only when the computed result depends on it; and every privacy mechanism fails closed — an unhandled field is scrubbed by default.**

Most systems don't leak personal data through their primary store — that one is designed deliberately. They leak it through everything *around* the primary store: audit rows that copied a name "for convenience", webhook payloads persisted before anyone asked whether they should be, debug telemetry that logged the request body, test fixtures recorded from a real account, documentation that names the customer whose bug prompted it. Data minimization is the lens over all of those surfaces at once: **for every durable artifact, what is the minimum it needs to hold — and what happens to everything else?**

The principle has four disciplines. They look unrelated (schema design, ingestion, testing, documentation) but they are the same decision applied to different surfaces.

## 1. Reference people — don't duplicate them

A durable record (audit trail, activity log, immutable history row) stores the **identifier** of a person or entity, never a copy of their name, email, or other personal fields. Display data is resolved live at read time, from the one place that owns it.

The test for the exception is precise: **snapshot a value only when the computed result actually depends on it.** A commission calculation that used an exchange rate must snapshot the rate — the result is meaningless without it. An approval record that notes *who* approved needs the approver's id — the result does not change if the approver later renames themselves, so their name has no business being copied into the row.

Why this is worth being strict about:

| Copied PII costs you | Because |
|---|---|
| Right-to-erasure compliance | Deleting the person's record must delete their data. Every copy in an audit row is an orphan you now have to find. |
| Correctness | Copies go stale. The person renames, the email changes — every duplicated field is now wrong forever, in rows you promised were immutable. |
| Breach blast radius | Every table holding copies is another table whose compromise exposes people. References expose nothing on their own. |

## 2. Excluded data stays excluded — everywhere

When the system decides some data is out of scope — a sync filter that only admits certain records, a scope that excludes certain fields — that decision applies to **every store, not just the primary one**. Raw inbound payloads, webhook request logs, debug rows, telemetry: if the filter said "we don't take this data", then a log table quietly retaining the full payload has overruled the filter.

The failure mode is always the same: the primary path is carefully filtered, and a secondary path built "for debugging" persists the unfiltered original. Data you were not supposed to store is now stored — you just call it a log. Minimization applies at the *first* point of persistence: reject or trim before writing, not after.

## 3. Committed artifacts are anonymized — always

Anything that lands in the repository — test fixtures, recorded API responses, documentation, examples, design docs, agent skills and rules — is durable, shared, and effectively public to everyone with repo access, forever (history included). Therefore:

- **Fixtures recorded from real systems are scrubbed before commit.** Recording real responses is the right way to build honest test data — but names, emails, company identifiers, and tokens are replaced with fake values as part of the recording pipeline, not as an afterthought.
- **Docs stand on their own feet.** A document that says "customer X's setup does Y" is both a privacy leak and a maintenance trap — it goes stale when that customer changes. State the behavior as a system fact; drop the customer.
- **No secrets, ever.** Credentials and tokens in committed artifacts are compromised the moment they land, regardless of later deletion.

## 4. Privacy fails closed

Every scrubbing, filtering, or anonymization mechanism must treat the **unknown** as sensitive. Concretely: preserve fields by **allowlist**, and scramble or drop anything not on it. When the upstream adds a new field tomorrow, a fail-closed scrubber mangles it and a test somewhere breaks — annoying, visible, fixed in minutes. A fail-open scrubber (blocklist) passes the new field through silently, and the leak is discovered by accident months later, if at all.

This is the privacy instance of a broader stance: an omission should produce a loud failure, not a silent behavior. The cost of fail-closed is a broken test; the cost of fail-open is a leak with no alarm attached.

## Litmus tests

1. **The erasure test** — if this person or customer is deleted from the primary store, does any copy of their personal data survive — in audit rows, snapshots, logs, fixtures, docs? Each survivor is a minimization failure.
2. **The result-dependency test** — for every field about to be copied into a durable record: *does the computed result depend on it?* If the result is identical without it, store the reference instead.
3. **The excluded-data test** — walk every secondary store (raw payloads, request logs, telemetry, debug tables). Does any of them retain data the system's own filters or scopes declared out of scope?
4. **The new-field test** — upstream adds an unexpected field tomorrow. Does your persistence/scrubbing layer leak it by default, or scramble it by default? Only the second is acceptable.
5. **The public-repo test** — could this artifact (fixture, doc, example) be published openly without exposing a person, a customer, or a credential? If not, it isn't done.

## When it applies — and when not

**Apply when designing** anything that persists beyond the request: audit trails and immutable histories, activity/event logs, webhook and integration ingestion, telemetry and debug capture, recorded test fixtures, and any document or artifact committed to the repository.

**Don't contort:**

- **The primary store is not the target.** The system of record for data you legitimately hold is designed by its own domain rules; minimization governs the *copies and side-channels*, not the source of truth.
- **Result-bearing snapshots are correct, not violations.** When the computation genuinely depended on a value, snapshotting it is exactly right — that is the audit trail doing its job. The test is dependency, not squeamishness.
- **Ephemeral runtime data is out of scope.** Data held in memory, or in short-lived caches with expiry, is a different risk class. This principle governs what *endures*.

## Relation to the other lenses

- [`config-and-record`](../config-and-record/README.md) owns the snapshot-vs-reference decision mechanically (what identity a thing carries, how it is referenced). Data minimization adds the privacy dimension to that decision: *when in doubt about copying a person's data, the answer is a reference.*
- [`pure-core-persistent-shell`](../pure-core-persistent-shell/README.md) puts persistence decisions in the shell, at the edge. Data minimization is a constraint on those shell decisions: the caller decides *whether* to persist; this lens bounds *what may be kept*.
