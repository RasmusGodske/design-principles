---
type: concept-explainer
title: Concept Families
description: 'Why alternative ways of doing the same job are grouped into a named family and written down together: the next person adding a way finds the others first, and everyone uses the same words. Covers what a family is, how members are named, families of one, unnamed families, outliers, reshaping, and where a family is written down. Open when adding a new way to do something that can already be done, a second variant of anything, or when you find yourself listing several things that do the same job.'
---

# Concept Families

> **Every new way of doing something starts a family or joins one. Know which, and write the family down: its name, each member's name, and what each member does that the others don't.**

Imagine a product where reports can be exported. Over a year, three developers each add an export, without knowing about the others:

- a spreadsheet download, called "Download"
- a printable version, called "Print view"
- a data feed for other systems, called "API dump"

Each has its own name, its own button and its own settings. When a customer asks "can I get a PDF?", nobody connects that to "Print view". When a fourth developer is asked for a calendar export, there is no pattern to follow, so they build a fourth one-off.

All three are the same kind of thing: ways to export a report. Name that once and write it down:

```text
Export formats
| Member      | What it gives               | Used for           |
| CSV export  | one row per line            | spreadsheets       |
| PDF export  | the report as a document    | printing, sending  |
| JSON export | the full report as data     | other systems      |
```

Now the calendar export has an obvious place: a fourth row that works like the other three. And when a customer asks for a PDF, everyone, from support to the developers, knows it as "PDF export".

## Why

People understand a system in groups. "Three ways to get data out" fits in a head; fifteen unrelated feature names do not. A named family gives developers, reviewers and the people talking to customers the same words.

It tells you when to stop looking. Someone searching the documentation for a PDF export who finds an "Export formats" section without it knows at once that there is none. Without the family, they would have to read everything to be sure. Code works the same way: a complete list of members turns "not there" into an answer, so you can stop searching and decide to build it. This only works if the list is complete, which is why rules 5 and 6 ask for every member, outliers included.

It also improves the code. To place a new way in a family, you have to look at the existing ways and say how yours differs. That is when a one-off becomes visible: it either joins and follows the family's shape, or it is genuinely new and gets its own name.

## The rules

### 1. Start or join

Before building a new way to do something, ask: *is there already a way to do this job?*

- **Yes: join.** Use the family's names, add your member to its table, and follow the shape the others share.
- **No: start.** Name the family and your member, even if it is the only one.

### 2. A family answers one question

Its members are different answers to the same question, and someone will choose between them again.

- **Question test:** "How is it exported?" CSV, PDF, JSON. "How is the person notified?" Email, text message, push.
- **Listing test:** if you would naturally list them together, they are probably a family.

If something seems to fit two families, two questions are mixed. A report that "runs nightly" answers *when does it run?* (on demand, scheduled, on an event) and *how much does it cover?* (what changed, or everything). It is one member of each family, not a new member of either.

### 3. Name members with the family's noun

```text
✗  csv, pdf, push
✓  CSV export, PDF export, push notification
```

The name alone should tell you which family it belongs to. Use the words the business already uses, and choose names most people would agree with.

### 4. A family of one is a name and a table

Write a one-row table and one line on what the family is for. Build shared code only when a second member arrives, or when one is already planned. In that case, design the family properly now.

### 5. Name an unnamed family in full

If the family exists but was never named, write down every member when you add yours, not only your own. You have just compared them, so you are best placed to do it.

### 6. List the outliers

Some code predates the family or follows it only partly. List it under the family with the reason, so nobody copies it by mistake. Code you touch moves into the family.

### 7. Reshape when you learn more

Families are discovered, not designed once. Two separate things can turn out to be one family. A product built around *companies* and *job listings* may find that job listings and a later website scraper are both **enrichment sources** for companies. A family can also turn out to mix two questions and need splitting.

Update the table and names in the same change, and keep old names as "formerly called …" so older code and notes still make sense. Rename identifiers in code when you touch that code.

### 8. Write it where the next person will look

1. **Members sit together** (one module or directory): put the table in that directory's README, under the family's name.
2. **Members are spread out:** put the table in the family's natural home, and give each member a short note pointing to it.
3. **Users choose between members:** also put it in the product documentation, using the same names.

Keep one table per family. Everything else links to it.

## Quick checks

1. Which question does the new thing answer, and does a family already answer it?
2. Would you mention it in the same sentence as something that already exists?
3. Does its name include the family's noun?
4. Does the table say what it does that the others don't?
5. Does it seem to fit two families? Then two questions are mixed.

## When it applies, and when not

**Use it** when adding a new way to do something, a second variant of anything, or when you catch yourself listing several things that do the same job.

**Don't overdo it:**

- **States are not a family.** An order's statuses are stages of one thing; nobody chooses between them.
- **Private helpers are not a family.** Nobody picks between them.
- **A family need not exist in code.** Good abstractions often show it, but never add a type only to make a family visible.
- **Apply it to what you build or touch**, not as a sweep through untouched code.

## Relation to the other lenses

- [`explicit-names`](../explicit-names/README.md) names variables and methods; this lens names concepts and ways of doing things. They meet where a member's name becomes an identifier.
- [`deep-modules`](../deep-modules/README.md): its variants are a family in the file tree, and it already asks you to "name the variant axis cleanly". This lens asks for the name earlier, as words and a table rather than structure.
- [`framework-and-implementation`](../framework-and-implementation/README.md): shared code grows on evidence. A family of one is a name, not early shared code.
- [`single-chokepoint-per-fact`](../single-chokepoint-per-fact/README.md): one place writes each fact; here, one table holds each family.
- [`documentation-placement`](../documentation-placement/README.md) and [`discoverable-knowledge`](../discoverable-knowledge/README.md) decide where the table lives and that it can be found.
- [`config-and-record`](../config-and-record/README.md) settles a family of two for every entity. This lens is the general form.
