---
type: concept-explainer
title: Growing a Doc Home
description: When to split a README into a Docs/ directory, where intermediate exit READMEs are earned, how to name index files, and when numeric prefixes are legitimate.
---

# Growing a Doc Home

How a documentation directory earns structure as it grows: the `README` → `Docs/` split, intermediate "exit" READMEs, index-file naming, numbered files, and keeping shared and generated docs honest.

> Read the [README](README.md) first for the altitude rule and the two placement modes.

## Start as one README; split on real context-rot

A doc home begins as a **single `README.md`**. It graduates to a `Docs/` directory of focused files — with the README demoted to a pure index — only when **one file has actually grown large enough to force a reader through sections irrelevant to their need.** The symptom is concrete: a single README accreting several distinct *kinds* of content at once (an orientation, a full reference, a testing guide, a migration plan, an FAQ).

Two failure modes to avoid:

- **Splitting too early.** A `Docs/` directory holding a single file is premature structure — it invents navigation overhead and creates two competing entry points (the README and the lone file) where one would do. Don't create `Docs/` before there's content to disclose.
- **Splitting too late.** A README that's become a 400-line everything-document buries the reader who needed ten lines.

A small area's correct resting state is **one README**, and it should sit comfortably beside multi-file siblings without being "upgraded" for consistency. Single-README is not a lesser form; it's the right form until growth says otherwise.

A lighter intermediate form is legitimate before a full `Docs/` directory: when a home has exactly **two reader altitudes** — an operator who needs "how to use it" and an implementer who needs the deep contract — a co-located two-file split (`README.md` for the how-to, a `TECHNICAL.md`/contract file for the depth) achieves progressive disclosure without a subdirectory.

Whenever a `Docs/` directory *is* created, it must carry its own index (a `README`/`index`) naming the directory's scope and listing its files. A set of mutually cross-linking topic files with no entry point is an incomplete split — the reader has no door.

## An index is a plaque, not a signpost

A reader descending toward a deep document should pass through a **graded series of index READMEs**, not leap from the top straight to the bottom. But each of those READMEs must *earn its place* — and when it does, it must be worth stopping at.

Think of an index as a **trail plaque** — the interpretive board at a path junction. A plaque does two things at once: it **orients** you (what this area is, why it exists, the one or two things worth knowing before you go deeper) and it **routes** you (what lies down each path). A bare **signpost** that only says "go that way" is a failure: if you make a reader stop, give them a view. So when you create an index, ask not just "what does this point to?" but "what is worth *telling* someone who has arrived here?" — and put that on the plaque.

### When a level earns a plaque: the novelty test

