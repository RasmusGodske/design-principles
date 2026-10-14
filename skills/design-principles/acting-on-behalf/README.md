---
type: concept-explainer
title: Acting on Behalf
description: 'Why every read and write an actor asks for — done on behalf of a principal (whose permissions apply) and performed by a performer (a user, an impersonating administrator, an API token, an assistant, a job) — should pass through one thin layer that acts on their behalf, deciding what this actor may see and do, over services that do not know who is asking. Open when deciding where a "who may see / who may do" rule goes, when adding a second way into the same data (an API, an assistant), when a page hides a field or a button by role, when deciding what gets audited, or when reviewing a controller that decides visibility.'
---

# Acting on Behalf

> **Every read and write an actor asks for goes through one thin layer that acts on their behalf. It decides what this actor may see and do, then calls services that do not know who is asking. Nothing else decides it: not the request handler, not the page, not the API endpoint.**

That layer is the **on-behalf service**. The services behind it are **base services**.

Start with a story. An HR system shows employee profiles. The salary is visible only to HR and to the employee's own manager. The rule lives in the profile page's request handler: *if the viewer is HR or the manager, include the salary.*

A year later two new ways in arrive: an API for a payroll integration, and an assistant that answers questions about colleagues. Both load the employee through the same service the page uses, and neither has heard of the rule, because the rule was never in the service. It was in one of three callers. The salary is now readable by anyone with a token. Nothing on the page changed, and the page's tests still pass.

Writes go wrong the same way. The **Approve** button on an expense is shown only to the approver. The approve endpoint checks that the expense is pending, but not who is asking. Anyone who sends the request directly approves it.

In both cases the rule existed, but it lived in a *caller*. A rule about who may see or do something has to live where *every* caller passes through.

## Actions, subjects and payloads

Everything an actor does is an **action**: one named thing a service lets you do, such as *list employees*, *open an employee's overview*, *grant access*. An action runs **on** something, its **subject**: the record it is about (*this* employee), or nothing for actions like *list employees*. The caller names the subject separately, by its address or its id, and it reaches the on-behalf service as its own argument. Everything else the caller supplies (filters, a page number, the form's values) is the action's **payload**, so a payload never needs to say which record it is for. The action returns a **result**. Reads are actions too; their result is what the actor gets to see.

> run *grant access* (the action) **on** employee 42 (the subject) **with** { role: manager } (the payload)

Every way in carries the same three parts, only packaged differently, and hands them to the on-behalf service unchanged:

```
a page:            POST /employees/42/access        body: { role: "manager" }
an assistant tool: grant_access { id: 42,           payload: { role: "manager" } }
at the on-behalf service: grantAccess(actor, employee 42, { role: "manager" })
```

## Who is the actor

Every action is done **on behalf of** someone: the **principal**, whose permissions apply. Usually it is also **performed by** them. When it isn't, the **performer** is recorded beside the principal:

| Situation | Performed by | On behalf of |
|---|---|---|
| A user edits their own profile | the user | the user (the usual case) |
| An administrator impersonates a user | the administrator | the user |
| A user's API token syncs data | the token | the user who made it |
| A user's assistant files an expense | the assistant | the user |
| A nightly sync you want audited | the job | the system itself |

The on-behalf service takes both as one value, the **actor**: *on behalf of* (the principal) plus *performed by* (the performer, which defaults to the principal). An application that never impersonates anyone still passes the pair, and the day it needs to, nothing changes shape.

**Whose rules apply.** The principal's, narrowed by the performer's own limits. An administrator impersonating a user sees exactly what that user sees. A token can do what its owner can, minus anything the token wasn't granted. The audit trail records both: "the token did this, on behalf of Anna".

**Both are open types.** Anything can be a principal or a performer, as long as it can say what kind it is and how to find it again: a user, a member of a tenant, the system itself, a named job. A row is found again by its id; something that has no row, such as a job, by a stable key. A performer is usually only recorded, so a reference is enough. The principal is what the rules ask questions of ("is this an administrator?"), so the on-behalf service needs it in a form it can ask.

