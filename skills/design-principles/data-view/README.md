---
type: concept-explainer
title: Data View
description: 'Why every view of the data (the employee list, the employee overview, the expenses section) is produced by exactly one data view: a service that takes the actor and what the view is about, asks the on-behalf services of the entities it shows, and returns one presentation-agnostic view shape. Pages, API endpoints and assistant tools only present that view, so request handlers are one line, templates decide nothing, and what a view contains is reviewed and tested in one place. Open when building or reviewing a page or endpoint, when a request handler gathers data from several services, when a template checks roles, or when splitting a page into sections.'
---

# Data View

> **Every view of the data is produced by exactly one data view. A data view takes the actor and what the view is about, asks the on-behalf services of the entities it shows, and returns one view shape. It decides what the view contains; the on-behalf services decide what this actor may see. A page, an API endpoint or an assistant tool only presents the view, and decides nothing.**

This principle builds on [acting on behalf](../acting-on-behalf/README.md). Read that first: a data view is how a view is assembled from the on-behalf services it describes.

Start with a story. An employee's profile page shows their name and role, their salary, the expenses waiting for *your* approval, and their recent absences. The page's request handler grew one feature at a time:

- it loads the employee;
- if the viewer is in HR, it also loads the salary;
- it loads the employee's expenses, then keeps the ones where the viewer is the next approver;
- it loads absences, then works out whether to show the **Edit** button.

The template adds its own checks on top: it hides the absence notes unless the viewer is a manager. To answer "what does a manager see on this page?" a reviewer has to read the handler, four services and the template, and work out how they combine. Two of the rules (the salary, the expenses filter) are visibility rules living in a caller, which is exactly what [acting on behalf](../acting-on-behalf/README.md) forbids. And when someone builds an assistant tool that shows the same profile, the whole handler is copied.

## A view, and its presentations

A **view** is one way of looking at the data: the employee list, the employee overview, the employee's expenses. It is produced on the server, and it doesn't know how it will be shown.

A **presentation** shows a view: a page, an API endpoint, an assistant tool, an export. Several presentations can show the same view.

This flips the old dependency. The data a page received used to be shaped by the page: whatever the template needed. Now the view is shaped by what it *is*, and the page is one of its consumers. The page depends on the view; the view doesn't depend on the page.

## The rule