Plant a plaque only where the directory is a **domain concept the reader couldn't infer** — a feature, sub-system, or idea specific to this product, with a purpose and reasons that aren't common knowledge. Do **not** plant one on a **generic technical bucket** named after a *kind* of file. (This is the "document proportionally to novelty" rule: only document what a competent developer can't be expected to already know.)

- ✅ A directory named after a **domain concept** — e.g. a bespoke `Dunning/` (overdue-invoice chase) workflow, or a `Settlement/` engine — earns a plaque. A competent developer can't know what it means or why it exists *here* without being told, and that *why* is worth capturing. (The reasoning is often not in the code — it lives in the feature's design history; mine that to write the plaque, don't just summarize the folder.)
- ❌ A directory named after a **technical kind** — `Services/`, `Controllers/`, `Enums/`, `Jobs/` — earns nothing. "A folder of services" is common knowledge, and its parent already makes the purpose plain. Link any real content **straight through** from the plaque above it. (Narrow exception: a one-line README when the directory carries a *non-obvious constraint* — "vendored; never edit", "only X may import this".)

### A single child is a prompt to *check*, never a reason to collapse

Novelty is the test — **not child-count.** Having one child today is *not* a reason to remove a plaque. A level that names a concept a newcomer couldn't infer keeps its plaque even with a single child: a bespoke `Engine/` abstraction earns "what an engine is, and the contract every engine implements" *regardless of how many engines exist yet*. What you collapse is a **pure pass-through that introduces no concept of its own** — a bare `V1/` version-wrapper (everyone already knows what "version 1" means), or a generic bucket.

So when a level has one child, don't collapse on sight — *check*: **is there a novel concept to explain here?**

- **Yes** → keep the plaque, and make it explain the concept. `Engine/` with one engine still earns its board.
- **No, it's just a corridor to the one thing inside** → delete it and link that thing straight through from the real plaque above. One rich plaque beats a chain of "keep going" signposts.

Don't starve a real concept of its plaque just because it has one implementation today — and equally, don't manufacture levels for siblings that don't exist yet (a `V1/` wrapper because a `V2/` *might* someday arrive). Build the trail for what exists, and let novelty — not the shape of the directory tree — decide where a reader is worth stopping.

> This is where Documentation Placement and [Discoverable Knowledge](../discoverable-knowledge/the-trail.md) meet: the graded, descend-only trail is a discoverability property; deciding *which levels earn a plaque* — and making each plaque worth reading — is a placement decision.

## Index-file naming: `README.md`, split by tool boundary

Use **`README.md`** as the canonical index-node name everywhere in a source tree — it's the name every developer and platform already looks for.

Use a different fixed name (e.g. `index.md`) **only inside the subtree of a tool that forces it** — a documentation generator with its own filename convention — and only there. A single repository may legitimately run two index-naming conventions split strictly along a tool boundary; what breaks predictability is deviating *without* a tool forcing it (a stray `NOTES.md` or an ALL-CAPS status file standing in for the directory's entry point). Where a tool requires a manifest-style index *and* you want a human landing page, keep them as two separate files rather than letting two nodes compete for "the entry point."

## Numeric `NN-` prefixes only for true sequences

Number files `01-`, `02-` **only to visualize a genuinely sequential, dependency-ordered process** whose steps must be performed in order — and make that ordering explicit in the directory's index. Numbers imply mandatory sequence; applying them where there is none makes a reader believe in an order that doesn't exist, and the scheme visibly frays (collisions, a missing `03`, half-numbered/half-named sets).

Do **not** number:

- **Stable record identifiers** (decision records) — they're an unordered set with permanent IDs, not steps.
- **Chronological logs** (dated events, migrations) — order them by their date metadata, not a fragile prefix.
- **Parallel variants** of one topic (a "create" guide and an "update" guide) — they're peers, not a sequence.
- **Ordered steps *within* one task** — those are a numbered list *inside* a single file, not numbered sibling files.

## Keep shared and generated docs honest

Two recurring kinds of document need a placement rule rather than a new category:

- **Reusable templates / scaffolds** (a doc skeleton copied to start each new doc of a kind) live in **one canonical home and are never duplicated.** A byte-identical template copied into several trees is guaranteed to drift; keep a single source and point to it.
- **Machine-generated documents** (generated API references, emitted contracts) are **segregated from hand-authored docs and clearly marked "generated — do not hand-edit"**, so no one edits an artifact that the next build will overwrite. Generated files that aren't committed aren't part of the documentation trail at all.

## Capture what won't change — not volatile state — so it can't go stale

A document in a durable home must stay true as the code evolves. This is the *temporal* half of the "document proportionally to novelty" rule (stated above under plaques): novelty decides *whether* to document; the **staleness test** decides *what* to write so it lasts. Every sentence is a claim that can rot, so before writing one, ask:

> **Would a plausible change to the code or surrounding process make this sentence false?**

- **Yes** → it's **volatile state**: a count, the present list of things, an exact signature, "for now there is one," a sprint label. **The code (or the process system) is already the live source of truth for all of these**, so your prose is a *copy* that drifts the moment the real thing changes. Don't restate it — point to where it actually lives (the directory, the registry, the type), let the structure carry it (an index's links, which the trail keeps complete), or accept that it's a *generated* artifact and mark it as such (see [Keep shared and generated docs honest](#keep-shared-and-generated-docs-honest)).
- **No** → it's **durable**: the intent, the constraints, the design decisions, the mental model — *and the one-sentence purpose of the thing*, which a refactor doesn't falsify. The code can't tell you these and they rarely change. **This is what documentation is for.**

So the durable half explicitly *includes* the "what it does" line every boundary README is required to carry — a stable statement of purpose passes the staleness test. What it excludes is *current state* dressed up as prose.

```
❌ "There is currently one implementation."         volatile — the next one makes it a lie
✅ "Each implementation is fully independent, so a change to one can't affect another."
                                                    durable — true for any number of them

❌ "The handler takes a record and a context."      volatile — the signature will change
✅ "The handler is synchronous on purpose: callers depend on ordering."   durable
```

The point isn't to write *less* — it's to write the half that lasts. A doc full of the durable *why* stays correct for years; a doc that restates volatile state is wrong by the next refactor and trains readers to distrust all docs.

**Transient process state is just the most obvious volatile state.** Sprint numbers, phase labels, "not yet implemented", task or decision identifiers couple a durable doc to an ephemeral system and rot the fastest — keep them out entirely. And the in-flight working documents that carry them (plans, scratch investigations, status notes) don't belong in the durable trees at all; they live in the project's dedicated **working-document area**. When such work produces durable knowledge — a constraint, a contract, a rationale worth keeping — **re-home** that knowledge into its proper durable doc (copied out, self-contained), and leave only the history behind.