**Each on-behalf service states which kinds of principal it supports, and refuses the rest loudly.** An action that only makes sense for a person says so in its first line, and a job asking for it fails instead of slipping through. Supporting a new kind of principal means writing that kind's rules into the on-behalf service; nothing behind the on-behalf service changes.

**Whether something is an actor at all is a choice, made visibly.** Anything whose access you want to control, or whose actions you want to be able to audit, acts through the on-behalf service. Code you decide not to control or audit, such as a migration or test setup, calls the base service directly, and that decision is written down where a reviewer will see it.

## Two layers

| | What it knows | Who calls it |
|---|---|---|
| **Base service** | What the system can do, and the rules about the record itself: "a paid expense can't be changed" | The on-behalf service, and code you have deliberately decided not to control or audit: a migration, test setup |
| **On-behalf service** | What *this actor* may see and do with it: "only the approver may approve" | Every actor: pages, API endpoints, assistants, command-line tools, and system jobs you want audited |

The base service is the owning service from [detachable domain](../detachable-domain/README.md): the only code that touches the entity's stored records. This lens does not replace it. It adds one rule on top: when an *actor* is asking, the caller goes through the on-behalf service in front of it.

The on-behalf service is not a second implementation. It never writes data itself, and it holds no business rules about the record. It checks, then delegates.

## What the on-behalf service does: three steps

1. **Check the actor.** May they open this record at all? If not, answer *not found*, exactly as if it didn't exist, so the answer doesn't confirm that it does. May they take this action? If not, refuse.
2. **Pass the actor's limits down.** Tell the base service which rows this actor may see and which parts to load. What they may not see is never fetched, so it can never leak, and it costs nothing. Each part the on-behalf service may withhold is an explicit argument to the base service, named for what it adds (*include the sign-in status*: yes or no) and with no default value, so adding a part forces every on-behalf service to decide it.
3. **Delegate.** The base service does the work and applies the record's own rules.

That is all. Because every actor passes these three steps, this is also the one place where recording who looked at or changed what can be added, when it is needed.

An on-behalf service with queries of its own, or with rules about the record, has started growing a second definition of the domain.

**A cheap question beside every answer.** A page often needs to know only *whether* a section exists (to show a tab), not what is in it. So an on-behalf service offers a check that answers without loading anything, such as "may this actor view it?", beside the methods that return data.

**On-behalf services may build on the on-behalf service of what they belong to.** An employee's expenses belong to the employee, so the expense on-behalf service's first check can be the employee on-behalf service's "may view". The rule for opening the employee then exists once.

**Existing permission helpers are inputs, not the on-behalf service.** A system often already has helpers such as "which rows may this user see". The on-behalf service may use them, but it owns the rule. When the on-behalf service's rule is stricter than the helper's (the helper lets managers see balances; the on-behalf service says administrators only), the on-behalf service states the stricter rule and still applies the helper, so the two can only narrow each other.

## Actor rules and record rules

The line between the two layers is one question: **does the answer depend on who is asking?** That includes the asker's relationship to the record ("is the next approver", "manages this employee"): those are about who is asking, so they are actor rules, even though the record is needed to answer them.

| Rule | Depends on who asks? | Lives in |
|---|---|---|
| "Only HR and the manager see the salary" | Yes | On-behalf service |
| "Only the next approver may approve" | Yes | On-behalf service |
| "A paid expense can't be recalculated" | No, nobody may | Base service |
| "An archived employee can't be assigned new work" | No | Base service |

A rule that would stop every actor equally, even one permitted everything, is a record rule, and it belongs below the on-behalf service. If an actor can do something a rule should have stopped, an actor rule is sitting in a caller.

## Reads: the shape is an allowlist, and hidden means absent

The on-behalf service returns a **data shape**: a typed description of what is sent (a data class, a typed object, a schema), never the stored record itself.

**The data shape is the same for every actor.** It lists everything that could *ever* be shown about the record, and it marks the parts that some actors don't get as *possibly absent*. A new column on the stored record reaches no one until someone adds it to the shape on purpose. That is the allowlist.

**The on-behalf service fills the shape for one actor.** A part this actor may not see is left out entirely. It is not sent as empty.

