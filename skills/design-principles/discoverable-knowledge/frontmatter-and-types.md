---
type: lookup-reference
title: Frontmatter and Types
description: Which frontmatter fields a document needs, how to write a description that triggers the right open, and which document type to choose from the canonical vocabulary.
---

# Frontmatter and Types

How a document carries its identity: the required frontmatter, how to write a `description` that does its job, and the vocabulary of document `type`s.

> Read the [README](README.md) for why identity lives in frontmatter while the graph lives in body links, and [the-trail.md](the-trail.md) for how `description` powers navigability.

## The frontmatter

Every governed document opens with a YAML frontmatter block. Three fields are required; one is optional.

```yaml
---
type: concept-explainer
title: How Billing Periods Work
description: What a billing period is, how its boundaries are computed, and why partial periods are prorated.
tags: [billing, periods]
---

# How Billing Periods Work
...
```

| Field | Required | What it is |
|---|---|---|
| `type` | yes | The document's **kind**, from the vocabulary below. Lets a reader or tool filter by function. |
| `title` | yes | The canonical display name. **The first heading (`# …`) must match it** — one title, no drift. |
| `description` | yes | One sentence: what this document is. Read by anything linking to the doc, so it must stand alone. |
| `tags` | no | Free-form labels for cross-cutting grouping. |

There is deliberately **no** `parent`, `read-when`, or `status` field:

- The **graph** is the body's markdown links, not a frontmatter field — so there is no `parent`.
- The **"when to read it"** is read from this doc's own `description`, not authored at each link — so there is no `read-when`.
- **Lifecycle** is not a trail concern: a document is either durable (and on the trail) or transient (and in the working-document area, off the trail). There is no in-between state to mark, so there is no `status`.

### `title` is canonical; the H1 must equal it

The display name lives in the frontmatter `title`, and the document's first heading must be the same string. This is a single source of truth expressed in two places that a checker can compare — if they diverge, that's an error, not a judgement call. (A tool can therefore build an index from frontmatter alone, without parsing the body.)

## Writing a good `description`

The `description` does double duty: it's the document's identity *and* the "should I read this right now?" signal every link inherits. That makes one property essential:

> **Write the description as the question the document answers, not the topic it's filed under.**

- ✅ "How to decide whether a class belongs to the public surface or stays internal." — a reader knows instantly whether this is what they need.
- ❌ "About the public surface." — a topic label; the reader still has to open the file to find out if it's relevant.

Rules of thumb: one sentence; lead with the verb or the question ("How to…", "What a … is and when…", "Why … rather than …"); make it true *standalone*, because it will be read far from the document, in a list of links the reader is scanning to decide what to open.

## The `type` vocabulary

Types are **functional**, not topical — they classify *how a document is read*, not what subject it covers. Subject is already handled by full-text search and by where the doc lives; what neither handles well is *function* — "do I need a rule I must obey, an explanation, a procedure, a lookup, an orientation map, a record, or a signpost?" Each type's selecting question is answerable from the title and first paragraph alone, which is all a scanning reader cheaply has.

| `type` | Read it to… | The question that selects it |
|---|---|---|
| `index` | route onward | "Is this document's main job to point me to *other* documents?" |
| `concept-explainer` | understand | "Do I read this start-to-finish to understand how or why something works — no rule to obey, no code to locate, no single fact to look up?" |
| `how-to-guide` | perform a task | "Does this give me ordered steps to *do* one concrete thing right now?" |
| `lookup-reference` | look up a fact | "Do I open this to jump to *one entry* and confirm a name/signature/option, not read it through?" |
| `module-orientation` | locate code | "Is this tied to one code area — opened because I'm about to work *in* that code and need to know what lives there and how it's organized?" |
| `binding-rule` | obey a constraint | "Does this prescribe a pattern I'm *required* to follow — would a reviewer reject my change for ignoring it?" |
| `research-record` | weigh past evidence | "Is this a point-in-time record (an investigation, recorded gotchas, a completed change) I should treat as possibly-stale evidence rather than standing authority?" |

Notes on the boundaries that earn these splits:

- **`binding-rule` vs everything else** is the single most decision-relevant axis for a reader: *must I comply with something here?* Keep it broad and surface-agnostic — a coding rule, a component contract, and a mandated template are all `binding-rule` because the reading posture (comply) is identical.
- **`concept-explainer` vs `module-orientation`** — the first builds a mental model of a concept with no required code location; the second is a map anchored to a specific code area. A decision record (ADR) is a `concept-explainer`: you read it to understand *why a choice was made and what it rules out*.
- **`research-record`** is the only backward-looking type — you read it to *orient before work*, distrusting it as a snapshot, where the others are living authority. That "trust posture" difference is why it's worth its own type.

### Governance: a canonical list, not free strings

`type` is only useful if its values are consistent — if documents scatter across `doc`, `guide`, `guideline`, `reference` for the same kind, filtering collapses. So the list above is **canonical**: a new type is a deliberate addition to it, not something an author coins on the spot. A document carrying an unknown type is **warned, not rejected** — the trail tolerates an unrecognized type (so a genuinely new kind isn't blocked from existing) while the warning keeps synonyms from quietly creeping in.

Adding a type is earned the same way every split above is: only when a document is genuinely *read differently* from all existing types. A kind that's read like an existing type — however distinct its subject or surface form — takes that type; it does not get a new one.
