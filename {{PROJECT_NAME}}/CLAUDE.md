# {{PROJECT_NAME}}/CLAUDE.md — Lean source operating manual

This file is the **agent-facing operating manual** for working with
the project's Lean source. It auto-loads when an agent reads any
`.lean` file under this directory.

Top-level `../CLAUDE.md` covers project-wide process (reading order,
hand-off contract, citations, project history). This file carries
the Lean-specific discipline: build/lint gates, friction review,
MCP tool guidance, and pointers into the symptom-indexed quirks
reference (`../TACTICS-QUIRKS.md` *Symptom index*).

For the blueprint side (TeX, dep-graph, `checkdecls`, `inv bp`/`inv
web`), see `../blueprint/CLAUDE.md`. For notes/phase-log discipline,
see `../notes/CLAUDE.md`.

## Reading order

In addition to the project-wide reading order in `../CLAUDE.md`:

- **`../TACTICS-QUIRKS.md`** — rescue reference, symptom-indexed.
  Skim its **Symptom index** at session start. When a build fails
  with an unfamiliar Lean error, that index is the first place to
  look — the bullets map error symptoms to the named § for the fix.
- **`../TACTICS-GOLF.md`** — golfing / improvement reference. Read
  at cleanup time (when the `simplify` skill fires, or when
  shrinking/polishing a proof before commit), **not** during
  first-draft writing — *except* the first-draft-shaping closers
  flagged below (*Reach for stronger tactics during first-draft
  writing*) and § 4 (Lean LSP MCP — see *Lean LSP MCP — reach for
  it* below).
- **`../notes/FRICTION.md`** — optional skim for an open
  upstream-eligible item to land alongside the session's main work.
- **`../MODULE-SYSTEM.md`** — operational reference for converting
  a project file to Lean's module system (`module` + `public import`
  + `@[expose] public section`), including the constraints /
  gotchas / `backward.privateInPublic` technical-debt rules. Read on
  demand — when converting a file or debugging a `module`-related
  build failure — not as session-start orientation.

## Starting a Lean-touching session

In addition to the universal Starting steps in `../CLAUDE.md`
(read CLAUDE.md / ROADMAP.md / `notes/PhaseN.md`; `git log
--oneline -20`; identify the active phase):