**Hidden and empty must look different.** "No salary recorded yet" and "you may not see the salary" are different answers. If both arrive as an empty value, a page will tell an employee "No salary recorded yet" about a salary that exists. That is false, and it tells them there is something there. Absent means hidden; empty means empty.

**Counts, sorting and search see only what the actor sees.** "12 expenses awaiting approval" counts the expenses this actor may see, not all of them. Never let an actor sort, filter or search by a part they may not see: sorting employees by salary reveals the salary order even when no salary is shown.

**Adding a part forces a decision.** Build the shape so that the on-behalf service cannot be compiled, or cannot pass its tests, without saying who gets the new part. A new part should never be visible to every actor just because nobody decided otherwise.

## Actions: absent, available, or blocked with a reason

An actor needs to know what they can do, not only what they can see. Permissions belong to **actions**, never to individual fields. What counts as one action is the service designer's choice: one action per field for fine-grained control, or one "update employee" that changes several fields at once. This lens only says that whatever the actions are, each is permitted or not as a whole.

The on-behalf service returns the actions too, one entry per action, each under its own key:

| State | When | The actor sees |
|---|---|---|
| **Absent** | They are not permitted | Nothing. No disabled button and no "no permission" note, because either would tell them the action exists. |
| **Available** | Permitted, and the record allows it | The action |
| **Blocked** | Permitted, but the record's state doesn't allow it right now | The action, disabled, with the reason: "Paid expenses can't be recalculated" |

The reason is a stable code plus a sentence for people. The code is what tests and machine callers act on; the sentence is what a tooltip shows.

**The blocked reason and the refusal come from one function.** The base service has one place that answers "is anything stopping this action, and why?". The on-behalf service calls it to fill the action list. The base service calls it again before it does the work. The tooltip and the actual refusal can't disagree, because they are the same answer.

## Writes: the on-behalf service refuses the same way

When an actor asks to change something, the on-behalf service checks before delegating:

- **May not open the record at all:** answer *not found*, as for reads.
- **May open it, but not take this action:** refuse with a plain "forbidden" and no detail, the same way the action was absent.
- **Blocked:** refuse with the same reason the action list showed.

A request sent directly, skipping the page, gets exactly the answer the page would have given.

**The on-behalf service checks the action the actor asked for, not everything it causes.** If approving an expense also books a payout, the actor needs permission to *approve*. Booking the payout is the base service's work, done as part of approving.

**The input goes to the on-behalf service as it arrived.** The request handler doesn't build, reshape or trim what the actor sent; it passes it to the on-behalf service as the action's typed payload. That is what lets the same action be a page form, an API call or an assistant tool without any changes.

## The actor is passed, never looked up

The on-behalf service takes the actor as an explicit argument. It never reads "the current user" from ambient request state.

Jobs, assistants and command-line tools have no request, so an ambient lookup either finds nobody and lets everything through, or finds the wrong actor. A tool that shows an admin what a sales rep would see is performed by the admin *on behalf of* the sales rep. It must say so explicitly, not borrow whoever happens to be signed in. A scheduled job that is an actor passes itself as the performer.

## Build it with the first page, even when everyone sees everything

A page where every actor sees the same thing still gets an on-behalf service. Today the on-behalf service checks that the actor may open the record and passes everything through, which is a few lines. The day the first part becomes restricted, or the first change needs to be audited, the place already exists and every caller already uses it. Without it, that day starts with finding every caller.

This is the same economics as [single chokepoint per fact](../single-chokepoint-per-fact/README.md): the code is being written today either way. The only question is whether it is written in a findable place.

## What you get for it

- **One place to review and test who sees and does what.** "Who can see the salary?" is answered by reading one function, and tested with one table of actors (admin, manager of this employee, manager of someone else, the employee themself, an API client) times what each one gets. No browser, no request handler. Build the table of actors once and share it across every on-behalf service's tests; then each new on-behalf service's test is a loop, not a setup.
- **New ways in are safe by default.** An API endpoint or an assistant tool calls the same on-behalf service the page calls, and inherits every rule.
- **Auditing has a home.** Every read and write an actor causes passes one layer, so recording it, if you ever need to, is added there once.

