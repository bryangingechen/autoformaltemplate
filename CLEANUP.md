# Cleanup rounds — operating manual

This file is the project's **cleanup-round reference**: how to run a
between-phases (or post-phase) audit pass that surveys what already
shipped, rather than the per-commit friction review that fires on
work-in-progress.

For per-commit / end-of-session discipline, see
`{{PROJECT_NAME}}/CLAUDE.md` *Friction review*. That review keeps
new friction from accumulating silently; this file's review *discharges*
debt that the per-commit review didn't catch (because the lesson only
becomes visible across many proofs, or because a "standard idiom"
worth re-examining was waved through earlier).

For golfing idioms / rescue patterns, see `TACTICS-GOLF.md` /
`TACTICS-QUIRKS.md` — cross-cutting lessons surfaced by a cleanup round
land there, not here.

## When to run a cleanup round

- **Between phases**, before opening the next phase's work log. The
  default cadence. A finished phase is a natural moment to step back
  before the next dependency-introducing decisions.
- **When `notes/PhaseN.md` blows its line budget** (cf.
  `notes/CLAUDE.md` *Soft length budget*) and compression should
  happen anyway. Bundle related sweeps with the compression pass so
  the next agent sees the slimmer notes.
- **When the friction log accumulates four+ open entries** of the
  same shape (e.g. four "I had to write `letI : Fintype V := …`"
  entries → consider a typeclass-boundary sweep).
- **After a major API addition** that may have left earlier files
  using a now-superseded pattern (e.g. a new helper that subsumes
  three older multi-step proofs).
- **Ad-hoc**, when an agent or user spots a code-smell pattern worth
  surveying systematically.

## Three audit categories

A cleanup round picks some subset of these; the round's work log
records which were in scope and why.

### A. Blueprint ↔ Lean divergence audit

The bias is **fix Lean first**. `blueprint/CLAUDE.md` (*Proof
verbosity*) states the principle: "First make Lean as painless as the
math; only then add prose asides." A cleanup round operationalises
that across the existing corpus.

For each chapter under `blueprint/src/chapter/`:

1. For each `\lean{...}` entry, compare the blueprint statement form
   against the Lean declaration's signature. Flag any mismatch in
   hypotheses, conclusion form, or implicit/explicit binders.
2. Re-read each prose proof. If it suggests "the Lean does X via Y"
   where Y is harder than X, that's a candidate for Lean
   simplification — the blueprint shouldn't be carrying a smoothness
   gloss the Lean can't sustain.
3. Look for "formalization aside" remarks. Each one is a flag: the
   round's first response is to attempt a Lean simplification that
   eliminates the aside. Only if simplification fails does the aside
   stay (and become more concrete about what residual cost remains).

`checkdecls` is the always-on per-commit gate that verifies every
`\lean{...}` still resolves; it lives in `blueprint/CLAUDE.md`
*Static checks before commit* and runs on every commit that touches a
blueprint pointer. A cleanup round does not need a separate "run
checkdecls" task — failures of that gate are caught in-commit, not in
a post-hoc audit.

The friction direction matters: we **prefer to shorten the Lean**
rather than add a prose aside. If a Lean simplification attempt fails,
the cleanup-round log records *what was tried* so the next round
doesn't re-litigate, plus the aside that was added in its place.

### B. Code-smell sweep

Concrete grep targets. Each smell is its own commit (or small
cluster); the goal is principled root-cause fixes, not local
workarounds.

