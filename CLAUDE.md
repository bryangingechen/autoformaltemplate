<!-- template-only:begin -->
> **Template-repo notice (stripped at instantiation).** You are in
> `autoformaltemplate`, the *template* this manual ships with — not an
> instantiated formalization project. Everything below describes the
> workflow of a project *created from* this template; the `{{…}}`
> placeholders are intentional and `lake build` does not work here.
> For work on the template itself (docs, workflows, the rename script,
> syncing lessons from downstream projects), the operative guide is
> `TEMPLATE.md` — its *Maintaining the template* section carries the
> sync workflow (boundary-finding, template-relevant paths,
> de-specialization rules, re-sync prompts, per-commit gates) and is
> required reading for a sync session. The only CI on this repo is
> `.github/workflows/template-ci.yml`, which smoke-tests
> `scripts/rename.sh` instantiation on every push. The per-session
> workflow, phase machinery, and hand-off contract below do **not**
> apply to template-meta work.
<!-- template-only:end -->

# CLAUDE.md — agent operating manual

This file is the **agent-facing operating manual** for working on
this project. Claude Code reads it automatically at session start.
Humans should start from `README.md` and `ROADMAP.md` instead.

This file covers project-wide process — reading order, hand-off
contract, citations, project history. Three subdirectory `CLAUDE.md`
files auto-load on demand when their subtree is touched and carry
the area-specific discipline:

- `{{PROJECT_NAME}}/CLAUDE.md` — Lean source ops (build/lint
  gates, friction review, MCP guidance, file-size triggers).
- `notes/CLAUDE.md` — phase-notes and friction-log discipline.
- `blueprint/CLAUDE.md` — blueprint TeX ops (static checks incl.
  `checkdecls` and the honesty/supersession gates, local builds,
  dep-graph spot-check, forward-mode rendering mechanics).

Project conventions (what the code looks like) live in `ROADMAP.md`
and `DESIGN.md`; tactical advice for Lean proofs lives in
`TACTICS-GOLF.md` (idioms / golfing) and `TACTICS-QUIRKS.md`
(symptom-indexed rescue — its *Symptom index* up top is the first
stop when a `lake build` fails with an unfamiliar error). The
discipline for **cleanup rounds** (between-phases or post-phase
audit passes — blueprint/Lean divergence, code-smell sweeps,
long-proof audits) lives in `CLEANUP.md`; read it when running such
a round or before opening a `notes/PhaseN-cleanup.md` work log.

Four further references are **read on demand, not session-start
orientation**: `PHASE-BOUNDARIES.md` (the full phase open/close
checklists — read at a phase boundary; the trigger summaries +
pointers stay in *Per-session workflow* below), `MODULE-SYSTEM.md`
(converting files to the Lean module system; debugging
`module`-related build failures), `blueprint/AUTHORING.md`
(blueprint TeX authoring conventions — annotation order, label
prefixes, citations, include-vs-skip, proof verbosity), and
`REFS.md` (reading the reference PDFs in `.refs/`). The auto-loaded
CLAUDE.md suite is a per-session token budget; when it grows,
extract to read-on-demand references like these rather than
deleting content (see the phase-close organization review).

## Reading order

Every session, in order:

1. **CLAUDE.md** (this file) — process.
2. **ROADMAP.md** — current status, directory layout, phase plan,
   and engineering conventions. The canonical hand-off doc.
3. **`notes/PhaseN.md`** for the active phase — lemma checklist,
   decisions made during that phase, hand-off notes. Required
   reading when picking up or finishing a phase. Reading this
   triggers `notes/CLAUDE.md` auto-load.
4. **`{{PROJECT_NAME}}/CLAUDE.md`** — auto-loads when an agent
   reads any `.lean` file under the subtree. Carries Lean-specific
   discipline.
5. **DESIGN.md** — only when you're about to question a
   cross-cutting decision. The default answer is *don't*.
6. **`notes/FRICTION.md`** — optional skim for an open
   upstream-eligible item to land alongside the session's main
   work. (Auto-loaded via `notes/CLAUDE.md` when an agent reads
   `notes/PhaseN.md`.)
