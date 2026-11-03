---
type: concept-explainer
title: Concept Families
description: 'Why every new way of doing something either starts a family or joins one: alternative ways to do the same job are grouped, named, and written down together, so the next person adding a way finds the others first and everyone, in code and in conversation, uses the same words. Covers what counts as a family (the same question, answered differently; things you would list together), how members are named, a family of one, unnamed families, outliers, reshaping a family, and where the family is written down. Open when adding a new way to do something that can already be done, a second variant of anything, a new kind of page, export, notification or sync, or when you catch yourself listing several things that do the same job.'
---

# Concept Families

> **Every new way of doing something either starts a family or joins one. Know which you are doing, and leave the family named and written down where the next person will look: the family's name, every member's name, and what each one solves that the others do not.**

Start with a story. A product can export a report as a spreadsheet. A year later someone adds a printable document export, and later still a third developer adds a data export for other systems. Each was built by someone who did not know about the others. The spreadsheet one is called "download", the document one "print view", the data one "API dump". Each has its own button in a different place, its own settings, its own way of choosing which rows go in.

A customer asks "can I get this as a PDF?" and support has to find out that the answer lives under "print view". The fourth developer, asked for a calendar export, cannot tell whether there is a pattern to follow, so they add a fourth one-off. Nothing was wrong in any single change; what is missing is that nobody ever said "these are **export formats**, and here they are side by side".

Now the same history, with the family named the first time:

```text
Export formats            (reports/README)
| Format       | What it gives                    | Used for                 |
| CSV export   | one row per line, for a sheet    | analysis in a spreadsheet |
| PDF export   | the report as a document         | printing, sending on     |
| JSON export  | the full report as data          | other systems            |
```

The second developer finds the table and adds a row instead of a new button somewhere else. The customer's question has an answer in their own words. The developer asked for a calendar export knows exactly where it goes, and that it should look like the others.

## Why: groups are how people think and talk

People understand a system by grouping it. "There are three ways to get data out" is something a person can hold in their head; fifteen separately named features are not. A named family gives everyone the same handle: developers building the next member, a reviewer reading the change, the person explaining the product to a customer. When a reader meets one member they can be shown its siblings, and when someone adds a member they can see at once whether it is "a new alternative like the others" or "something that solves what the others do not".

It also changes how code gets written. A developer who has to place a new way into a family has to look at the existing ways first and say how theirs differs. That is the moment a one-off becomes visible: either it joins and follows the family's shape, or it is honestly something new and gets its own name. Code that has been grouped by what it does is easier to explain and easier to extend, the same way a codebase with a predictable file structure is easier to navigate.

## The rules

### 1. Know whether you are starting a family or joining one

Before building a new way to do something, ask: *is there already a way to do this job?*

- **Joining**: there is. Find the family, use its names, add your member to its table with what yours solves that the others do not, and follow the shape the others share.
- **Starting**: there is not. Name the family and your member anyway, even as a family of one, so the second way has a place to join.

### 2. A family is the alternative answers to one question

Members of a family are different ways to do the same job, and someone will choose between them again: a developer building the next feature, or a user picking an option. Two tests:

- **The question test.** Name the family after the question its members answer. "How is the data exported?" (CSV, PDF, JSON). "How is the person notified?" (email, text message, push notification). If your new way answers a different question, it belongs to a different family.
- **The listing test.** If you would naturally list them together ("you can export as CSV, PDF or JSON"), or a reader of one would want to be shown the others, they are probably a family.

When one thing seems to belong to two families, there are probably two questions mixed into one. A report that "runs nightly" answers *when does it run?* (on demand, on a schedule, on an event) and *how much does it cover?* (only what changed, or everything). Those are two families, and the nightly report is one member of each, not a new member of either.

### 3. A member's name is its distinguishing word plus the family's noun

```text
✗  csv, pdf, json                       (on their own, about what?)
✓  CSV export, PDF export, JSON export
✓  email notification, push notification
```

The name alone should say which family a member belongs to, so whoever hears it in a conversation or reads it in a log knows there are alternatives and where to find them. Prefer the words the business already uses for the thing over technical ones, and a name most people would agree with. The developer picks the names; the aim is that others recognise them, not that someone signs them off.

### 4. A family of one gets its name and its table

