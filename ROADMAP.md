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
├── PHASE-BOUNDARIES.md  phase open/close checklists (read at a phase boundary)
├── MODULE-SYSTEM.md     module-system conversion reference (read on demand)
├── formalization.yaml   project metadata self-report (synced at phase boundaries)
├── LICENSE              Apache-2.0
├── .claude/commands/    project slash commands (coordinate-phase + its playbook)
├── .claude/agents/      subagent definitions the coordinator dispatches
├── notes/               per-phase work logs + cross-cutting logs
│   ├── PhaseN.md        lemma checklist + decisions + hand-off for Phase N
│   ├── coordinate-phase-rescue.md  coordinator rescue reference (read on demand)
│   ├── dispatch-log.md  /coordinate-phase exception log (coordinator-owned)
│   ├── FRICTION.md      long-running API/tactic friction log (created lazily)
│   └── PERFORMANCE.md   build-time + profiling notes (created lazily)
├── {{PROJECT_NAME}}.lean        top-level entry point
├── {{PROJECT_NAME}}/            all Lean sources live here
│   ├── Mathlib/         mirror for upstream-eligible lemmas (see DESIGN.md)
│   │   └── …/           each file mirrors its eventual upstream path
│   └── Basic.lean       placeholder; replace with the project's first module
├── lakefile.toml        Lake build config; depends on mathlib4
├── lean-toolchain       pinned Lean version (matches mathlib4)
├── lake-manifest.json   resolved dependency revisions (commit after first build)
├── blueprint/           LaTeX/plastex blueprint (web + PDF)
│   └── AUTHORING.md     TeX authoring conventions (read on demand)
├── home_page/           Jekyll landing page deployed to GitHub Pages
└── .github/workflows/   CI: build/lint, mathlib hopscotch bumps, dependabot
```

## Status

The default phase granularity after Phase 0 is **one Lean source
file per phase** (multiple phases may share a blueprint chapter);
the Status table carries one row per phase, plus a row per cleanup
round (see `CLEANUP.md`).

| Phase | File(s) | Status |
|---|---|---|
| 0. Detailed informal blueprint | `blueprint/src/chapter/*.tex` | planning |
| 1. <name> | `{{PROJECT_NAME}}/File1.lean` | — |

<!-- Add a row per phase as it's planned. Use ✓ once a phase closes,
"in progress" while it's active, "planning" for the next-up phase. -->

The Status table is a **thin index**: each cell is a status marker plus
at most one short scope clause and a `(see notes/PhaseN.md)` pointer —
**never** a phase summary. The one-paragraph summary lives in the
per-phase prose under *Phase plan* (§N) below; the lemma list and
decisions live in `notes/PhaseN.md`. A cell that grows past a clause
or two has absorbed content that belongs in §N — re-thin it.

## Phase plan

### Phase 0 — Detailed informal blueprint (forward mode)

Phase 0 writes the project's **entire informal blueprint** before any
Lean lands: every chapter under `blueprint/src/chapter/`, with full
statements, prose proofs, and `\uses{...}` dep edges — but no
`\lean{...}` pointers and no `\leanok` ticks. The dep-graph is
all-red on first build because the red nodes *are* the to-do list
for the Lean phases. Work log: `notes/Phase0.md`.

Phase 0 closes when the dep-graph is a single connected component
sinking on the headline theorem(s), and the §§1–N sections below
have been sharpened from the blueprint: each later phase section is
cut **one per Lean source file** and lists its **blueprint targets**
— specific `def:foo` / `lem:foo` / `thm:foo` labels under
`blueprint/src/chapter/` — instead of speculative Lean lemma names.
The phase-completion bar for every later phase is *the listed nodes
acquire `\lean{...}` + `\leanok` in the blueprint, the corresponding
Lean declarations land, and `blueprint/verify.sh` stays green*.

### Phase 1 — <name>

<!-- One-paragraph mathematical scope: the key definitions to be
introduced and the headline result(s) the phase delivers. Written
(or sharpened) at Phase 0 close, from the blueprint. -->

Files: `{{PROJECT_NAME}}/File1.lean`.

Blueprint targets: `def:foo`, `lem:bar`, `thm:baz`
(`blueprint/src/chapter/<chapter>.tex`).

<!-- Repeat per phase, one per Lean source file. Each opens with a
one-paragraph scope, names its file, and lists its blueprint node
labels — not speculative Lean lemma names; the Lean names are chosen
when the nodes are formalized. -->

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

  *Mathlib-affinity check, applied when drafting each new lemma.*
  Before landing a lemma in a project file, pause and ask whether the
  body uses any project-specific hypothesis. The trigger is
  signature-shape: a lemma parameterised over the project's data is
  almost always project-internal; a lemma whose conclusion is about
  an abstract object (a `Submodule`, a `Matrix`, a `Finset`-sum, a
  `SimpleGraph` lacking the project's bundle) is a candidate for the
  mirror. If the body genuinely needs no project hypothesis, draft
  the abstract lemma under `{{PROJECT_NAME}}/Mathlib/<exact upstream
  path>` *from the start* (file the body verbatim, file the one-line
  project consumer alongside if needed), rather than inlining the
  abstract chunk in the project file and migrating later. The
  asymmetry is the reason for the rule: the early-draft cost is
  zero, while retro-mirroring costs a multi-task cleanup round
  (observed in practice: one cleanup round retro-mirrored six
  modules that should have landed in the mirror from the start).

  *Landed mirror modules.* Once mirrors accumulate, keep a one-line-
  per-module inventory list under this bullet (path — lemma names —
  phase that landed it); the running tree under
  `{{PROJECT_NAME}}/Mathlib/` is the ground truth, the list is the
  human-readable map.
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