7. **`blueprint/CLAUDE.md`** — auto-loads when the session reads
   blueprint TeX (writing a new chapter, updating a `\lean{...}`
   pin, flipping `\leanok` on a forward-mode entry as a lemma
   lands). `blueprint/DESIGN.md` carries the backfill-vs-forward
   workflow discussion.

The hand-off contract is: **`ROADMAP.md` + the active
`notes/PhaseN.md` should be enough to identify the next concrete
task** without reading any source file or commit history. If either
drifts from that guarantee, the friction-review step at end-of-
session is where you fix it.

## Per-session workflow

### Starting

1. Read CLAUDE.md, ROADMAP.md, the active `notes/PhaseN.md` (see
   *Reading order*).
2. `git log --oneline -20` to see what the last session did.
3. Identify the active phase from ROADMAP's Status table. If the
   phase has not started yet, open ROADMAP's planning section for
   that phase and create `notes/PhaseN.md` in your first commit
   (template in `notes/CLAUDE.md`).

> **Lean-touching sessions** also run a `lake build` sanity check
> on the leftmost active phase's file before editing — see
> `{{PROJECT_NAME}}/CLAUDE.md` *Starting a Lean-touching
> session*. Lean-specific working bullets (engineering conventions,
> friction review, build/lint gates, MCP guidance) live there too.

### Working

- Use `TaskCreate` for short-lived intra-session todos. They don't
  persist across sessions; use `notes/PhaseN.md` for anything that
  needs to outlast the session.
- **Forward-mode blueprint phases.** The active phase's blueprint
  chapter — typically a section of `blueprint/src/chapter/*.tex` — is
  the authoritative dep-graph and lemma index. Pick the leaf-most
  red node (no `\leanok`, dependencies all `\leanok` or mathlib
  facts), formalize it in Lean, then add/flip `\lean{...}` and
  `\leanok` on its blueprint entry in the same commit. Backfill
  mode writes the blueprint chapter end-to-end after the Lean
  lands; forward mode inverts that so the dep-graph doubles as the
  live to-do list. See `blueprint/CLAUDE.md` for rendering
  mechanics (`inv bp && inv web`), `checkdecls`, dep-graph
  spot-check, and authoring conventions; `blueprint/DESIGN.md` for
  the workflow-mode rationale.

  **Structural-edit phases** are the variant for refactor work that
  reshapes existing definitions or signatures rather than adding new
  ones. No new chapter is opened; the blueprint edits restate
  already-green nodes against the new shape in step with the Lean,
  distributed across the existing chapters. Forward-mode discipline
  still applies (the dep-graph IS the lemma index), but the to-do
  list lives in `notes/PhaseN.md`'s *Layer plan* section rather than
  a single blueprint chapter. Per-slice gate (two misses in
  enharmonic Phase 17): before committing a slice that changes a
  decl's *statement*, grep `blueprint/src/` for that decl — when the
  `\lean{...}` name survives the flip, `checkdecls` cannot catch a
  node still stating the legacy form; restate it in the same commit.
- **Every commit is a potential handoff point.** Treat each commit
  as if the session could end on it. The pre-commit checklists
  below (*keep the hand-off contract honest*) and the Lean-side
  one (*friction review* in `{{PROJECT_NAME}}/CLAUDE.md`) run
  on every commit, not just the last one of a session — there is
  no special "session-end" work that doesn't already fall out of
  doing those well on each commit. Phase-completion work is the one
  genuine exception: that fires on the commit that closes a phase,
  whenever in the session it lands, and is documented separately
  under *When this commit closes a phase*.
- **Substantive progress per commit; recover wrapper-churn via a
  planning commit.** Diagnostic: if a chain ships >3 consecutive
  commits with ≤10-LoC proofs that mostly alias existing mathlib
  facts, pause and audit whether the trajectory is approaching the
  headline or just accreting token API surface. The recourse is a
  **planning commit** — convert the remaining work into sub-lemma
  skeletons (full statements + prose proofs + any design-decision
  asides) in one commit, so subsequent commits close one substantive
  skeleton each rather than another wrapper. Skeleton statements
  carry undischarged cruxes as explicit `h…` hypotheses, never
  `sorry` bodies — the `block-sorry-commit.sh` hook denies
  sorry-adding commits (see `{{PROJECT_NAME}}/CLAUDE.md` *build and
  lint gates*). When
  laying out sub-lemmas, fold mechanical assembly (an `iff`
  combining two halves, finite-union closure) into substantive
  predecessors rather than splitting them as separate "assembly
  commits".