The first member of a family gets a one-row table and a line saying what the family is for. That is all it needs, unless a second member is already known to be coming. If it is (the second export format is already planned), sit down now and design the family properly, including whatever the members will share. If there is no sign of a second member, build only the one you need; the shared parts wait for the second member, who will show what is really shared.

### 5. Joining a family nobody named means writing the whole family down

Often the family already exists but has never been named: two export formats live in the code, each documented on its own, if at all. When yours arrives, write down the whole family, the existing members and yours. You are the one who just compared them, so you are the person best placed to name them.

### 6. Outliers are listed, with the reason

Real code rarely follows its family completely. Some members predate the shared shape; some follow it partly. List them under the family as not yet following it (or following it only partly), with why, so the next developer does not copy an outlier by mistake. Code you touch moves into the family.

### 7. A family is reshaped when understanding changes

Families are found, not designed once. Two things that started as separate turn out to be members of one family; a family turns out to mix two questions and splits in two. A product that began with *companies* and *job listings* as two separate things may find that job listings, together with a later website scraper, are really two **enrichment sources** for companies.

When you see it, reshape the family's table and names in the same change. Keep the old names as "formerly called …" so older code and notes can still be followed. Identifiers in code are renamed when that code is touched, or in a change of their own.

### 8. Write the family down where the next person will look

First match wins; the third is added to the other two:

1. **Its members sit together** (one module, one directory): the family's table goes in that directory's README or doc, under a heading with the family's name.
2. **Its members are spread out** (pages of the same kind in different folders): the table goes in the family's natural home, and each member carries a short note pointing to it, so a reader of one member can find the rest.
3. **The family reaches the users** (export formats a customer chooses between): write it in the product documentation too, with the same names as in the code, so customers, support and developers use the same words.

There is one table per family; everything else points to it rather than copying it.

## Quick checks

1. **Which question?** Can you name the question your new thing answers, and does a family already answer it?
2. **Would you list them?** Is there something you would naturally mention in the same sentence as your new thing?
3. **The name alone**: does your member's name carry the family's noun?
4. **What it solves**: does the family table say what your member solves that the others do not?
5. **Two questions?** Does your new thing seem to belong to two families at once? Then you have probably found two families.

## When it applies, and when not

**Use this lens** when adding a new way to do something, a second variant of anything, a new kind of page, export, notification, integration or sync, and whenever you catch yourself listing several things that do the same job.

**Don't overdo it:**

- **The states of one thing are not a family.** An order's statuses (draft, placed, shipped) are stages of one thing, not alternative ways to do a job; nobody chooses between them.
- **Internal helpers are not a family.** Two private functions inside one service are not alternatives anyone picks from.
- **A family does not have to exist in code.** It lives in its names and its table. Good abstractions often show a family on their own (an interface with its implementations, a set of variants in a directory), but never add a type only to make a family visible.
- **Naming is a change like any other.** Write down the families you build in or touch, not a sweep through code nobody is working on.

## Relation to the other lenses

- [`explicit-names`](../explicit-names/README.md) names the variables, properties and methods in a line; this lens names the concepts and the ways of doing things. They meet where a member's name becomes an identifier: a class called after the member ("PDF export") reads the way people talk about it.
- [`deep-modules`](../deep-modules/README.md): its variants are a family laid out in the file tree, and it already asks that you "name the variant axis cleanly" before promoting. This lens is the same habit for concepts that are not variants of one module, and it asks for the name even before the second variant exists, as words and a table rather than structure.
- [`framework-and-implementation`](../framework-and-implementation/README.md): shared code grows only on evidence, and this lens agrees. A family of one is a name and a table, never early shared code; the shared parts wait for the second member, or are designed now when a second member is already known to be coming.
- [`single-chokepoint-per-fact`](../single-chokepoint-per-fact/README.md): one place writes each fact. Here, one table holds each family, and everything else points to it.
- [`documentation-placement`](../documentation-placement/README.md) decides that a family's table lives beside the code it describes, and [`discoverable-knowledge`](../discoverable-knowledge/README.md) that it can be found from there: under a heading with the family's name, reachable from the doc that hosts it.
- [`config-and-record`](../config-and-record/README.md) is a family of two settled once for every entity: each is either authored configuration or a context-bound record. This lens is the general form of that move, for any number of members.
