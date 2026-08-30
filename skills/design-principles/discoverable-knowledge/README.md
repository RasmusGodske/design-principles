---
type: concept-explainer
title: Discoverable Knowledge
description: Why every document must be reachable from a known root and self-describing at the link, and how the trail of index and content nodes makes that checkable.
---

# Discoverable Knowledge

A discipline for keeping a codebase's documentation **findable**: every document is reachable from a known root by following references, and every reference describes itself well enough that a reader can decide whether to follow it. Knowledge no one can find might as well not exist.

## Why this exists

Documentation rots in a specific, predictable way: someone writes a useful markdown file, puts it somewhere plausible, and never links it from anything. From that moment the file is an **orphan** — the only way to find it is to already know it's there, or to stumble across it while browsing the filesystem. It drifts out of date because no reader ever arrives to notice. It might as well not have been written.

This is sharper for a coding agent than for a human. An agent has a small working context and no memory of "that doc I read last month." It discovers knowledge the way a researcher follows a trail of citations: start somewhere known, read, follow the references that look relevant, stop when it has enough. A document that nothing references is invisible to that process. So the cost of an orphan isn't just untidiness — it's knowledge that exists but cannot participate.

Discoverable Knowledge makes the trail an explicit, checkable property instead of a hope.

## The two facets

Knowledge is discoverable when **both** of these hold. They are co-equal — one without the other still strands the reader:

- **Reachability** — you can get to the document from a known root by following references. No orphans. A perfectly-written doc that nothing links to is still lost.
- **Navigability** — once you see a reference to a document, it describes itself well enough that you can decide whether to follow it *without opening it*. A reachable doc behind an unlabelled link forces you to open everything to find anything.

The whole discipline is in service of one outcome: a reader (human or agent) starting from the root can find what they need and skip what they don't.

## The model in brief

The full model is in [the-trail.md](the-trail.md); the short version:

- **The root** is the project's top-level `README.md` — the one document a human or an agent opens first. Every governed document is reachable from it.
- **Index nodes** (`README.md` / `index.md`) are discoverable *by convention*: open a directory, read its README. They are the branch points of the trail.
- **Content nodes** (everything else) are discoverable *only by being referenced*. An unreferenced content node is the orphan this discipline eliminates.
- The trail is **graded and descend-only**: the root names every top-level area; each index node names its children; depth is reached by descending the chain. There is never a root-to-deep-leaf leap, and an index that lists only *some* of its children is a defect equal to a missing one.

## How a reference describes itself

A document's *identity* lives in YAML frontmatter; the *graph* lives in the body's links. The split that makes the trail navigable:

- The **target** carries a one-sentence `description` in its frontmatter — "what this is", written once, where it cannot drift.
- The **source** simply links to it (with grouping and order). It does **not** hand-author a "read this when…" gloss next to every link — that gloss is *read from the target's description*. An index's reading-map can therefore be **generated** from its children's frontmatter rather than maintained by hand.

So you write the description once, at the doc, and every reference to it inherits a self-describing label for free. The required frontmatter fields, the description-writing guidance, and the document-type vocabulary are in [frontmatter-and-types.md](frontmatter-and-types.md).

## Prior art: the Open Knowledge Format

This discipline is a close cousin of Google's **Open Knowledge Format (OKF)** — markdown files with YAML frontmatter, cross-linked into a graph, with `index.md` files providing progressive disclosure. A repository that follows Discoverable Knowledge is, in effect, a conformant OKF bundle.

The one deliberate divergence is the point of the whole thing. OKF's conformance rules *require consumers to tolerate broken cross-links* — it gives you a format but **no reachability guarantee**. Discoverable Knowledge adds exactly the guarantee OKF omits: every governed document must be reachable, and an orphan is a defect, not a tolerated edge case.

## What is governed

Discoverable Knowledge governs a project's **durable documentation** — the knowledge a reader would otherwise have to read the source to recover. It does **not** govern:

- **Transient/working documents** (in-progress plans, scratch findings) — these belong in a dedicated working-document area, never in the durable trail.
- **Self-discovering material** — anything found by a mechanism other than a reference (a tool that loads it, a generator that emits it, a package manager that owns it). The test, in full in [the-trail.md](the-trail.md): *if every link to this were deleted, would it still be found the right way?* If yes, it's a separate ecosystem with its own discovery, outside this trail.
- **Your coding-agent's configuration layer, if any** — agent-harness files are tooling, not project knowledge, and sit outside the trail (the trail may be read *by* the harness, but never depends on it).

## Enforcement

The discipline is designed to be machine-checkable, and a companion checker can enforce it: walk the link graph from the root, flag orphans, validate frontmatter, and generate the reading-map indexes. The principle is the contract; any such tool is a separate artifact that checks it. The principle stands on its own without the tool — a human can follow it with no tooling at all.

## Reading map

This README is the spine. Load a depth doc only when the task needs it.

| Doc | Read when |
|---|---|
| [the-trail.md](the-trail.md) | Working out whether a document is reachable, what counts as an index vs content node, or whether something belongs on the trail or is a self-discovering ecosystem |
| [frontmatter-and-types.md](frontmatter-and-types.md) | Tagging a document — choosing its `type`, writing its `description`, or filling its frontmatter |

## What this is not

- **Not a folder structure.** Discoverable Knowledge says nothing about *where* a document should live — only that it be reachable and self-describing. Where docs live is the concern of its sibling principle, **[Documentation Placement](../documentation-placement/README.md)**.
- **Not a wiki engine or a publishing tool.** It's a discipline over plain markdown files; no runtime, no build step required.
- **Not a documentation mandate.** It does not say "write more docs." It says: *of the docs that exist, none may be orphans.* Whether a thing deserves a doc at all is a Documentation Placement question.

## How it relates to the other principles

Discoverable Knowledge governs the **documentation graph** (is a doc findable?). It composes with **[Documentation Placement](../documentation-placement/README.md)**, which governs **where documentation lives** (co-located with code, centralized, the README→`Docs/` split, intermediate "exit" READMEs). The two meet at one move: splitting an overgrown README into a `Docs/` directory creates content nodes that the README — now an index — must reference. Placement decides *where*; Discoverable Knowledge decides that the result is *wired and self-describing*.

The parallel to the code-side principles is exact: `deep-modules` (code shape) and `detachable-domain` (code topology) are to source what Documentation Placement (doc placement) and Discoverable Knowledge (doc graph) are to documentation.
