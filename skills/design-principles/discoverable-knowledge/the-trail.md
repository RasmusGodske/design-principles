---
type: concept-explainer
title: The Trail
description: What the documentation root is, how index and content nodes make a doc reachable, and how to tell a trail document from a self-discovering ecosystem.
---

# The Trail

The reachability model in full: what the root is, the two kinds of node, what "reachable" means precisely, and how to tell a trail document apart from a self-discovering ecosystem that sits outside it.

> Read the [README](README.md) first for the two facets (reachability + navigability) and the short version of this model.

## The root

The trail has exactly one root: the project's top-level **`README.md`** — the document a human opens first when they land in the repository, and the natural starting point for an agent asked to orient itself.

A coding-agent's configuration file (if the harness has one) is **not** the root. It may be a convenient shortcut that points *into* the trail, but it is part of a separate tooling layer (see [Ecosystems](#ecosystems-and-the-owned-discovery-test) below). The canonical root is the one a human and an agent share: `README.md`.

**Reachability is defined against this root.** A document is reachable if you can arrive at it by starting at `README.md` and following references. A document you cannot reach this way is an **orphan**, regardless of how good it is.

## Two kinds of node

Every document on the trail is one of two kinds, and the distinction is what lets a README live without being referenced by a content doc:

- **Index nodes** — `README.md` and `index.md` files. Discoverable *by convention*: a reader who opens a directory knows to read its README. An index node's job is to **delegate scope downward** — name and link its children — not to explain code itself. Index nodes are the branch points of the trail.
- **Content nodes** — every other document. Discoverable *only by being referenced*. A content node explains its subject. An unreferenced content node is the orphan the whole discipline exists to prevent.

This is why "a README can exist without an inbound reference" is true but narrow: a README is found by the convention of looking in its directory. A content node has no such convention — references are its *only* route to being found.

## What "reachable" means precisely

Reachability is not "linked from somewhere." It is a connected chain from the root:

1. The root index references every top-level area's index.
2. Each index node references **every** sibling document in its own directory and every child index below it.
3. Therefore the chain runs unbroken from `README.md` to every document.

Two failure modes are defects of equal severity:

- **A missing reference** — a content node no index links to. An orphan.
- **An incomplete index** — an index that links *some* of its directory's documents but not others. The unlisted ones are orphans hiding behind a node that looks complete. An index that lists three of its five docs is as broken as one that lists none.

### The trail is graded and descend-only

Depth is reached by **descending the chain of index nodes**, never by jumping. The root must not link directly to a document five directories deep; it links to the top-level area's index, which links to the next level's, and so on. Each level is an **exit**: a reader descends only as far as they need and stops the moment they have enough.

This has a practical consequence: where a hierarchy has levels but no index nodes at the intermediate levels, the trail has gaps — the root is forced to either ignore the deep document or leap to it. The fix is to give each intermediate level that represents a distinct scope its own index node. (When such an intermediate node is *worth creating* — i.e. when its scope is novel enough to explain — is a Documentation Placement question.)

### Index nodes and content nodes are read differently

An index node and a content node answer different questions, and mixing them is a smell:

- An **index node** is read to *route*: "what's here, and where do I go next?" Its payload is links + one-line scopes. If you find yourself reading an index node for its own content, it has stopped being an index.
- A **content node** is read for *itself*. Sibling content nodes at one level should answer the same shape of question — divergent depth between peers ("this module is documented in detail, its sibling not at all") is a defect, the same asymmetry an incomplete index creates.

## Navigability: descriptions at the target, not the link

Reachability gets you *to* a document; navigability lets you decide whether to bother *before* you open it. The rule:

- The **target document** carries its self-description once, in frontmatter (`description`) — see [frontmatter-and-types.md](frontmatter-and-types.md).
- The **source** that links to it carries only *which* documents it points to and *how they're grouped/ordered*. It does not duplicate the target's description into a hand-written "read this when…" gloss.

Because the description lives once at the target, an index node's reading-map can be **generated** from its children's frontmatter rather than hand-maintained — and it cannot drift per-link, because there is only one copy. Genuine *lateral* cross-references (one content node citing another for context) still carry a sentence of prose explaining the relationship; that's a property of the edge, not a duplicate of the target's identity.

## Ecosystems and the owned-discovery test

Not every markdown file in a repository is a trail document. Some material is found by a mechanism *other than a reference* — and forcing it onto the reference trail is busywork that the trail's own checker would only get in the way of. The test:

> **Owned-discovery (deletion) test:** if every link to this file were deleted, would it still be found the right way?
> - **No** → it's a **trail document**. References are its only route to discovery, so it must be reachable.
> - **Yes** → it's a **self-discovering ecosystem**. It has its own discovery mechanism and sits outside this trail.

Things that pass the test (yes — self-discovering) and are therefore *outside* the trail:

- **Working-document areas** — in-progress plans, sprint scratch, decision logs. Found by the working-doc tooling, not the durable trail. Durable knowledge produced inside them must be **re-homed** into the trail (copied out, made self-contained) — never merely linked, so it survives after the working docs are archived.
- **Self-loading tooling** — material a tool surfaces by its own mechanism (a harness that loads files by path-glob, a CLI that lists its commands).
- **Generated output** — anything a build step or generator emits; the trail governs hand-authored knowledge.
- **Third-party trees** — vendored dependencies, package-manager-owned directories.
- **Your coding-agent's configuration layer** — agent-harness files are tooling, not project knowledge. They may read *from* the trail; the trail never depends on them.

### One pointer, not a wiring job

A self-discovering ecosystem is outside the *reference* trail, but a reader following the trail should still be able to learn it *exists*. The rule is **one reachable pointer, not per-file wiring**: a single trail document mentions the ecosystem and how it's discovered (e.g. "working documents live under `…/` and are found via the workspace tooling"). You do not wire each of its files into the trail — its own mechanism handles that.

### The two-layer corollary

A repository worked by a coding agent has two layers of markdown, and only one is governed here:

1. **Project documentation** — knowledge about the product and codebase. This is the trail. Rooted at `README.md`.
2. **Agent harness** — the agent's own configuration (instructions, rules, skill/agent definitions). Tooling, potentially swapped if you change agents. Outside the trail.

The dependency runs one way: the harness reads from the project trail; the trail never references or depends on the harness. Keep the principle's own wording agnostic — it describes "a self-discovering tooling layer", never a specific vendor's directory.