- **State the handoff state in one sentence after each commit.**
  Once a commit lands, write one sentence to the user: either
  *"clean handoff point; next agent picks up at X"* or
  *"intentionally mid-step; if you stop me now, Y is the loose end."*
  Cheap, lets the user judge whether to stop or continue without
  the agent unilaterally drawing a session boundary.
- **Commit attribution.** Match the author identity of existing
  commits exactly: `git -c user.name=… -c user.email=… commit …`;
  never write to git config, and do **not** substitute an email from
  session context (the harness-injected user email may differ from
  the project identity). In the `Co-Authored-By:` trailer, name the
  model *actually generating the commit* — check your own model
  identity rather than copying the trailer from recent `git log`
  (history may have been authored by a different model). Write the
  model name in display form (`Claude Sonnet 4.6
  <noreply@anthropic.com>`), not the model-id form
  (`claude-sonnet-4-6`).
- **Pushing to `master` triggers a Pages deploy** (blueprint, docs,
  upstreaming dashboard via `leanprover-community/docgen-action`).
  PRs run the same build but skip the deploy step. There is no
  separate "deploy when ready" knob — every green master push
  publishes.
- **Automated GitHub Actions bumps** arrive as a single monthly
  grouped PR from Dependabot (`.github/dependabot.yml`), titled
  something like "Bump the github-actions group with N updates".
  Merging it usually requires only running CI green; do not bump
  the pins by hand between cycles unless there's a specific reason
  (security fix, action removed, etc.).

### Before each commit — keep the hand-off contract honest

The contract: **ROADMAP.md plus the active `notes/PhaseN.md` should
be enough to identify the next concrete task** without reading any
source file or commit history. Every commit's tree should satisfy
this, since every commit is a potential session boundary.

In the same commit as the friction review (Lean commits) or the
content change (docs commits):

- **Update `notes/PhaseN.md`** — the active phase's *Current state*,
  *Decisions made*, *Blockers*, and *Hand-off / next phase* sections,
  so they reflect what this commit changes. A 2-line edit is fine;
  silence is not. When writing *Hand-off / next phase*, name the
  **smallest concrete commit** that moves work forward, not the full
  target theorem. If you genuinely don't know whether the next lemma
  is one session's work or three, say so explicitly.
- **Move deferred items to where they will land.** A lemma punted
  from Phase 2 to Phase 3 belongs in Phase 3's "Lemmas to develop"
  list with a one-line rationale, not as a footnote in Phase 2.
  Forward-looking TODOs stranded under closed phases rot.
- **Lift on promotion.** If a `notes/PhaseN.md` decision has been
  referenced in 2+ files or by 2+ phases, promote it to
  `TACTICS-GOLF.md` (general idiom), `TACTICS-QUIRKS.md` (rescue
  pattern), or `DESIGN.md` (cross-cutting rationale) and replace
  the Phase N entry with a one-line pointer. Cross-cutting lessons
  that stay in phase notes rot — this is the rule that prevents
  Phase notes from accumulating into 500-line documents.
- **Compress in-commit, not in a cleanup round.** If this commit
  tips the phase note's finished part (*Decisions made*) past its
  forward part, or trips the ~500-line tripwire (see
  `notes/CLAUDE.md` *Forward-weighted note*), rebalance **now**.
  Deferring to a cleanup round means the verbose intermediate gets
  written, re-read next session, and re-compressed — three context
  costs for one durable paragraph.
- **If you answered a "Choices to revisit" entry** in `DESIGN.md`,
  update it.

**Sanity check before commit:** re-read the active phase's ROADMAP
section. If you can't summarize the next agent's first task in one
sentence, the section needs more compression or more pointer
discipline.

