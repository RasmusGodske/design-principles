# design-principles

A set of design principles for writing maintainable, testable, decoupled code — packaged as a skill for coding agents (Claude Code and anything else that reads `SKILL.md`-style skill directories).

The principles are **lenses**, not procedures: each one is a way of looking at a design or a diff. They are language- and framework-agnostic; stack-specific mechanics (directory names, wiring, enforcement tools) live in **bindings** beside the principle they bind.

| Principle | One-line |
|---|---|
| Deep Modules | Hide a lot of behaviour behind a small interface, with an explicit public surface. |
| Pure Core, Persistent Shell | Business logic transforms data into data; persistence is a caller decision at the edge. |
| Detachable Domain | Each domain owns its entities and exposes them only through a data-shaped service. |
| Config and Record | Every entity is portable authored config or a context-bound row — and its identity is modelled accordingly. |
| Data Minimization | Durable records hold references, not copies of personal data; privacy mechanisms fail closed. |
| Framework and Implementation | The framework holds only the invariant shape; implementations own the semantics; promote on evidence. |
| Single Chokepoint per Fact | One place in the code creates, changes, or deletes each piece of data. |
| Testing | A test's location says what it covers; its cost is declared inside it. |
| Documentation Placement | Docs live at the altitude that matches them. |
| Discoverable Knowledge | Every document reachable from a known root; every reference self-describing. |

## Why

Most of the cost of software is paid after it is written: reading it, changing it, extending it, and reviewing someone else's change to it. These principles exist to keep that cost low, and they do it by making the writing of code **mechanical** — most decisions are already made before the first line is typed:

- **Where things go is a rule, not a judgment call.** A module has a fixed shape with a small public surface; a class has one obvious home; a test lives beside what it tests; a doc lives at the altitude of what it describes. "Where does this belong?" is answered by looking it up, not by discussing it.
- **What to create is a rule, too.** When something is a data class, when it is a model, when it earns a service, when a group of code earns a module, when a framework/implementation split is justified — each has an explicit criterion, and most of the criteria are *earn it first*: don't add structure until the code shows it needs it.
- **One way to change a fact, one owner per entity.** Each piece of data has a single place that writes it and a single domain that owns it, so a change stays local and a bug has one place to be.
- **Review gets cheap.** When everyone — every developer and every agent — is judging a diff against the same lenses, review is checking a design against shared rules instead of relitigating taste.
- **Review can pick its depth.** Because the structure is predictable, a reviewer can choose the level they want to look at instead of reading everything. For one module the public surface is what matters, so they review only `public/` and trust that nothing else is reachable from outside; for a riskier module they go one level down and read the internal service behind that surface. Without an agreed structure you cannot make that choice — you do not know what shape the implementer followed, so the only safe review is the whole diff. When the boundary is enforced (only a module's published surface may be imported), what sits behind the surface is the module's own concern, and a reviewer can decide, explicitly, whether to look at it.

The result is a **shared language between developers and coding agents**. The principles are written as lenses with diagnostic questions and red flags, so a human can apply them in a design conversation and an agent can apply them mid-task, and both reach the same conclusion for the same reason.

### Why this matters for coding agents

Coding agents are very good at producing code that works right now and noticeably worse at producing code that is still easy to build on six months and fifty features later. Left to their defaults they optimize locally: the nearest working shape, another helper, a second code path that writes the same table, a model reached from wherever it was convenient. None of it is wrong in the moment; all of it compounds. The long-term result is a codebase where each new change is a little harder than the last, until the agent (and the humans) hit a wall where nothing can be added without first untangling what is already there.

These principles do not make that wall disappear. What they do is move it: by giving the agent explicit rules about shape, ownership, purity, identity, and placement — rules it can check rather than intuit — a much larger amount of code can be written before the codebase stops being easy to extend. And because the rules are the same ones humans review against, the code the agent produces stays legible to the people who will maintain it.

Start at [`skills/design-principles/SKILL.md`](skills/design-principles/SKILL.md) — the index that tells an agent (or a human) which lens applies when.

## Install

Claude Code discovers skills in `~/.claude/skills/` (user-wide) or `<project>/.claude/skills/` (per project). Clone and symlink:

```sh
git clone https://github.com/RasmusGodske/design-principles.git ~/.local/share/design-principles
ln -s ~/.local/share/design-principles/skills/design-principles ~/.claude/skills/design-principles
```

Update with `git -C ~/.local/share/design-principles pull`.

## Layout

```
skills/design-principles/
  SKILL.md                         index — which lens, when; how bindings work
  <principle>/README.md            the principle (stack-agnostic)
  <principle>/*.md                 deeper sub-docs, read on demand
  <principle>/examples/            worked examples in neutral pseudocode
  <principle>/bindings/<stack>/    the real names / wiring / enforcement for one stack
```

Bindings today: `laravel` (for `deep-modules` and `testing`). To add a stack, copy the shape of an existing binding; keep everything else agnostic — `./check.sh` fails if a principle doc names a language, framework, tool, or project. Terms specific to the codebase you extracted principles from can go in a gitignored `check.local` (one regex per line) so the gate keeps catching them without committing the names.

## Credits

The **Deep Modules** principle is rooted in John Ousterhout's *A Philosophy of Software Design*, and the initial inspiration for it here came from [Matt Pocock](https://www.aihero.dev/) — his writing on deep modules and AI-assisted coding is where this collection started.

## License

MIT — see [LICENSE](LICENSE).
