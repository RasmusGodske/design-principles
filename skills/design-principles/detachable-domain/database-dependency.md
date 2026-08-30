---
type: concept-explainer
title: Detachable Domain — Detaching from the Database
description: How isolating an entity's models behind its owning domain's data-shaped service detaches the rest of the system from the database.
---

# Detachable Domain — Detaching from the Database

> **An entity's models are reachable only through the service of the domain that owns them, and that service speaks in data classes. Isolating the model behind that one data-shaped interface is what detaches the rest of the system from the database.**

This is the first of two axes of the [detachable-domain](./README.md) principle. It governs the relationship between an entity and its persistence. The second axis — references between domains — lives in [`domain-dependency.md`](./domain-dependency.md).

A note on what this axis is *not*: it is not "make every function pure." Keeping a single computation side-effect-free is [`pure-core-persistent-shell`](../pure-core-persistent-shell/README.md), and this axis uses that discipline for the computations that have real logic. What this axis adds is a claim about **dependency topology**: where the model is allowed to live, who may touch it, and therefore what the rest of the system depends on. A service that issues a query is not "pure" — but if it exposes a data-in/data-out interface, everything on the other side of that interface is detached from the model, which is the property this axis is after.

## Two representations, one entity

Most codebases conflate the entity with its database row: the ORM model *is* the `Order`, and to have an order you must have a row, and anyone anywhere can look the row up by id and mutate it. Detaching means splitting the entity into two representations with very different visibility:

- **The data class** — the canonical, in-memory form. Just the facts: fields and nested data, fully serializable. This is what crosses boundaries; it is what callers, other domains, the frontend, and tests see.
- **The ORM model** — **internal to the owning domain.** It is how that domain reads and writes its own rows. Nothing outside the domain imports it, queries it, or mutates it.

The model is a projection the owning domain manages, not the entity itself. You can hold and reason about the entity — as a data class — with no row behind it.

## The owning service is the single gateway

One domain owns each entity. That domain exposes a **service** as its public surface, and that service is the *only* code that touches the entity's models. Everyone else — controllers, other domains, jobs — speaks to the service in data classes: they hand it a request (data in) and receive a result (data out). The service does the querying and the writing **inside**, against its own models; that is legitimate and expected. What is forbidden is anyone *else* reaching past it to the model.

This is the rule that does the real work, and it holds even when there is no interesting logic at all:

> **An entity is created, read, mutated, and deleted only through its owning domain's service. No HTTP handler and no other domain touches the model directly — no create, no save, no delete, no query on the model from the outside.**

## What this buys you — ownership and reviewability first

The headline benefit is not a hypothetical future microservice. It is **today's** ownership and reviewability:

| Property | Why it follows |
|---|---|
| **Single-owner control** | Every change to an entity flows through one service. Invariants, validation, events, and audit live in exactly one place instead of being re-implemented (or forgotten) at every call site that happened to grab the model. |
| **A reviewable dependency graph** | When a domain's entities are reachable only through a small public service surface, reviewing a change means reading the surfaces it crosses — not every line that might have touched a shared model. Before clear boundaries, anything could read or write any model from anywhere; nothing was internal, so the whole surface was public and reviewing one change could mean reviewing everything. |
| **Tests run without infrastructure** | Logic with real computation takes data classes, so a test hand-builds the input and asserts on the output — no migrated schema, no factory-for-everything. An HTTP-handler test mocks the owning service and gets data classes back. |
| **Construct in memory; persist later — or never** | A valid entity graph can be built and reasoned about before any row exists. Previews and "what-if" flows stop requiring throwaway rows. |
| **Relocatable (the bonus)** | Because callers depend only on the service's data interface, the service can later fetch from another service instead of the local database, and its callers never know. Extraction stops being a rewrite — see [`domain-dependency.md`](./domain-dependency.md) for the honest cost. |

## The rules

1. **Only the owning domain's service touches its models.** Everyone else speaks to it in data classes. This is near-universal — it holds even for plain CRUD.
2. **The service's interface is data-in / data-out.** It takes a request data class and returns a result data class, even though it queries and writes inside. That data interface is what detaches its callers.
3. **Where there is real logic, make the inner computation pure** — a `f(data) → data` function the service calls, with no queries or model access inside it. This is [`pure-core-persistent-shell`](../pure-core-persistent-shell/README.md); reach for it for pricing, scoring, validation, eligibility — not for a row-to-row passthrough.
4. **Persistence is the service's job, isolated there.** The transaction, the constraint handling, and the model mapping all live inside the service. Callers decide *whether* to ask it to persist; they never persist themselves.

## Worked examples (generic)

### a. Read + compute — a pure inner function

A pricing routine. The domain has `Order`, `LineItem`, and a `Customer` with a discount tier. The *computation* is pure; the service resolves its input and calls it.

```text
// Pure inner computation — no model, no query. This is pure-core.
function calculateOrderTotal(order: OrderData) -> OrderTotalData:
    subtotal = sum(item.quantity * item.unitPrice for item in order.lineItems)

    return OrderTotalData(
        orderId:  order.orderId,
        subtotal: subtotal,
        total:    subtotal * (1 - order.discountRate),
    )
```

The test needs zero rows: hand-build `OrderData`, assert on `OrderTotalData.total`. The *service* is what reads the order and customer from its models, builds `OrderData` (the discount rate resolved up front), calls `calculateOrderTotal`, and — if asked — writes the result. The model never leaves the service.

