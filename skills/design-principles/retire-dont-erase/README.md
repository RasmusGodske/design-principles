---
type: concept-explainer
title: Retire, Don't Erase
description: Read before writing a database migration that drops a column or table, deletes rows, or rewrites existing data. Don't delete — retire the column or table (rename it, keep the data), and back up existing values before rewriting them, so the migration can always be rolled back with the data intact.
---

# Retire, Don't Erase

> **Don't drop a column or table in a migration — retire it. Before a migration changes existing data, back up the values it changes. Always leave yourself a way back.**

## Why

Dropping a column feels safe when nothing seems to read it. But sometimes something does: a report, an export, a job nobody remembered. Once the migration has dropped the column, the data is gone, and rolling back gives you an empty column at best.

Retiring instead costs almost nothing and keeps the way back open.

## When to read this

Whenever a migration:

- drops a column or a table,
- rewrites values in existing rows (fixing data, changing a format, merging one field into another), or
- deletes rows.

## Removing a column or table: retire it

Rename it with a `retired_` prefix instead of dropping it, for example `delivery_method` → `retired_delivery_method`.

- The data stays where it is.
- Code that still uses the old name fails loudly, so you find out instead of silently getting nothing.
- Rolling back is just renaming it back.

Drop the retired column later, in a separate migration, once you're sure nothing needs it. How long to wait is your call.

## Changing existing data: back it up first

Before the migration changes existing rows, copy the values it is about to change into a backup table made for that migration. Store both the old value and the new one. When rows are deleted, back up the whole row.

- Rolling back copies the old values back.
- Only restore rows that still hold the new value. If a row has changed since the migration ran, stop and report it instead of overwriting that later change.

## Two rules for the way back

- **Rolling back restores the data, not just the column.** A column that comes back empty or filled with a default is not a rollback.
- **Leave a note.** Every retired column or table, and every backup table, gets a comment saying which migration created it and why. Someone who finds it a year later should understand it without asking anyone.

## When you don't need this

- The data can be recalculated, like a cache or a derived value.
- The migration has never run anywhere but your own machine. Just fix it.
- The law requires the data to be erased. Then erase it.

## Related

- [Safe deletion](../safe-deletion/README.md) is about what *users* may delete. This one is about what *migrations* delete.
- [Data minimization](../data-minimization/README.md): a backup is a copy of data, so keep only what the rollback needs.