### When this commit opens a phase

Phase opening fires on the first commit that turns the new phase on —
typically the commit that creates `notes/PhaseN.md` and either
(forward mode) opens the new phase's blueprint chapter or
(structural-edit mode) lays down the *Layer plan*. **The full
phase-open checklist** — the ROADMAP row + §N planning section, the
sub-lettered-phase codes-until-open convention, the user-facing
status-surface sync (README + home_page + intro.tex +
formalization.yaml, with its reader-facing jargon-free discipline),
the cross-phase program-doc sync, and the red-node consistency gate —
lives in **`PHASE-BOUNDARIES.md` *When this commit opens a phase***
(read it at a phase open). It is on top of the per-commit checklists
above.

### When this commit closes a phase

Phase completion fires regardless of where in a session it happens —
the commit that takes the last red node green for a phase (or
otherwise discharges the phase's target). **The full phase-close
checklist** — flip + re-thin the ROADMAP row, compress the §N
planning section, sync the user-facing status surfaces (incl.
`formalization.yaml` alignment via `#print axioms`), the end-to-end
blueprint-chapter re-read + crux-node expositions, working-doc-tail
compression, and the project-organization review — lives in
**`PHASE-BOUNDARIES.md` *When this commit closes a phase*** (read it
at a phase close), including the **sub-phase close vs full-phase
close** carve-out. It is on top of the per-commit checklists above.

## Referencing prior work

Cite the originator of every non-trivial mathematical claim, and
verify each citation against a primary source before writing it.
**Both halves matter.** The verification half is well-understood;
the citation half is the new one — a hallucination is not the only
way to mis-credit a result. Silently omitting an attribution
("this is the standard approach", "by the classical Maxwell-type
argument") is just as bad as a wrong one, because the next reader
has no anchor to verify against and the prose reads as if the
project owns work it doesn't.

Concretely, **proactively scan your blueprint / notes / commit-
message prose before commit** and ask, for each substantive
mathematical step:

- Whose result is this? (A named theorem, a classical lemma, a
  technique attributed in standard references.)
- Have I cited it? If "no", does this commit cite something else
  that subsumes it (e.g., the blueprint chapter's section preamble),
  or am I silently asserting the result?
- If "yes" — verify the citation per the bar below before commit.

The bar to *add* a citation is low; the bar to *leave the prose
uncited* should be high. When in doubt, cite the standard reference
and let the next reviewer judge whether it's needed.

The verification bar:

Hallucinated section pointers (e.g. *"Whiteley §3"* with no paper
specified) and mis-attributions (crediting a populariser or
surveyor instead of the original prover) are the failure modes — once
written down they propagate through future sessions and read as
authoritative.

The minimum bar:

- **Author + year resolve to a real publication.** Confirm title,
  journal/series, volume, and page range against a primary source
  (DOI landing page, publisher metadata, NASA ADS).
- **"X §N" references hold.** §N must exist in X and contain what
  you claim. If you cannot quickly verify, write *"classical"* or
  *"see X for a survey"* without a section number rather than guess
  one.
- **Attribution names who proved the result.** A survey or textbook
  is fine as a *"presentation we follow"* pointer alongside the
  primary citation, not in place of it.

### Reading PDFs in `.refs/`

Reference PDFs accumulate under `.refs/` (gitignored). The how-to
for reading them (pypdf inside the blueprint venv when the `Read`
tool lacks poppler; the page-offset caveat) lives in `REFS.md` —
read on demand when consulting a PDF, not session-start orientation.

## Project-history note

<!-- Replace this section with a one-paragraph history of where the
project came from: original repo, lift / fork commit, any
restructuring that's relevant to interpreting git log. Delete the
placeholder if the project starts fresh. -->

TODO: project-history paragraph.

<!-- If the project ever vendors code from another repository (e.g. a
subsystem ported from an Apache-2.0 Lean package), add a "Vendored
provenance" paragraph here: name the upstream package and license,
give every vendored file a copyright header with a provenance +
modifications note, and record the attribution discipline in
DESIGN.md. Delete this comment otherwise. -->