### b. Write — create and mutate through the owning service

There is no pure computation here; the value is entirely in routing the write through the owner. The service is the only thing that touches the `Project` model.

```text
// The Project domain's public service — the only code that touches the Project model.
class ProjectService:

    function create(data: CreateProjectData) -> ProjectData:
        // Uniqueness is the database's job (see "DB-arbitrated invariants" below);
        // the service translates a violation into a domain error.
        project = Project()                       // the ORM model
        project.customerId = data.customerId
        project.name       = data.name
        project.save()

        return ProjectData.fromModel(project)     // re-projected to data, now carrying the generated id

    function rename(projectId: int, name: string) -> ProjectData:
        project = Project.byIdOrFail(projectId)
        project.name = name
        project.save()

        return ProjectData.fromModel(project)
```

An HTTP handler calls `projectService.create(data)` and receives a `ProjectData` — it never sees the `Project` model. Note the two facts the read-only examples don't surface: **who writes the row** (the owning service) and **how the created entity comes back** (the service re-projects the saved model to a data class, now carrying the generated id). For an entity created with no transformation, this is *all* there is — do not invent a "pure core" for a three-field insert.

### c. Search / list — the query lives in the service, behind a data interface

The query is not a violation; it is the service doing its job. What matters is that the query is *isolated to the service* and the interface on both sides is data.

```text
// HTTP handler receives a request data class, passes it straight through,
// and returns the service's data to the client.
function index(request: ListProjectsRequestData, projects: ProjectService) -> Response:
    return respond(projects.list(request))

// The service owns the query: filter, sort, paginate, aggregate — all the DB's strengths.
class ProjectService:

    function list(request: ListProjectsRequestData) -> ProjectListData:
        query = Project.query()
        if request.status:
            query = query.where(status = request.status)
        query = query.orderBy(request.sortBy, request.sortDir)

        page = query.paginate(perPage: request.perPage, page: request.page)

        return ProjectListData(
            projects:   [ProjectData.fromModel(p) for p in page.items],
            total:   page.total,
            page:    page.current,
            perPage: page.perPage,
        )
```

`f(ListProjectsRequestData) → ProjectListData` *at the interface*, even though it queries inside. The HTTP handler and the frontend depend only on the data classes; the `Project` model dependency is isolated to this one service inside its deep module. Test the handler by mocking the service and returning a `ProjectListData`. If projects later move to a different service, `list()` swaps its fetch for a network call and the handler never knows. This is the detachment — and notice it does **not** require "zero queries"; it requires the query to sit behind a data-shaped interface, owned by the entity's domain.

## DB-arbitrated invariants

Some invariants can only be enforced by the database: uniqueness ("project name unique per customer"), foreign-key existence, optimistic-lock versions. A data class cannot answer them, and a pre-check is racy (another request inserts between your check and your write). The rule:

- **The database constraint is the source of truth.** Keep the unique index / FK; let it be the real arbiter.
- **The owning service catches the constraint violation and translates it** into a domain error (a typed exception or a result). Doing this in the service is *expected*, not a failure of the principle — it is the service owning its entity's invariants.
- A pre-check for a nicer message is fine *in addition*, but never *instead* of the constraint.

The same applies to **transactions**: a write spanning several of the domain's tables, or an "end the old, create the new" that must read current state under a lock, lives inside the service, in one transaction. When correctness needs a read inside that transaction, the service reads inside it — "resolve everything before the logic" is a guideline for pure computations, not a ban on the service reading its own rows mid-write.

## When this does *not* mean extra ceremony

The ownership rule (mutate through the owning service) is near-universal. The full apparatus — a separate data-class twin plus a pure `f(data) → data` computation — is **not**. Reach for the apparatus only when there is genuine logic, a boundary to cross, or a detachability/testability need. Signs you are over-applying:

- Wrapping a no-logic CRUD entity in a model + data class + pure-compute step + mapper, hiding nothing (this also fails the [`deep-modules`](../deep-modules/README.md) deletion test).
- Inventing a `f(data) → data` for a row-to-row passthrough with no transformation.
- A data class that exists only to mirror a table one-to-one with no caller beyond the service.

For these, the entity still flows through the owning service — but the service is just doing a thin, honest write, and that is the whole design.

## Review red flags

- An HTTP handler or another domain calling **create / save / delete / query on the ORM model** of an entity it does not own.
- A business-logic (not service) function parameter typed as an **ORM model**.
- A **relation access mid-computation** (`x.relation.field` lazily loading a row) inside a function meant to be pure — a hidden query and a hidden input.
- An HTTP handler **returning an ORM model** (or a serializer wrapping one) to the frontend, coupling the frontend to the table shape.
- A **preview/draft feature implemented by creating real rows and deleting them afterwards.**
- A pure computation **buried with a `save()`** inside it instead of returning data for the service to persist.

## A practical guard

For the **pure inner computations**, wrap the call in a query log and assert **zero queries were issued** — if any fire, an input is being resolved lazily instead of passed in. For the **service boundary**, the guard is different: a caller (HTTP handler, another domain) should be able to run fully against a *mocked* service returning data classes, with no database at all. If a caller can't be tested without real rows, it is reaching past the service to a model.