| Smell | Grep | Question to ask each site |
|---|---|---|
| `classical` invocations | `grep -n "^\s*classical$\|^\s*classical *--" {{PROJECT_NAME}}/*.lean` | Is `[DecidableEq V]` / `[DecidableRel G.Adj]` a cleaner boundary, or is the decidability genuinely unavailable here? |
| `letI : Fintype V := Fintype.ofFinite V` (and `haveI`) | `grep -nE "letI\|haveI.*(Fintype.ofFinite\|Set.Finite.fintype)" {{PROJECT_NAME}}/*.lean` | Should the caller take `[Fintype V]`, or is the `[Finite V]`-bridge the right boundary? Is the same `haveI` repeated across many sites suggesting a single helper? |
| `@[nolint …]` / `set_option linter.* false` | `grep -nE "@\[nolint\|set_option linter" {{PROJECT_NAME}}/*.lean` | Why was the lint silenced? Is the underlying issue still present, or has mathlib evolved past it? Each site should have a one-line comment justifying it. |
| `noncomputable def` | `grep -n "noncomputable def" {{PROJECT_NAME}}/*.lean` | Is the keyword forced (`Classical.choose`, no `Decidable` instance for the body)? Or accidental? |
| `Set` vs `Finset` mixing | manual; look for `.toFinset` / `Set.ncard_coe_finset` chains | Does the definition belong in `Set` form (avoid `[Fintype V]` requirement) per `DESIGN.md`, or is the proof site obviously cleaner with a `Finset`-form companion? |
| `change` / `show` to coax `simp`/`rw` | `grep -nE "^\s*(change\|show)\b" {{PROJECT_NAME}}/*.lean` | Per `{{PROJECT_NAME}}/CLAUDE.md` *Concrete signals* — is the `change` covering for an un-fused predicate lemma? Could a project-internal simp lemma replace it? |
| Multi-step `rw [..., ..., ...]` chains (3+ args, one mathematical step) | `grep -nE "rw \[[^]]*,[^]]*,[^]]*,[^]]*\]" {{PROJECT_NAME}}/*.lean` | Missing fused lemma — usually a one-line mirror under `{{PROJECT_NAME}}/Mathlib/<path>`. |
| `show X = Y from rfl` as a `rw` / `simp only` argument | `grep -nE "show .* from rfl" {{PROJECT_NAME}}/*.lean` | Falls into one of: (a) a `let`-binding the rewrite chain should be reducing on its own; (b) a bundled-vs-unbundled morphism gap with a named `_apply` lemma upstream; (c) a numeric / arithmetic literal — reach for the named lemma instead of `rfl`; (d) a notation unfold — the whole `rw` chain often collapses to a one-line `simp [structural_lemma, side_hypotheses]`. |
| Manual `Fintype.card` / coercion chains | manual | Often `Set.ncard_coe_finset` / `Set.ncard_eq_toFinset_card'` bridges that the autoparam pattern would have absorbed. |

`DESIGN.md` *Engineering conventions* and *Choices to revisit* pin
the project's official answers — a cleanup-round sweep is "are we
actually following these". Drift gets fixed; if the drift looks
deliberate, the convention itself goes in *Choices to revisit*.

### C. Long-proof audit

Rank the top ~10 proofs by line count and walk each:

```sh
# crude line-count ranking by `theorem`/`lemma` body
awk '/^(private )?(theorem|lemma) /{name=$0; line=NR}
     /^(end|namespace) /{ if (line) {print NR-line, line, name; line=0} }
     /^\s*$/{ if (line && NR-line > 50) {print NR-line, line, name; line=0} }
' {{PROJECT_NAME}}/*.lean | sort -rn | head -20
```

For each long proof, ask:

- **API extraction.** Is there a self-contained sub-lemma that other
  proofs would call separately? Extract → smaller pieces with a
  named API surface, and the main proof reads as composition.
- **Mathlib lemma we missed.** Re-run `lean_loogle` (type pattern)
  or `lean_leanfinder` (concept) against any 5-10+ line subblock.
  TACTICS-GOLF *Search mathlib before mirroring* — multi-line
  hand-rolled blocks regularly collapse to a one-line mathlib
  invocation.
- **Tactic substitution.** Could `grind only [...]` / `fun_prop` /
  `linear_combination` collapse a multi-step `rw` chain? Use
  `lean_multi_attempt` to A/B-test candidates without an edit-build
  cycle.
- **Definitional refactor.** Would making a predicate `abbrev` (or
  reshaping its body) save proofs that currently have to unfold it
  by hand? *Don't* convert `def`s to `abbrev`s casually — this is a
  per-proof judgement call, not a policy reversal.
- **Cross-proof unification.** Two proofs that share an algebraic
  backbone are candidates for a shared lemma.

**Calibration: long-proof rankings surface structural shape, not
extraction debt.** The top-10 ranking is a *screening* tool, not a
to-do list. It's normal for a cleanup pass to close with most top-10
sites as no-op: long bodies are often forced by structural recursion
/ case-dispatch boilerplate that is shared at the *boilerplate* level
but not at the *step* level. Treat the four-question walk as the
audit gate that confirms the no-extract finding rather than as a
discovery procedure for refactor candidates. When C does surface a
refactor, it tends to come from outside the top-10 — a smaller proof
whose shape matches one already known to be unifiable.

