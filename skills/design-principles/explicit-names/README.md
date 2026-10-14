---
type: concept-explainer
title: Explicit Names
description: 'Why every variable, property and method is named so that one line, read on its own, says what happens: a variable is named after the type it is declared as (with its role in front when two share a type), a method starts with its action and names what it acts on, and length is never a reason to shorten a name. The point is to cut how much code anyone, person or agent, must read to understand a line. Open when naming anything, when reviewing a diff, or when a line only makes sense after scrolling to a constructor or opening another file.'
---

# Explicit Names

> **A name says exactly what the thing is, and a method's name says what it does. A variable or property is named after the type it is declared as; a method starts with its action and then names what it acts on. Length is never a reason to shorten a name: one line, read on its own, should tell you what happens.**

Start with a story. A reviewer reads one changed line in a diff:

```text
balances.summary(actor, person)
```

Is `balances` a list of balances, or something that fetches them? Does `summary` read a summary, build one, or store one? Who is `person`, and is `actor` the same kind of thing? To answer, the reviewer scrolls up to the constructor to find what `balances` is, opens that class to see what `summary` does, and follows `person` back to where it was set. Three files to understand one line. An agent working through the same code pays the same price, out of a context that is far smaller than the codebase.

Now the same line, named explicitly:

```text
employeeBalanceAccessService.getBalanceSummary(actor, viewedEmployee)
```

It is a service, it reads, it returns a summary of a balance, and the balance belongs to the employee being viewed. Nothing else needs to be opened to know what the line does.

## Why: read less to understand more

Most of the cost of code is reading it. Every name that hides what it stands for sends the reader somewhere else to find out: to a declaration, a constructor, a class, a call site. Each of those trips costs attention for a person and context for an agent, and the cost repeats for every reader, every time.

An explicit name pays that cost once, when the code is written. The reader of a single line, a diff, a stack trace or a search result gets the meaning where they already are. The less code you need to read to understand a line, the more of the codebase anyone can safely change.

Typing a long name costs nothing that matters: editors complete it, and code is read far more often than it is written.

## The rules

### 1. A variable or property is named after the type it is declared as

```text
✗  approvals, service, svc, repo, data, items
✓  expenseApprovalService, expenseRepository, pendingExpenses
```

A collection is named after what it holds (`pendingExpenses`, not `list` or `results`). A plural noun is for a collection only; a service named in the plural (`approvals`) reads like a list.

The type is the **declared** one. When a parameter accepts any kind of thing behind an interface (an actor who may be a person, an API token or a scheduled job), the name follows the interface (`approvingPrincipal`), not a concrete kind the value happens to be today. Naming it after one concrete kind would claim something the code doesn't promise.

### 2. When two share a type, the role goes in front

```text
✗  mayApproveExpense(employee, employee2, expense)
✗  mayApproveExpense(approver, submitter, expense)
✓  mayApproveExpense(approvingEmployee, submittingEmployee, expense)
```

The role alone (`approver`) says which one, but not what it is. The type alone says what it is, but not which one. Together they say both.

### 3. A method starts with its action, then names what it acts on

```text
✗  summary(), for(), devices(), openOf(), balance()
✓  getBalanceSummary(), buildOverviewView(), listDevices(), listOpenExpenses(), removeDevice()
```

A bare noun hides whether the method reads, builds, changes or deletes. The verb says which, and the noun after it says on what. A question answered with true or false starts with `is`, `has`, `may` or `can`: `mayApproveExpense()`, `isArchived()`.

Use the same verb for the same kind of action across the codebase, so the verb itself carries meaning: `get` returns one thing, `list` returns several, `build` assembles a new value without storing it, `create`, `update` and `remove` change stored data.

### 4. No abbreviations

```text
✗  emp, tx, cfg, amt, cu
✓  employee, transaction, configuration, amount
```

An abbreviation is a name the reader has to decode. The few that every reader of the code already knows as words (`id`, `url`) are fine.

## Quick checks

1. **One line**: cover everything but one line. Can you say what it does, to what, and what comes back?
2. **No trip**: did understanding the line need a jump to a declaration, a constructor or another file? The name that sent you there is the one to change.
3. **The verb**: does every method name start with an action? Would `get`, `build` or `remove` in front make it clearer?
4. **The plural**: is every plural name a collection?
5. **Two of a kind**: where two values share a type, does each name carry both the type and the role?

## When it applies, and when not

**Use this lens** when naming anything new, when reviewing a diff, and whenever a line only made sense after you read somewhere else.

**Don't overdo it:**

- **A tiny scope can be short.** A loop index or a one-line lambda's parameter, whose whole life fits on the screen beside its use, needs no long name: `for each expense in pendingExpenses` is already explicit.
- **Don't repeat the namespace in a class name.** This lens is about the names of variables, properties and methods. A class's own name describes what the class is, and its module belongs in its namespace (see [deep modules: naming and placement](../deep-modules/naming-and-placement.md)). A variable holding that class still carries its full name.
- **Renaming is a change like any other.** Apply the lens to code you write or touch, not as a sweep through code nobody is working on.

## Relation to the other lenses

- [`deep-modules`](../deep-modules/naming-and-placement.md): its naming page decides what a *class* is called and where it lives. This lens decides what the *variables, properties and methods* that use the class are called. The two meet in one place: a property holding a class is named after that class.
- [`acting-on-behalf`](../acting-on-behalf/README.md): an action's name is the method's name. When the method starts with the action, the action a reviewer checks permissions for is the one written in the call.
- [`data-view`](../data-view/README.md): a data view is named after what the view is, and its build method says that it builds it, so a call reads as the view it produces.
