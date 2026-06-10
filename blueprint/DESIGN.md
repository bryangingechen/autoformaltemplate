# blueprint/DESIGN.md — workflow and selectivity notes

This file holds the cross-cutting **rationale** for how the blueprint
integrates with the rest of the project: when to write the blueprint
relative to the Lean (backfill vs forward), what to include vs. skip,
and open questions about the workflow.

It is the blueprint's analogue of the top-level `DESIGN.md` — notes
and discussion rather than operational rules. Operational rules
(static checks, local build) live in `blueprint/CLAUDE.md`;
authoring conventions live in `blueprint/AUTHORING.md`.

## What the blueprint is for

The blueprint serves two audiences and produces three artefacts:

- **Mathematician readers** browsing the project for the first time
  see the *web rendering*: a hyperlinked LaTeX document explaining
  the formalization's content in mathematical English, with
  `\lean{...}` pointers down to the API docs for each formalized
  lemma.
- **The maintainer / contributors** see the *dep-graph view*
  (`dep_graph_document.html`): a visual map of which lemmas depend on
  which, color-coded by formalization status.
- **A PDF rendering** for offline reading and citation.

The blueprint is not a 1:1 mirror of the Lean. It records the
**mathematical structure** the formalization is built around, not
every engineering detail.

## Two workflow modes

The blueprint can be written either after the Lean lands (backfill)
or before it (forward). Both produce the same final artefact; the
difference is when the writing happens and what role the blueprint
plays during Lean work.

### Backfill mode

Lean is the source of truth. The blueprint chapter is written from
the Lean as raw material, after the phase is complete. Every entry
has `\leanok` from the start; the dep-graph for the new chapter is
all-green when committed.

When to use:
- A phase has already landed and there is no blueprint chapter for it.
- A phase's Lean is small or structurally simple enough that an
  upfront dep-graph adds no planning value.

Concrete recipe lives in `blueprint/CLAUDE.md`.

### Forward mode

The blueprint chapter is written as a *plan* before the Lean exists:
target definitions and theorems, intermediate lemma statements, and
`\uses{...}` chains based on the mathematical dependency graph. Each
entry starts **without** `\leanok`. As Lean lemmas land, the agent
adds `\lean{...}` and flips `\leanok` on. The dep-graph then doubles
as a live progress tracker — non-green nodes are the actual
remaining work.

When to use:
- A phase has not yet started and its proof structure is non-trivial
  enough that a visual dependency plan beats a flat ROADMAP list.
- A phase will span multiple sessions, so a shared visual plan
  amortizes the upfront cost across sessions.
- The mathematical reference is solid enough to write a credible plan
  from.

## Three options for forward mode

Within "forward mode" there are three concrete recipes, differing in
how much you write upfront:

| | Upfront cost | Mid-phase churn | End-of-phase cost |
|---|---|---|---|
| **A. Full forward** — chapter + prose proofs + `\lean{}` pins, all before any Lean | High | High (every Lean rename / split / merged lemma is a 2-file edit) | Low |
| **C. Hybrid skeleton** — chapter structure only: definitions, target theorems, intermediate lemma names, `\uses{}` chains. No `\lean{}`, no `\leanok`, no prose proofs | Medium | Low (mostly one-line additions as Lean lands) | Medium (prose proofs written at end, against stable Lean) |
| **B. Pure backfill** — chapter written end-to-end after the Lean is done | Zero | Zero | High |

(Letters are inherited from earlier discussion; A/B/C is not an
ordering.)

The **highest-churn pieces of the blueprint** are the `\lean{...}`
pins and the prose proofs. Lean names change as the API stabilizes;
prose proofs are most efficient to write once, against the final
shape of the Lean argument. Option A pays both costs twice; Option C
defers both to when the Lean is stable. The **dep-graph** is the
most valuable forward-mode artefact independently of those, and you
get it with just definitions + statements + `\uses{...}`.

**Selectivity (see below) further reduces Option C's churn**, because
the lemmas most prone to renaming are exactly the small API helpers
we would not blueprint in the first place. The case for selectivity
is **strongest in forward mode**: when you haven't yet written the
small bridge helpers, the question of whether to blueprint them
doesn't arise.

### Hybrid skeleton (Option C) — the forward-mode default

Option C is the recommended default for any forward-mode phase.

Workflow:

1. **Phase kickoff.** Agent drafts the chapter covering the phase's
   target direction. Draft carries: target theorem statement,
   intermediate definitions/lemmas, `\uses{...}` populated from the
   math, **no** `\lean{...}`, **no** `\leanok`, **no** prose proofs
   (or one-line gestures only). Commit, render dep-graph, human
   reviews.
2. **Each Lean session.** Agent picks a leaf-most red node in the
   dep-graph (a lemma whose `\uses{...}` chain bottoms out in green
   nodes or in axioms / mathlib facts), formalizes it in Lean, then
   adds `\lean{Namespace.name}` and `\leanok` to the blueprint
   entry. The dep-graph node turns green. One-line edit.
3. **Phase end pass.** Single focused pass to write 1- to 3-sentence
   prose proofs per blueprint entry, against the now-stable Lean.

## Selectivity: what goes in the blueprint

The blueprint is a reader's doc, not a 1:1 mirror of the Lean. The
default presumption is **exclude**; an entry must earn its slot by
clearing one of these bars:

- Defines a project-level concept.
- States a theorem a reader would name out loud.
- States a lemma with non-trivial mathematical content used at a
  phase boundary or feeding a main theorem.

Categories that are typically **excluded**:

- **Tautologies.** Lemmas that follow immediately from definition
  unfolding. Zero reader benefit.
- **Constructors and accessors.** Lemmas whose only job is to absorb
  membership or And-projection boilerplate at use sites. Their
  content is visible in the type signature.
- **Mirror lemmas under `{{PROJECT_NAME}}/Mathlib/`.** These are
  upstream-eligible facts about mathlib types. They are not project
  results; they belong upstream (and are tracked separately by the
  upstreaming dashboard). Excluded from the *main-line* chapters
  only — they land in per-module appendix chapters instead; see
  `blueprint/AUTHORING.md` *Blueprint appendices for mirror
  modules*.
- **Small bridge / glue lemmas.** Anything whose name or statement
  is likely to change as the API stabilizes. These are the
  **highest-churn** artefacts in the codebase, and including them in
  the blueprint creates two-file edits on every refactor.

### Why selectivity matters beyond reader experience

Selectivity is not just about readability — it also makes forward-
mode authoring much cheaper. The lemmas most prone to renaming /
restating during Lean work are exactly the bridge helpers we would
already exclude. So in principle, **a hybrid-skeleton forward chapter
should churn very little** during Lean work: the included entries
are the mathematical landmarks, which are stable by design.

The caveat is that a written blueprint chapter is robust against
pure infrastructure churn (renaming a constructor, splitting a glue
lemma) but **not** against the addition of new mathematically
significant lemmas mid-phase. Forward-mode skeletons should be sized
to accommodate growth in the latter.

### Heuristic for unclear cases

If you find yourself wondering whether a lemma deserves a blueprint
entry, ask: *would a reader thinking about the proof at a whiteboard
ever name this lemma?* If yes, include it. If no, it's API
infrastructure — leave it out.
