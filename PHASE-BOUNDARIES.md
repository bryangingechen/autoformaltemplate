# PHASE-BOUNDARIES.md — phase open/close checklists

**Read-on-demand reference, not session-start orientation.** These are
the detailed checklists that fire **only at a phase boundary** — a
handful of times across a whole (often multi-sub-phase) phase, yet they
would otherwise load on every one of the dozens of build/commit
sessions in between. So they are extracted here from the top-level
`CLAUDE.md` *Per-session workflow*, leaving a short trigger-summary +
pointer there (the same per-session-token-budget discipline that
produced `REFS.md` and `MODULE-SYSTEM.md`).

**Read this file when a commit opens or closes a phase.** The section
titles below match the `CLAUDE.md` stubs verbatim, so cross-references
of the form *"CLAUDE.md *When this commit opens/closes a phase*"*
resolve here for the full checklist. These checklists are **on top of**
the per-commit checklists in `CLAUDE.md` *Before each commit — keep the
hand-off contract honest* (and the Lean-side friction review in
`{{PROJECT_NAME}}/CLAUDE.md`).

## When this commit opens a phase

Phase opening fires on the first commit that turns the new phase
on — typically the commit that creates `notes/PhaseN.md` and either
(forward mode) opens the new phase's blueprint chapter or
(structural-edit mode) lays down the *Layer plan* that drives the
in-place restate of existing chapters. On top of the per-commit
checklists:

- Add or update the phase's row in the ROADMAP Status table (status:
  *planning* or *in progress*) and write the §N planning section. **The
  table cell is a thin pointer** — status marker + at most one short
  scope clause + `(see notes/PhaseN.md)`. The §N prose is the single
  per-phase summary home; never restate the §N summary inside the cell.
- Create `notes/PhaseN.md` from the template in `notes/CLAUDE.md`.
- **Sub-lettered phases — codes until open, no umbrella note.** When a
  phase is large enough to break into sub-phases, do **not** pre-assign
  letters to the not-yet-opened ones: a premature letter
  renumber-churns every cross-reference the moment a layer splits.
  Instead — (a) track the layers by **stable codes** (e.g.
  `CARRIER`/`CHAIN`/`ENTRY`/`ASSEMBLY`) in the phase's **design doc**
  `notes/PhaseN-design.md`, the cross-phase plan/recon home; (b) **mint
  a letter (`Na`) + a per-sub-phase work log `notes/PhaseNa.md` only
  when a sub-phase is about to open** — so the first commit of a
  sub-lettered phase creates the opening sub-phase's log, **not** an
  umbrella `notes/PhaseN.md`. A sub-letter is minted only when its turn
  comes. (Calibration: a CombinatorialRigidity phase opened with a
  recon sketching sub-phases a–d; the labels were recoded to stable
  codes the same day, minting only the open layer's letter.)
- **Sync the user-facing status surfaces** so the project's
  externally-visible state reflects that Phase N is now in progress:
  - `README.md` — *Project status* prose.
  - `home_page/index.md` — *Project status* prose and the phase
    table (add the new row).
  - `blueprint/src/chapter/intro.tex` — §*Phase plan* prose and the
    enumerate (add the new bullet); update the dep-graph-status line
    at the end of the section if relevant.
  - `formalization.yaml` — `status.scope` if the new phase changes
    the in-progress description; add any new `sources` entries the
    phase introduces.

  These are the project's public face (the first three render to
  GitHub Pages on every master push); let them drift and the website
  + README silently misrepresent project state. Confirm Phase N-1's
  status on each surface at the same time — if the previous phase
  closed without flipping these, do it here.

  **They are reader-facing summaries, not a status log — give them the
  forward-weighted, jargon-free discipline the phase notes get:**
  - *Register.* They address a domain reader (intro.tex) or a project
    visitor (README, home_page), not an agent mid-phase. Banned:
    agent-process jargon — `green-modulo-N`, `design-pass-first`,
    `axiom-clean`, `re-scoped`, sub-phase blow-by-blow
    (`22a … 22b … 22c …`), and raw blueprint labels in prose. State
    status at the arc / chapter level; the dep-graph's green/red is
    the fine-grained status, the prose is not.
  - *Sync = re-summarize, not append.* Flipping Phase N also folds the
    now-closed phases back into the arc / chapter-level summary; only
    the active frontier earns a sentence or two. The detail lives in
    ROADMAP §N, `notes/PhaseN.md`, and the dep-graph — these surfaces
    *point there* (one canonical home per content type). The
    orientation prose is fixed-size: a paragraph added per phase means
    you are logging status, not summarizing. (Calibration: all of
    CombinatorialRigidity's surfaces had ballooned into per-sub-phase
    essays by Phase 22d and were rebuilt to an arc-level summary.)
