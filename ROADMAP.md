# {{PROJECT_TITLE}} — Roadmap

This directory aims to formalize {{ONE_LINE_BLURB}}.

<!-- Replace the line above with one or two sentences naming the
headline theorem the project is working toward and the proof route
the formalization will follow. -->

The work is expected to span multiple sessions. This file is the canonical
hand-off document: it carries the directory layout, status, mathematical
plan, and engineering conventions. Read it after `CLAUDE.md`.

> **Agents:** start with `CLAUDE.md` (the agent operating manual covering
> reading order, per-session workflow, friction review, and the
> `notes/PhaseN.md` template). This file is the *what*; CLAUDE.md is the
> *how*.
>
> Design rationale (why these choices and not others) lives in
> `DESIGN.md`. Open it only when you actually need to question a
> decision; otherwise this file is sufficient.

## Directory layout

```
<repo root>/
├── CLAUDE.md            agent operating manual — must-read first every session
├── ROADMAP.md           this file — directory layout, status, plan, conventions
├── DESIGN.md            rationale for cross-cutting design choices
├── TACTICS-GOLF.md      golf reference: grind, mirror rule, fun_prop, MCP, ...
├── TACTICS-QUIRKS.md    rescue reference: subst, simp residuals, dot notation, ...
├── CLEANUP.md           between-phases / post-phase cleanup-round discipline
├── notes/               per-phase work logs + cross-cutting logs
│   ├── PhaseN.md        lemma checklist + decisions + hand-off for Phase N
│   ├── FRICTION.md      long-running API/tactic friction log (created lazily)
│   └── PERFORMANCE.md   build-time + profiling notes (created lazily)
├── {{PROJECT_NAME}}.lean        top-level entry point
├── {{PROJECT_NAME}}/            all Lean sources live here
│   ├── Mathlib/         mirror for upstream-eligible lemmas (see DESIGN.md)
│   │   └── …/           each file mirrors its eventual upstream path
│   └── Basic.lean       placeholder; replace with the project's first module
├── lakefile.toml        Lake build config; depends on mathlib4
├── lean-toolchain       pinned Lean version (matches mathlib4)
├── lake-manifest.json   resolved dependency revisions (gitignored until first build)
├── blueprint/           LaTeX/plastex blueprint (web + PDF)
├── home_page/           Jekyll landing page deployed to GitHub Pages
└── .github/workflows/   CI: build/lint, mathlib hopscotch bumps, dependabot
```

## Status

| Phase | File(s) | Status |
|---|---|---|
| 1. <name> | `{{PROJECT_NAME}}/File1.lean` | planning |

<!-- Add a row per phase as it's planned. Use ✓ once a phase closes,
"in progress" while it's active, "planning" for the next-up phase. -->

## Phase plan

### Phase 1 — <name>

<!-- One-paragraph mathematical scope, the key definitions to be
introduced, and the headline lemma(s) the phase delivers. -->

Files: `{{PROJECT_NAME}}/File1.lean`.

Lemmas to develop:
- `Foo.bar` — short description
- `Foo.baz` — short description

<!-- Repeat per phase. Each opens with a one-paragraph scope, names
the files it adds or extends, and lists the substantive lemmas. -->

## Engineering conventions

- **Set-first.** Where a definition can stand on `Set V` instead of
  `Finset V`, prefer `Set V` so consumers don't need `[Fintype V]`.
  Promote to `Finset V` only when proof / use sites genuinely benefit.
- **Cardinalities.** Use `Set.ncard` for sets and `Finset.card` for finsets.
  Avoid `ℕ`-subtraction; rephrase `a ≤ b − c` as `a + c ≤ b`.
- **Style.** Module docstrings at the top of each file (`/-! # Title -/`).
  One declaration ↔ one purpose. Comments only when *why* is non-obvious.
- **Imports.** Each file imports the minimum it needs.
- **Decidability.** Add `[DecidableEq V]` / `[DecidableRel G.Adj]` only
  when a body genuinely builds specific `Finset V` / `Adj`-iterating
  objects. `classical` at the proof top is the acceptable alternative
  when adding the typeclass to the signature isn't worth the API
  noise. Many definitions can stay noncomputable via `Set.ncard`.
- **Predicates as `def`s, not `abbrev`s.** Non-reducible definitions
  don't unfold for `grind` on their own. To break a structured-predicate
  goal into parts, use `refine ⟨?_, ?_⟩`; for a membership predicate,
  add a corresponding `mem_*` simp lemma. See `TACTICS-GOLF.md` for
  the full discussion.
- **Missing mathlib lemmas.** If you need a lemma that genuinely
  belongs upstream, put it under `{{PROJECT_NAME}}/Mathlib/<exact mathlib path>`
  so promotion is later a copy-paste. The directory is created lazily;
  don't pre-populate. See `DESIGN.md` "Mirror directory".
- **Tactic notes.** Practical guidance on `grind`, `fun_prop`,
  `linear_combination`, the mirror-first rule, and other cross-cutting
  idioms lives in `TACTICS-GOLF.md`. When in doubt, read it — the
  section TL;DRs are short and save iteration time.
- **No prose counts in shared docs.** Don't write "Phase X surfaced
  N upstream candidates" or similar in `ROADMAP.md`, `DESIGN.md`, or
  the TACTICS docs — counts drift the moment a new phase mirrors more
  lemmas. Link to `notes/FRICTION.md` (or the mirror directory
  listing) as the source of truth instead.

## Working on the project

The per-session workflow (starting / working / friction review at
end-of-session / leave-it-ready-for-the-next-agent), and the
`notes/PhaseN.md` template, live in `CLAUDE.md`. Agents: read that
first.

## References

<!-- Add bibliographic references for the headline theorem and the
key results the proof route depends on. Match the conventions in
blueprint/src/bibliography.bib (firstAuthorYear for single-author,
camelCased authors for multi-author works). -->