| Layer | Its one job |
|---|---|
| **Presentation** (a page's request handler, an API endpoint, an assistant tool) | Calls one data view and presents the result. In a request handler, one line. |
| **Data view** | Decides what this view contains: which on-behalf services to ask, with which filters, and how the answers are arranged. |
| **On-behalf services** | Decide what this actor may see and do, entity by entity. |
| **Template** | Renders what arrived. A part that is absent is not rendered. |

One thing stays with the presentation: **how a refusal looks.** Whether to refuse is the on-behalf service's decision; showing it as an error page, a redirect to another section, or a tool error is the presentation's.

Each layer has one question to answer, so each can be reviewed alone. "What is in this view?" means reading the data view. "Who may see the salary?" means reading the on-behalf service. The handler and the template have nothing to review beyond "they decide nothing".

## One data view per view

- **A view has exactly one data view, and it returns one view shape.** Name them as a pair, so each finds the other: the *employee overview* data view returns the *employee overview* view shape. The view's name says which view it is (list, overview, expenses), not where it is shown.
- **A data view is per view, not per entity.** The employee list, the employee overview and the employee's expenses are three data views with three shapes. One big "employee" shape shared by every view would mix two kinds of absence: "not in this view" and "not for this actor". The receiver could no longer tell which one it was looking at.
- **Sections are views.** When a page splits into sections (tabs), each section is its own page, with its own address, showing its own view. Looking at one section never fetches another section's data.
- **A shared frame is built once.** Sections of one page share a frame: the header, the tab bar. Build the frame in one small builder that, like a data view, only asks on-behalf services (including each section's cheap "may view" for the tab bar), and have every section's data view embed it. The frame is not a view of its own, so this is not a data view calling a data view.
- **What it takes depends on the view.** Like any action (see [acting on behalf](../acting-on-behalf/README.md)), a view takes the actor, its subject and a payload. A view of one record takes the record as its subject. A list has no subject; its query (filters, sort, page) is the payload. The view behind a creation form takes only the actor.
- **Viewing and editing are separate views.** Showing a record's values and changing them are two actions, so an edit form is its own view with its own data view, even when it is shown inside the same frame as the record's other sections. The view section offers *Edit* as an action; it doesn't turn into a form.

## A data view never decides who sees what

A data view passes the actor to the on-behalf services and never looks at the actor itself. There is no "if the actor is an admin" in a data view, ever. That is the line you check in review.

- **The view's own entity goes through its on-behalf service too.** The employee overview asks the employee on-behalf service for the employee, and gets back the salary or not.
- **Other entities are asked through their owners' on-behalf services, with filters.** "The expenses waiting for this actor's approval, the five most recent" is a query the expense on-behalf service answers. The data view chooses the slice; the expense on-behalf service decides which expenses this actor may see in it. If the filter a view needs doesn't exist, add it to the owner's on-behalf service, where every caller can use it.
- **Embed, never edit.** An on-behalf service's answer goes into the view shape as it arrived. Arranging means choosing which slices to ask for and where each answer goes in the view; it never removes or changes anything inside an answer. If the data view drops a row or blanks a field, the visibility rule has a second home, and reviewing the on-behalf service no longer tells you what the view shows.
- **Facts about the actor come from the on-behalf services as data.** Some wording depends on who is looking: "awaiting *your* approval" against "awaiting Lars's approval". The on-behalf service returns that fact ("the actor is the person themself") like any other part. The template may choose its words by it; it never hides anything by it.
- **Actions come from the on-behalf services too.** The view's actions are the action lists the on-behalf services returned (absent, available, or blocked with a reason). The data view arranges them; it doesn't invent them.

## Sections appear when their data came back

The page doesn't decide whether a section exists; it follows from the data. If the on-behalf service left the salary out, the salary card is not rendered. If a section's data view refuses the actor, its tab is not shown. There is no second list of "who sees which tab" to keep in step with the on-behalf services.

When a page has to show a section before its data has loaded (a tab label, a placeholder), it asks the on-behalf service the cheap question, "may this actor see it?", straight away, and fetches the contents later. This is **decide now, fetch later**: the answer to "is it there?" is never deferred, only the work of loading it.

## Lists fetch in batches

A list view that asks an on-behalf service once per row runs one query per row. On-behalf services that are used inside lists take many records at once, and the data view asks once for the whole page of rows.

## What you get for it

- **Each question has one place.** What the view contains: the data view. Who may see it: the on-behalf services. How it looks: the presentation. A handler or template that decides anything is a review finding.
- **A new presentation costs nothing.** An assistant tool or an API endpoint that should show the employee overview calls the same data view the page calls. Nothing is copied, and every rule comes along.
- **Tests split cleanly.** A data view's test checks the composition: that the overview asks for the five most recent expenses awaiting approval, and arranges the answers right. Visibility is tested once, in the on-behalf services, not again in every view that shows the entity.

## Quick checks

1. **Count the calls in the handler.** More than one call, or any condition? Then the handler is assembling or deciding, and that belongs in the data view.
2. **Search the data view for the actor.** Does it ever look at the actor's role or relationship instead of just passing the actor on? Then a visibility rule has leaked out of an on-behalf service.
3. **Search the template for permissions.** Any role or permission check in a template is a rule the on-behalf services should have applied.
4. **Ask what a manager sees.** Can you answer it from the data view plus the on-behalf services it calls, without opening the handler or the template?
5. **Compare an on-behalf service's answer with the view.** Does the view contain exactly what the on-behalf service returned, or did the data view filter or blank something on the way?
6. **Read the view's name.** Does it say what the view is (overview, list), or where it is shown (page, screen, tool)? Only the first survives a second presentation.

## When it applies, and when not

**Use this lens** for every view of stored data that something presents: lists, record views, sections, forms that are filled in with existing values.

**Don't overdo it:**

- **Not every caller needs a view.** An API endpoint or an assistant tool that wants one entity, not a composed view, calls that entity's on-behalf service directly. A data view earns its place when several on-behalf services' answers are put together.
- **A data view is not a second on-behalf service.** Logic that belongs to an entity (its rules, its visibility, its available actions) goes into that entity's on-behalf service or base service, where every caller gets it.
- **Data views don't call data views.** A part that several views show is an on-behalf service method (or a filter on one), not a nested data view. One level of composition keeps "what is in this view" readable in one file.

## Relation to the other lenses

- [`acting-on-behalf`](../acting-on-behalf/README.md) is the foundation: the on-behalf services decide what an actor may see and do, and a data view composes their answers into a view. A data view without on-behalf services is the old request handler with a new name.
- [`detachable-domain`](../detachable-domain/README.md): a data view reaches other domains only through their on-behalf services, and owns none of their rules.
- [`deep-modules`](../deep-modules/README.md) and [`data-minimization`](../data-minimization/README.md): a data view and its view shape live on the public surface of the module that owns the entity the view is about: the employee overview lives in the employee module. A view is never a reason to create a module; neither is a page that presents it. A view fetches what it shows and nothing more.