- **Cross-phase program docs that no CI/checkdecls gate covers** must
  also be synced at the boundary, or they silently drift (a
  CombinatorialRigidity sub-phase closed with the program map still
  showing the prior phase in-progress). If the project keeps a
  `notes/<program>.md` map spanning several phases, sync its phase
  table + next-phase pointer here. It is the **program map**, not a
  per-phase detail surface — its per-phase entries are
  one-paragraph-max and point at ROADMAP §N / `notes/PhaseN.md`
  (`notes/CLAUDE.md` *One canonical home per content type*).
- **Read the target red/deferred nodes end-to-end for internal
  consistency *before* scoping the build (the red-node consistency
  gate).** When a phase opens to build specific already-stubbed
  blueprint nodes, read *those target nodes* in full — not just their
  statements — and confirm each is self-consistent: the **proof routes
  through the same argument the statement claims**, and **no
  live-route reference (`\uses` or a live-proof step) points at a
  superseded node** (see the honesty/supersession gates in
  `blueprint/CLAUDE.md`). Red nodes fall through the `\leanok`-gated
  honesty gate, so this is the only point that forces a re-read of a
  deferred node's *proof* before work builds on it. (Calibration:
  CombinatorialRigidity Phase 22c opened on target nodes whose
  statements said a route was superseded while their *proofs* still
  routed through the dead ends — rot that had survived since the route
  was corrected phases earlier, caught only by this re-read.)

## When this commit closes a phase

Phase completion fires regardless of where in a session it happens.
The commit that takes the last red node green for a phase (or that
otherwise discharges the phase's target) carries extra work *on top
of* the per-commit checklists:

> **Sub-phase close vs full-phase close — read this first.** A
> sub-lettered phase closing (e.g. `23f` within an umbrella Phase 23)
> is a **sub-phase close**, *not* a full-phase close, and the checklist
> below adapts. The full-phase close — flip the ROADMAP row to ✓, fold
> the whole §N planning section into one paragraph, write the now-final
> blueprint expositions, and re-summarize every user-facing surface —
> fires only at the **umbrella-phase close**. At an **intermediate
> sub-phase close**, instead:
> - **ROADMAP row stays at its umbrella status** — do **not** flip it
>   to ✓. Advance the umbrella cell's **sub-phase marker** (mark the
>   just-closed sub-phase done, name the next) and re-thin the cell to
>   a pointer.
> - **§N planning section:** compress only the *just-closed
>   sub-phase's* detail to a short summary + pointer; leave the
>   still-open sub-phases' planning intact.
> - **User-facing status surfaces:** these deliberately carry status at
>   the arc/chapter level with no sub-phase markers, so a sub-phase
>   close usually needs **no edit** to them — only the umbrella-phase
>   close does. (Always still sync the cross-phase program doc, which
>   *does* track sub-phases.)
> - **Blueprint re-read:** a node whose argument spans multiple
>   sub-phases stays pending — do **not** write its fuller exposition
>   at an intermediate sub-phase close; the clean account isn't final
>   until its deferred piece is discharged.
> - The **working-doc-tail compression** and **project-org review**
>   items fire per the (sub-)phase — same as a full close.

- Flip the phase's row in the ROADMAP Status table to ✓ and **re-thin
  the cell to a pointer** if it grew during the phase (status + ≤1
  short scope clause + `(see notes/PhaseN.md)`).