- `lake build {{PROJECT_NAME}}.<active-phase-file>` (the leftmost
  active phase's file) to confirm the tree still compiles cleanly
  on its own before touching anything.

## Engineering conventions

Where lemmas live, namespace policy, `Set.ncard` vs `Finset.card`,
decidability, etc. — the authoritative list is in
`../ROADMAP.md` "Engineering conventions". Follow it.

- When you add a lemma, put it in the file that introduces the
  relevant *definition*, not the file that first uses it.

## File-size signals (in-phase structural triggers)

A phase file approaching **~2000 lines or ~40 declarations** is a
likely signal that one or more mathlib-affinity-distinct theories
are getting bundled into a single file. (An ancestor project let a
phase file reach 5600+ lines / 87 declarations before noticing —
past the point where smell-sweeping in place could work.)

**Trigger.** When the active phase file crosses ~2000 lines or ~40
declarations, **pause before adding the next decl** and run a
classification walk on what's already there:

- Walk each non-trivial declaration; for each, ask whether the
  statement and proof use any project-specific hypothesis (a
  project structure, a project predicate, etc.).
- If no — the declaration is parameterised entirely by abstract
  inputs (`Submodule`, `Matrix`, `Finset`-sum, `ContDiff`, etc.) —
  it is mirror-eligible and belongs under
  `{{PROJECT_NAME}}/Mathlib/<exact upstream path>`. Open the mirror
  module in the same commit as the decl that would have crossed
  the threshold, not as a post-phase cleanup round.
- If yes — but the project-specific hypothesis is mechanical (e.g.
  the lemma's body is "unfold definition, apply abstract lemma")
  — the abstract part lifts to a mirror; the project-specific
  wrapper stays in the phase file.
- If the classification surfaces a clean exposition seam (e.g.
  two coherent sub-theories sharing one file) — open a sibling
  exposition file (`{{PROJECT_NAME}}/<topic>.lean`) in the same
  commit as the decl that would have crossed it.

The cost of a mid-phase split is one careful commit; the cost of a
post-phase restructure is a multi-task cleanup round (an ancestor
project's post-phase round ran six splits + matching blueprint
appendices, spread across many sessions). The asymmetry is the
whole reason for the trigger.

**The same classification applies at chain-opening time, not only
at threshold.** When opening a substantive mirror chain — a family
of upstream-eligible lemmas planned to land under a single mirror
file across multiple commits — run the classification on the
*planned* sub-lemmas before landing the opener. If they classify to
**≥2 distinct upstream destinations** (e.g. some algebraic, some
topological, some analytic), split at opening — the threshold rule
otherwise fires later and the cleanup is still owed.

## Reach for stronger tactics during first-draft writing

`../TACTICS-GOLF.md` is read at cleanup / golfing time per its own
header — *not* during first-draft writing. That timing is right
for golfing rules but leaves a gap for tactics whose payoff is
*don't write the manual chain in the first place*. The first-draft
reminder for three under-used closers:

- **`grind` before stacked `omega` / `linarith` / `simp; ring`
  closers.** Default to `grind` (then `grind?` once on success,
  pin as `grind only [...]`) for any goal whose final step is
  "use a handful of facts in scope to close arithmetic with
  equalities". `../TACTICS-GOLF.md` § 1.
- **`gcongr` before manual `mul_le_mul_of_nonneg_*` / `add_le_add`
  / `mul_lt_mul_of_pos_*`.** Default to `by gcongr` (or `by gcongr;
  exact <positivity-hint>`) for any goal whose final step is a
  monotonicity-chain rewrite with a shared outer function (`*`,
  `+`, `^`, …) and an inner ≤/< hypothesis in scope.
  `../TACTICS-GOLF.md` § 7.
- **`fun_prop` before manual `ContDiff.comp` / `ContDiffAt.comp` /
  `Differentiable.comp` chains — *but not* before value-form
  `HasDerivAt.comp_of_eq` / `HasFDerivAt.comp` /
  `.congr_of_eventuallyEq`.** `fun_prop` handles property-form
  goals (`ContDiff 𝕜 n f`, `Continuous f`, `Differentiable 𝕜 f`);
  value-form derivative goals stay on the named API (the
  discharger cannot synthesize a chain-rule derivative term that
  unifies with a goal-specific derivative).
  `../TACTICS-GOLF.md` § 3.

All three dischargers share a `∀`-quantified-hypothesis limitation
— pre-extract a per-index `have hX_e : … := hX e` when the
precondition needs it. **Cheap A/B test:** `lean_multi_attempt`
fires several candidates against a proof position in one MCP
round-trip — see *Lean LSP MCP* below.

## Lean LSP MCP — reach for it

`.mcp.json` at the repo root registers
[`lean-lsp-mcp`](https://github.com/oOo0oOo/lean-lsp-mcp); approve
the server on first prompt. File paths resolve against the project
root. **An MCP call is sub-second; an `edit + lake build` cycle is
30+ seconds — the cost asymmetry is the whole point.** Whenever you
would otherwise edit-and-rebuild to inspect an intermediate goal
(`lean_goal`), hunt for a mathlib lemma (`lean_loogle` /
`lean_leanfinder`), read an upstream signature (`lean_hover_info`),
check the project's own API for a name (`lean_local_search`), or
guess at a closing tactic (`lean_multi_attempt` A/B-tests several
candidates in one round-trip) — reach for the MCP first. Full
decision tree, cold-start details, and `lean_multi_attempt` payload
shape: `../TACTICS-GOLF.md` § 4.

Run `lake build` once before the first MCP call (warms `lake
serve`); skip if you've built recently this session. Two caveats:

- **Do not call `lean_leansearch`** — its endpoint has been down
  since late 2025; use `lean_loogle` / `lean_leanfinder` instead.
- **`lean_verify`'s axiom report can be stale** — it can report a
  phantom `sorryAx` on a genuinely sorry-free decl (stale LSP
  cache). A **warning-clean `lake build` is authoritative** for "no
  `sorry`" (Lean always emits a `declaration uses 'sorry'` warning
  for a real one), as is `#print axioms` against the freshly-built
  olean. Check `lean_diagnostic_messages` / re-run before believing
  a phantom report.

## Editing a patchable fork of a Lake dependency (optional pattern)

Some projects pin a non-mathlib Lake dependency to the user's own
fork precisely so the project can patch it. When that applies:
prefer the project-side route first (project source or a
`Mathlib/<exact path>` mirror — it travels with the project). The
checkout under `.lake/packages/<pkg>/` is a **separate git repo**:
edit + commit in *its* history, and never push the fork or bump its
`rev`/`inputRev` pins unprompted — both are outward-facing; surface
them as a follow-up. Flag any pending fork edit in the commit
summary and the active `notes/PhaseN.md`: a local-only fork edit
doesn't travel with a `git push` of this repo until the pin bumps,
so an unflagged one silently breaks the build for the next checkout.

## Before each commit — friction review (mandatory)

Before each commit that touches Lean code, do a **friction review**.
It is what keeps the project's API gaps from accumulating silently.

1. **Re-read the lemmas this commit adds or changes.** For each one:
   - Did any rewrite chain feel longer than it should have?
     (Two-rewrite glue lemmas — `coe_X` then `card_X` — are the
     usual culprit.)
   - Did `grind` need an unusually long hint list, or fail in a way
     you worked around rather than understood?
   - Did you hit a deprecation, missing simp lemma, or awkward
     typeclass dance?

   **Concrete signals.** Friction almost certainly happened if you
   wrote any of the following — each is a candidate FRICTION entry,
   not a "standard idiom" to dismiss:
   - `change` or `show` to make `rw` / `simp` find a pattern (the
     un-reduced lambda or `def`-predicate is the gap).
   - A multi-rewrite chain (3+ `rw` arguments) for one mathematical
     step — usually a missing fused lemma.
   - A manual `have h : <unfolded body> := h_predicate` to surface a
     `def`-predicate's content for `omega` / `grind`.
   - `omega` or `nlinarith` failed and you added a numeric hint, a
     `ring`-normalized rewrite, or a manual `mul_comm`.
   - Two `rw` lemmas to bridge a single conversion (e.g. `coe_X` then
     `card_X`, or `Set.ncard_eq_toFinset_card'` then
     `Set.toFinset_card`) — usually a one-line mirror.

   **Bar is low.** Anything that took a build-failure → fix iteration
   deserves at minimum a one-line FRICTION entry, even if the fix was
   "obvious in hindsight". The next agent doesn't have your
   hindsight.

2. For each genuine instance:
   - If the missing lemma is **upstream-eligible** (a fact about
     `SimpleGraph`, `Set.ncard`, `Finset`, etc., not specific to the
     project's mathematics), mirror it under
     `{{PROJECT_NAME}}/Mathlib/<exact mathlib path>` in this commit.
     The Lean namespace stays the upstream one. See `../DESIGN.md`
     "Mirror directory" for the mechanics; refactor the calling proof
     to use the new mirror lemma.
   - If it's **project-internal**, put it in the file that owns the
     relevant definition.
   - In all cases, add an entry to `../notes/FRICTION.md` (open or
     resolved/mirrored as appropriate). Even a one-line entry is
     valuable.
   - **If the entry carries a *general lesson*** (a rule that
     applies beyond this proof — a `subst`-direction trap, an
     `omega`-atomicity gotcha, a "search before mirroring"
     reminder, etc.), lift it to `../TACTICS-GOLF.md` (golfing
     idioms) or `../TACTICS-QUIRKS.md` (build-failure rescue) *in
     the same commit* and add a `**Lifted to:** TACTICS-GOLF § X`
     or `**Lifted to:** TACTICS-QUIRKS § X` cross-reference on the
     FRICTION entry. Don't bury the general rule in a `[resolved]`
     body.

3. **No new entries this commit is fine** — but only after you've
   walked the *Concrete signals* checklist above. "I didn't hit any"
   is fine; "I didn't think about it" is the failure mode this rule
   exists to prevent.

## Before each commit — build and lint gates

**Run both `lake build` and `lake lint`.** Both are CI gates (see
`../.github/workflows/push_pr.yml`); a failing lint blocks merge as
surely as a failing build. The full-project linter (`runLinter`)
catches `simpNF` and `unusedArguments` issues that the compile-time
`mathlibStandardSet` linter misses, so don't skip it. Both commands
are exactly as written — `lake lint` takes **no arguments**
(`lake lint <Module>` fails with `unexpected arguments`). If a lake
invocation errors on syntax, re-read this section or `lake help`;
do **not** guess flags.

### Build discipline — one build, never `lake update`

These rules exist because a downstream session OOM-crashed its
machine (enharmonic, 2026-06-10) when a subagent guessed
`lake build --update` as "lint syntax", silently rewrote
`lake-manifest.json` + `lean-toolchain` to mathlib master, then
piled up concurrent from-source mathlib builds trying to recover.
A PreToolUse hook shipped with the template
(`../.claude/hooks/block-lake-update.sh`, wired in
`../.claude/settings.json`) blocks `lake update` / `--update`
mechanically; the prose rules are the portable layer:

- **Never run `lake update` or any lake command with `--update`.**
  Toolchain and dependency bumps are a human decision and arrive
  via the hopscotch workflow (next section), never mid-session.
- **One `lake build` at a time, in the foreground.** Never start a
  second build while one is running, never poll a slow build by
  re-running it in a loop, never `&`-background a build inside a
  Bash call (it gets orphaned), and never `pkill` lake (it orphans
  the `lean` worker processes). If a build is slow, run it once
  with a generous timeout and wait. A full mathlib rebuild is
  **never** expected here — if `lake build` starts compiling
  thousands of mathlib files, stop immediately and report; do not
  wait it out or retry.
- **`lean-toolchain` or `lake-manifest.json` modified in
  `git status`?** Something has gone wrong. Stop, report, and let
  the human decide; do not build on top of it and do not commit it.

**A green build is not enough — the build must be _warning-clean_.**
`lake build` exits 0 even when it emits compile-time `linter.*`
warnings (`unusedSimpArgs`, `flexible`, `unusedDecidableInType`,
`unusedFintypeInType`, …), and these are **not** caught by `lake lint`
/ `runLinter` — the two linter families are disjoint. So "build green
+ `lake lint` clean" can still leave warnings riding in a commit (an
ancestor project shipped warnings into a vendored-port commit through
exactly this gap). **Before each commit, scan the full `lake build`
output for `warning:`** (e.g. `lake build <module> 2>&1 | grep -nE
'warning:'`) and drive the count to zero. Touch the file first
(`touch X.lean`) if the build is cached, since cached modules don't
re-emit warnings.

The `declaration uses 'sorry'` warning is the no-sorry gate's signal —
**a `sorry` never rides in a commit**; carry an undischarged crux as an
explicit `h…` hypothesis instead. A PreToolUse hook
(`../.claude/hooks/block-sorry-commit.sh`, wired in
`../.claude/settings.json`) mechanically denies any `git commit` whose
`.lean` diff vs HEAD adds a `sorry`/`admit` — added after a long
context-compacted session committed a sorry'd skeleton with a false
"gates clean" attestation (CombinatorialRigidity 2026-06-10);
prompt-level discipline does not survive compaction, hooks do.

**Fix warnings at the source; never paper over them.** The
fix-precedence order is:
1. **Solve it at the source** — drop the genuinely-unused simp arg;
   convert a `flexible` `simp […]` to `simp only […]` (or `suffices`);
   drop an unused `[Decidable…]`/`[Fintype…]` hypothesis and open the
   body with `classical` / `haveI := Fintype.ofFinite _` where a proof
   step actually needs it. This is almost always the right answer,
   including in vendored ports — a style sweep there is low-risk and
   keeps the project warning-clean.
2. **`@[nolint …]` / `set_option linter.X false` only with a
   justification _and_ only when the warning is a genuine false
   positive** — i.e. the flagged construct is semantically required
   but the linter can't see why (the canonical case is an instance arg
   required by a definition's contract). Always add a one-line comment
   stating why the suppression is correct, not merely convenient. A
   suppression used to dodge a real fix is a defect, not a workaround.
3. **If you can neither fix it at the source nor justify a suppression**
   — e.g. the fix would meaningfully alter a vendored proof's content,
   or you don't understand why the warning fires — **surface it to the
   user** rather than committing the warning or silencing it blind.

Newly-added `@[simp]` attributes are the usual `lake lint` offenders —
if the LHS is reducible by existing simp lemmas, drop the `@[simp]`
(the lemma stays callable by name) rather than working around with
`@[nolint simpNF]`.

> **Blueprint pointer touched?** If the commit also edits any
> `\lean{...}` pointer in `../blueprint/`, run `checkdecls` per
> `../blueprint/CLAUDE.md` *Static checks before commit*. CI runs
> the same check and a missing-declaration failure is a hard merge
> blocker.

## Automated mathlib bumps

PRs from `../.github/workflows/hopscotch.yml` (daily cron) arrive
on branches like `hopscotch/bump-mathlib`. Review them like any
other mathlib bump (the project's lemmas may need fixups if the
build broke). A tracking issue gets opened instead when the bump
hits a regression — the issue body identifies the breaking mathlib
commit via bisection.