## Quick checks

1. **Find the rule.** Pick a restricted part. Can you name the one function that decides who sees it? If the answer involves a template or a request handler, the rule is in a caller.
2. **Add a caller.** Imagine a new API endpoint or assistant tool for this record. Does it get the rules for free, or would someone have to remember to copy them?
3. **Skip the page.** Send the write request directly as an actor who never sees the button. What happens?
4. **Permit everything.** Give an actor every permission. Is it still stopped by something in the on-behalf service? Then a record rule is in the on-behalf service.
5. **Look for side doors.** Pick a write. Does every path an actor can trigger go through the on-behalf service, or does one reach the base service without anyone having decided it should?
6. **Read an empty value.** Can the receiving side tell "hidden" from "empty"?
7. **Check the layer in front.** Is there a platform permission list in front of the on-behalf service (route permissions, middleware)? It must allow at least what the on-behalf service allows, or the on-behalf service's answer never reaches the actor, and you have a second list of who sees what.

## When it applies, and when not

**Use this lens** whenever what an actor may see or do depends on who they are or on their relation to the record, whenever you need to know who did something, whenever there is, or will be, more than one way in (pages, API, assistants), and whenever a review asks "who can see this?".

**Don't overdo it:**

- **Skipping the on-behalf service is a decision, not an accident.** Code you deliberately don't control or audit, such as a migration or test setup, may call the base service directly. Make that choice visible. A path that skips the on-behalf service because nobody thought about it is a back door.
- **The on-behalf service is thin.** Business rules in the on-behalf service are skipped by everything that calls the base service directly.
- **One on-behalf service per entity, not one for the whole system.** Each domain owns the on-behalf services for its own entities. Split an on-behalf service by concern (reading, approving, sharing) when it grows.
- **Ambient filters are a safety net, not the on-behalf service.** A global "only show this user's rows" filter can stay as a second line of defence, but it reads the user from ambient state, so the on-behalf service must not depend on it.

## What this lens does not decide

- **What a write returns.** The updated record, a reference to the work started, nothing at all: that depends on the action.
- **Whether a base service returns stored records or data shapes.** That is [detachable domain](../detachable-domain/README.md)'s question. This lens only requires the *on-behalf service* to return an explicit data shape.
- **What gets audited.** Reads, writes, both or neither. This lens gives auditing one place to live; it doesn't require it.
- **Whether an action's consequences go through another on-behalf service.** (An on-behalf service building its first check on the on-behalf service of what it belongs to is fine; see above.) When an action also changes another entity, this lens only requires the on-behalf service to check the action the actor asked for. Whether the consequence goes through the other entity's on-behalf service or straight to its base service is left open.
- **How fine-grained actions are.** That is the service designer's choice (see Actions).
- **Who decides values from other entities shown inside a record**, such as the approver's name on an expense. Only that the on-behalf service returns them explicitly, as part of its shape.

## Relation to the other lenses

- [`detachable-domain`](../detachable-domain/README.md) is the foundation: every entity is reached only through its owning domain's service, and that service is this lens's base service. This lens decides *which door* a caller uses: the on-behalf service for every actor, the base service only for code you chose not to control or audit. Each domain owns the on-behalf services for its own entities too, so another domain that needs "the expenses this actor may see" asks the owner's on-behalf service instead of deciding for itself.
- [`single-chokepoint-per-fact`](../single-chokepoint-per-fact/README.md) gives each piece of data one writer. This lens puts one on-behalf service in front of everything an actor asks for. The chokepoint lives in the base service; the on-behalf service calls it and never writes itself. That lens says reading needs no chokepoint: true for keeping data *consistent*. For deciding what an *actor* may see, reading needs one too.
- [`pure-core-persistent-shell`](../pure-core-persistent-shell/README.md): "is anything stopping this action, and why?" is a pure function of the record. The base service and the action list both call it.
- [`deep-modules`](../deep-modules/README.md) and [`data-minimization`](../data-minimization/README.md): on-behalf services are part of a module's public surface, and what an actor may not see is never fetched, so it can't end up in a log, a cache or a response.