- **Compress its §N planning section in ROADMAP** to a one-paragraph
  summary plus a pointer to `notes/PhaseN.md`. The §N prose is the
  *single* per-phase summary home (the table cell stays a pointer, not
  a second copy). The lemma list and decisions live in
  `notes/PhaseN.md`.
- **Sync the user-facing status surfaces.** Same surfaces, same
  discipline (reader-facing summary; jargon-free; re-summarize, don't
  append) as the phase-open subsection above: `README.md` *Project
  status*, `home_page/index.md` *Project status* + phase table,
  `blueprint/src/chapter/intro.tex` §*Phase plan* + enumerate
  (including the dep-graph-status line), and `formalization.yaml`.
  Flip Phase N's marker to ✓ on each and fold the just-closed phase's
  detail back into the summary. In `formalization.yaml`, update
  `status.scope`, add the phase's headline theorem to
  `status.main_results` and `alignment` (verified with `#print
  axioms`), and record any new `fidelity` divergences — backfilling
  that file at project end loses exactly the per-phase detail it
  exists to capture. Plus any cross-phase program doc — see the
  phase-open subsection.
- **Re-read each new/edited blueprint chapter end-to-end as a domain
  mathematician** and collapse accumulated per-commit formalization
  asides. Forward-mode chapters are written one node at a time by
  separate per-commit subagents, each of which tends to narrate its
  own modelling choice ("formalized basis-free via …"); read in
  sequence these accrete into changelog-not-math prose. One
  end-to-end pass at phase close catches them while the chapter is
  fresh, rather than a cleanup round later. This pass is also where
  any crux-node expositions get written (see `blueprint/CLAUDE.md`);
  for larger projects, an exposition *ledger* note that flags crux
  nodes as they surface mid-phase (one line each) and gets discharged
  at phase close is a proven pattern (CombinatorialRigidity
  `notes/BlueprintExposition.md`).
- **If the model-tier dispatch experiment is running and this phase is
  its testbed**, write the phase's *Findings* close-out and archive the
  closed (sub-)phase's log rows per `notes/model-experiment.md`'s own
  upkeep notes, so the coordinator's every-dispatch read of the live
  file stays small. (Calibration: a CombinatorialRigidity sub-phase
  closed without archiving and ~180 stale rows accumulated in the
  every-dispatch read until the next cleanup.)
- **Compress the just-closed (sub-)phase's working-doc tails — in
  place, at the close.** Two in-place shrinks (both keep the
  every-session reads small): **(a)** the phase's *design doc*
  (`notes/PhaseN-design.md`) — collapse the just-closed (sub-)phase's
  recon arcs to cited verdicts, *preserving* the still-live arcs, the
  frozen contract, and every source citation (the blow-by-blow stays
  in git); **(b)** the closing phase note's settled *Decisions made*
  tail → one-line verdicts, per `notes/CLAUDE.md` *Forward-weighted
  note* — the backstop for the per-commit compress-in-commit rule when
  it slipped during the phase. Verify the live content survives
  (preserved sections byte-identical; cross-referenced decl names /
  §-labels / citations still resolve) before trusting the cut.
  (Calibration: skipping (a) let a CombinatorialRigidity design doc
  reach ~7,600 lines / ~167k tokens.)
- **Review project organization.** Re-skim ROADMAP.md,
  `TACTICS-GOLF.md`, `TACTICS-QUIRKS.md`, and `notes/FRICTION.md`
  (status sections). Have decisions in `notes/PhaseN.md` accumulated
  past the lift-on-promotion threshold? Has FRICTION.md grown
  unscannable? Is any DESIGN.md / ROADMAP.md prose-count or
  section-name reference stale? **Audit the auto-loaded CLAUDE.md
  suite for bloat** (the root file + the three subdirectory ones):
  every session pays their token cost at start; when a section has
  grown past orientation size, extract it to a read-on-demand
  reference (the `MODULE-SYSTEM.md` / `blueprint/AUTHORING.md` / this
  file's pattern), don't delete it. Apply the small fix in this
  commit if obvious; otherwise file a project-organization friction
  entry to address next phase. This step is what keeps the docs from
  drifting between phase boundaries.
