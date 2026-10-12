---
type: concept-explainer
title: Retire, Don't Erase
description: Why a change that removes or overwrites stored information must always leave a way back — retire the thing or keep a backup of what changed — and what a real way back has to do. Open when writing a schema change, a data fix, a backfill or a bulk script that drops, rewrites or deletes stored data, or when reviewing one.
---

# Retire, Don't Erase

> **A change that removes or overwrites stored information always leaves a way back. Take the thing out of service instead of destroying it, or keep a backup of exactly what you changed. A way back restores the information, not just the structure that held it.**

Start with a story. Orders used to carry a *delivery method* setting, and the warehouse now ships every order the same way, so the setting has nothing left to choose. A schema change drops the column. Its undo step adds the column back with every order set to the default, and the change ships. Three weeks later someone finds that the finance team's monthly report still split revenue by delivery method. The undo runs fine and the column is back, but every value in it says the same thing. What each order actually had is gone, and nothing warned anyone on the day.

The change itself was right; the setting really was dead. What went wrong is that the change made the decision *final* at the same moment it made it *true*. Finding out that something still depended on the data is normal. Not being able to go back is the failure.

This lens is about changes made by the people building the system: schema changes, data fixes, backfills, bulk scripts. What a *user* may remove, and when, is [safe deletion](../safe-deletion/README.md).

## Two ways to leave a way back

| | Use when | What you do |
|---|---|---|
| **Retire** | A whole column, field, table or file stops being used | Take it out of service but keep it: rename it with a `retired_` prefix so nothing reads it by accident, and anything that still does fails loudly instead of quietly getting nothing |
| **Back up** | Values are rewritten in place, or rows are deleted | Before changing anything, copy exactly what you are about to change into a backup made for this one change; the undo restores from it |

Retiring keeps the information where it was, so undoing is a rename. A backup is for when the information itself has to change: the old values have nowhere else to live, so they get a dedicated place of their own.

Either way, the decision to erase for good is a separate, deliberate act, taken later by someone who knows the retired thing or the backup is no longer needed. This lens does not say when that is. It only says the change itself must not take that decision.

## What a real way back does

**1. It restores the information, not just the structure.** A column that comes back empty, or filled with a default, is not an undo. The test: after undoing, does every record hold exactly what it held before?

**2. It never overwrites later work.** Between the change and the undo, people and processes keep working. The undo only restores a record that is still exactly as the change left it. If a record has moved on since, the undo stops and names it, rather than silently throwing that later work away. This is why a backup keeps what the change *wrote* next to what it *replaced*: comparing the two is how the undo knows whether a record is still its own.

**3. It is all-or-nothing, and so is the change.** The change checks its own result before it commits (did every rewritten record end up as intended?) and rolls back entirely if not. The undo does the same. A half-applied change, or a half-applied undo, leaves data that matches neither the before nor the after, and that is the hardest state to recover from.

## Leave a trail

Anything retired, and every backup, says where it came from and why, on the thing itself: which change created it, and what that change did. Someone who finds a `retired_` field or a backup years later should be able to trace it back without asking anyone, and decide on their own whether it can finally go.

Write the reason, not just a pointer. The change that created it may itself be pruned, squashed or archived one day; a reason written on the retired thing still stands on its own.

## Worked examples

| Change | Way back |
|---|---|
| Drop a setting nothing reads any more | Retire the field (`retired_delivery_method`); undoing renames it back |
| Drop a whole table of a feature that was removed | Retire the table; undoing renames it back |
| Rewrite a formula stored on many records | Back up each record's old and new formula; undoing restores records still holding the new one |
| Normalize spellings (`canceled` → `cancelled`) | Back up the affected records' old and new value |
| Delete orphaned rows | Back up the whole rows; undoing puts them back |
| Rename a column that is still in use | Not destruction: the information survives. A plain rename back is a complete undo |
| Drop a cache or a derived column that can be recomputed | No way back needed: recompute it |

## Quick checks

1. **Run the undo in your head.** After it runs, does every record hold exactly what it held before the change? If any value comes back as a default, a blank or a guess, the change is not reversible.
2. **Play out the late discovery.** A month from now someone finds that a report still read this data. What do they do? "Undo the change" is a good answer; "restore last month's full database" is not.
3. **Play out the busy undo.** Records changed since the change ran. Does the undo leave them alone and say so, or overwrite them?
4. **Read the trail.** Someone finds the retired field or the backup with no context. Does it tell them what created it and why?

## When it applies, and when not

**Use this lens** whenever a change removes, rewrites or deletes stored information: dropping a column, field or table, rewriting values in place, deleting rows in bulk, or replacing a stored document with a new shape.

**Don't overdo it:**

- **Recomputable data needs no backup.** A cache, an index or a derived value that can be rebuilt from what remains is already recoverable.
- **Changes that never shipped can simply be redone.** A change that has only run on a developer's machine has no history to protect; fix it in place.
- **Erasure the law requires is final on purpose.** When personal data must be gone, a backup of it would defeat the point. [Data minimization](../data-minimization/README.md) wins, and that erasure runs as its own deliberate operation.
- **Keep the backup to what changed.** Copy the values the change touches, not whole tables "just in case". A backup that holds more than the undo needs is a second copy of data to look after.

## Relation to the other lenses

- [`safe-deletion`](../safe-deletion/README.md) is the user-facing sibling: it decides whether a user may remove a thing, and keeps history resolving through archive. This lens covers the changes builders make to stored data, where there is no user and no archive button, only the change and its undo.
- [`data-minimization`](../data-minimization/README.md) pulls the other way on purpose. A backup is a copy, so it holds only what the undo needs, and where erasure is required, erasure wins.
- [`single-chokepoint-per-fact`](../single-chokepoint-per-fact/README.md): a bulk rewrite is still a write. If the data has a chokepoint, a backfill that bypasses it should at least produce what the chokepoint would have, and the backup is what lets you correct it if not.