### D. Project-organization compression

When a `notes/PhaseN.md` is past its line budget, or when a
cross-cutting lesson has been referenced in 2+ files / 2+ phases
without being lifted:

- **Lift** lessons from phase notes to `TACTICS-GOLF.md` (idioms),
  `TACTICS-QUIRKS.md` (rescue), or `DESIGN.md` (cross-cutting
  rationale) per `CLAUDE.md` *Lift on promotion*.
- **Compress** the multi-session plan to a commit-log pointer + a
  brief summary once the phase is closed (the plan stops being
  plan-relevant the moment the phase ships).
- **Re-skim** `notes/FRICTION.md` status sections — resolved
  project-internal entries with their resolution fully indexed
  elsewhere migrate to `FRICTION-archive.md`.

This category is essentially a structured re-run of `CLAUDE.md`
*When this commit closes a phase* → *Review project organization*,
applied to phases that have been closed for a while.

## Per-round work log

Every cleanup round gets its own work log under `notes/`, named to
sort near the relevant phase:

- `notes/PhaseN-cleanup.md` for a round between Phase N and Phase
  N+1 (alphabetical / glob order keeps it next to `PhaseN.md`).
- `notes/<topic>-cleanup.md` for ad-hoc rounds outside the
  between-phases cadence (e.g. `notes/perf-cleanup.md`).

The log follows the standard `notes/PhaseN.md` template — see
`notes/CLAUDE.md` *Template for `notes/PhaseN.md`*. Sub-organisation
of *Decisions made* is encouraged when many sweeps happen in one
round; the cleanup round's "Lemma checklist" is the task list
across (A)–(D).

**Task list discipline.** Populate the *full* task list in the log
*before starting any cleanup work*. The point of the log is clean
handoff: a session that runs out of time should be resumable from
the log alone, without the agent having had to scope the work
mid-session. New tasks discovered during the round are fine to
append (with a one-line note about what surfaced them), but the
initial sweep checklist should be comprehensive.

`ROADMAP.md`'s Status table gets a row for each cleanup round
between phases, so the existence and scope of the round is visible
without browsing `notes/`.

## What a cleanup round is *not*

- **Not a performance pass.** Build-time tuning has its own log
  (`notes/PERFORMANCE.md`) and protocol (4-run A/B, median
  comparison). A cleanup round can incidentally reduce per-file
  build time, but it doesn't measure it.
- **Not a phase.** The Status table row is for visibility; the
  cleanup round doesn't have a mathematical milestone, and it
  doesn't unlock new content. Phase N+1 doesn't depend on the
  round between Phase N and N+1 — the round is hygiene.

Refactor passes *are* in scope when surfaced by an A–D audit —
§C explicitly lists "API extraction", "Definitional refactor", and
"Cross-proof unification" as long-proof dispositions, and a B-sweep
that surfaces a missing fused lemma is itself a small refactor.
Land each surfaced refactor in-round as its own commit per *Workflow*
rule 3, not as a forward-work carry-over. The exclusion is on
*free-form* refactors started without an audit anchor — those still
belong in a phase plan or `DESIGN.md` *Choices to revisit*.

## Workflow

1. **Open the work log** with the round's planned scope (which of
   A–D, which files, which smells). One commit just for the log
   skeleton + task list is fine.
2. **Sweep first, fix later.** Within each category, run the greps
   / file walks and *record the task list* before starting fixes.
   You'll find more items than you expect; deferring some to a
   follow-up round is normal.
3. **Each fix as its own commit.** The per-commit friction review
   discipline (`{{PROJECT_NAME}}/CLAUDE.md`) still applies. A
   cleanup commit looks the same as any other commit: build/lint
   gates, friction review, work-log update.
4. **Lift cross-cutting lessons in-commit.** If a sweep reveals
   "always prefer X over Y" — that goes to `TACTICS-GOLF.md` /
   `TACTICS-QUIRKS.md` in the same commit as the fix, per the
   existing lift-on-promotion rule.
5. **Close the round** with a *Hand-off / next phase* section in
   the work log that names what carried over (if anything) and
   updates the ROADMAP Status row.
