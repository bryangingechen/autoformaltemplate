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
- **When a `notes/PhaseN.md` has gone finished-heavy** (*Decisions made*
  outweighs the forward sections) **or trips the ~500-line tripwire**
  (cf. `notes/CLAUDE.md` *Forward-weighted note*) — which signals the
  per-commit *Compress-in-commit* gate was skipped, since rebalancing is
  meant to happen continuously. Compress it and bundle related sweeps so
  the next agent sees the slimmer notes.
- **When a phase file crosses the size threshold** in
  `{{PROJECT_NAME}}/CLAUDE.md` *File-size signals (in-phase structural
  triggers)* (~2000 lines or ~40 declarations) — open a *structural*
  cleanup round mid-phase rather than deferring to a post-phase A–D
  pass. The scope is narrower than the standard categories: one axis
  only, *Lean-file split + matching blueprint coverage* — run the
  classification walk from that section on the existing declarations
  and open sibling exposition files (`{{PROJECT_NAME}}/<topic>.lean`)
  plus mirror modules (`{{PROJECT_NAME}}/Mathlib/<upstream path>.lean`)
  for each mathlib-affinity-distinct sub-theory the walk surfaces. The
  parallel `notes/PhaseN.md` split (per `notes/CLAUDE.md` *Notes-size
  signals*) fires together when both surfaces are over their
  thresholds. Rationale: one careful structural commit at the
  threshold beats a multi-task post-phase cleanup round (observed in
  practice: a post-phase retro restructure ran across many sessions;
  opening the seam at the threshold is cheaper at every point on that
  curve).
- **When the friction log accumulates four+ open entries** of the
  same shape (e.g. four "I had to write `letI : Fintype V := …`"
  entries → consider a typeclass-boundary sweep).
- **After a major API addition** that may have left earlier files
  using a now-superseded pattern (e.g. a new helper that subsumes
  three older multi-step proofs).
- **Ad-hoc**, when an agent or user spots a code-smell pattern worth
  surveying systematically.

## Audit categories

§A–§D are *box-check* sweeps: run a grep, walk each hit, fix each
site. §E is the complementary *evaluation* category: measure
project-wide tactic usage and recommend a direction. A round picks
some subset of §A–§D depending on what's accumulated; **§E always
runs at round-open** (the scan is cheap; see *Workflow* below).
§E appears first below, ahead of §A–§D, because its scan auto-fires
at round-open *before* §A–§D scope is decided; the letter labels
reflect the order the categories were codified, and stay stable so
old cleanup logs keep their meaning.

### E. Tactical-automation evaluation (always runs at round-open)

**Why this is a standing category, not an opt-in.** Rounds that run
only the §A–§D box-checks never ask *"are we reaching for `grind` /
`fun_prop` / `gcongr` enough across the project?"* — the question is
not self-evident from the box-check framing and historically needed
manual prompting to surface. §E as an **always-on round-open scan**
is the corrective: the scan is one shell command, cheap enough that
"do I run it?" should never be a judgement call.

**Round-open scan recipe.** First step of any cleanup round, before
populating the §A–§D task list:

```sh
# Standard `grep -wn` pattern, for tactics whose name does not collide
# with English words or common identifiers.
for t in grind gcongr fun_prop polyrith linear_combination \
         field_simp positivity continuity measurability fun_trans; do
  printf '%-20s %d\n' "$t" \
    "$(grep -rwn "$t" {{PROJECT_NAME}} --include='*.lean' | wc -l)"
done

# Literal-name-collision class: `bound` collides with English "bound"
# in docstrings/comments/identifiers. Match tactic-position contexts
# instead — the `by bound` / `; bound` / `<;> bound` openers cover the
# canonical mathlib invocation patterns and avoid the false positives.
printf '%-20s %d\n' bound \
  "$(grep -rEn 'by bound\b|; bound\b|<;> bound\b' {{PROJECT_NAME}} --include='*.lean' | wc -l)"
```

The same pattern generalises to any future tactic whose name is a
common English word or shares its identifier with a project decl
(a hypothetical `norm` / `apply` / `decide` collision): swap the
bare `grep -wn` for the tactic-position regex
`by <name>\b|; <name>\b|<;> <name>\b`. (Observed in practice: a
round-open scan returned 67 false-positive `bound` hits from
docstring English; the refined regex returned 0, unmasking a real
under-reach signal.)

Record the counts in the round's work log under a *Round-open
tactical-usage scan* heading. Then compare against the baseline:

- **`grind` / `gcongr` / `polyrith` at 0** across a several-thousand-
  line corpus is **under-reach**. `TACTICS-GOLF.md` documents `grind`
  as the preferred closer; 0 uses means the discipline isn't landing
  in first-draft writing.
- **`fun_prop` count below the FRICTION `[tactic]` count** —
  `grep -c '^### \[tactic\]' notes/FRICTION.md` — is **under-reach**.
  That FRICTION cluster is exactly the manual derivative-chain glue
  `fun_prop` automates.
- **`positivity` / `field_simp` / `continuity` / `measurability` /
  `fun_trans`** in the dozens range is normal; zero in a context
  that clearly demands them (e.g. zero `positivity` in an
  analysis-heavy chapter) is under-reach.
- **Any new mathlib tactic landed since the previous round** — add it
  to the loop above and treat 0 uses as the same under-reach signal.

**Audit follow-up.** If the scan surfaces under-reach on any tactic,
file a *§T-style audit wedge* in the round's task list (alongside
§A–§D): A/B-test the under-reached tactic at ~10 representative
sites via `lean_multi_attempt`, report the verdict, and *if the
verdict is "use this more"* lift the rule both to `TACTICS-GOLF.md`
(idiom side, read at cleanup time) and to `{{PROJECT_NAME}}/CLAUDE.md`
*Reach for stronger tactics during first-draft writing* (auto-load
side, read at session start).

**Tagging is a first-class follow-up question, not a footnote.**
The §E tactics — `grind`, `gcongr` / `grewrite`, `fun_prop`, and
their siblings — drive off a project-local + mathlib corpus of
`@[grind]` / `@[gcongr]` / `@[fun_prop]`-tagged lemmas. A bare
A/B-test on a project corpus with zero (or very few) project tags is
undercounting the tactic's reach by design. Every §T-style wedge
therefore asks two questions, not one:

1. *Direct substitution.* Does the tactic close the goal as written,
   against the existing tag corpus?
2. *Tag-then-substitute.* Would tagging one or more project lemmas
   with the corresponding attribute (`@[grind]`, `@[gcongr]`,
   `@[fun_prop]`, …) let the tactic close this goal — or a
   neighbouring goal in the same proof family — that direct
   substitution can't? `lean_hammer_premise` is the search lever for
   surfacing the candidate premise set on `grind`-shaped goals.

Record both answers in the verdict. The lift step then fires if
*either* answer pushes the tactic over the "use this more" bar —
project-helper tags plus a documented use site are a legitimate lift
outcome, not just direct-substitution wins. "Tactic doesn't fire"
often means "tactic hasn't been pointed at the right premises"
rather than "tactic is wrong for this goal class"; subagents that
skip the tag question converge on premature no-op verdicts.

**Skip conditions.** The scan itself is mandatory; the audit
follow-up is conditional on the scan finding under-reach. A round
that runs the scan, files the counts, and finds no under-reach
closes §E in one bullet — the visible record that the question was
asked is the point.

### A. Blueprint ↔ Lean divergence audit

This category runs in **two directions**. The first (the historical
framing) is *Lean too complex relative to the math* — bias **fix Lean
first**, per `blueprint/CLAUDE.md` (*Proof verbosity*): "First make Lean
as painless as the math; only then add prose asides." The second is
**faithfulness** — *Lean proves less than, or something subtly different
from, what the blueprint claims*. The two are orthogonal: a node can be
internally consistent (blueprint↔Lean line up on effort) yet
unfaithful (the Lean statement is weaker than the headline word). Steps
1, 4, and 5 below are the faithfulness direction; steps 2–3 are the
fix-Lean-first direction.

For each chapter under `blueprint/src/chapter/`:

1. For each `\lean{...}` entry, compare the blueprint statement against
   the Lean declaration's signature. Flag not just hypothesis /
   conclusion / implicit-explicit-binder mismatches but specifically
   these failure modes:
   - **(a) Named-concept expansion.** When the blueprint states a
     *named* mathematical concept — "diffeomorphism", "bijection",
     "isomorphism", "is the inverse of", "equivalent" — rather than a
     transcribed formula, expand it into its defining clauses and
     confirm *each* clause is actually present in the Lean, not merely
     morally implied. (A "C^∞ diffeomorphism" = bijective ∧ smooth
     forward ∧ smooth inverse ∧ *the smooth map is identified with the
     inverse*; a bundle missing the last clause is strictly weaker than
     the word.)
   - **(b) Quantifier domain.** Check the *ranging set* of every
     `∀` / `∃`, not just that a quantifier is present. "Nonempty proper
     `S ⊂ U`" vs "`S ⊆ U` with `Sᶜ` nonempty in `V`" is a domain
     mismatch that reads as "same `∀ S`" if you don't zoom in.
   - **(c) Bundling completeness.** A Lean `∧` that drops a conjunct
     the prose asserts.
   - **(d) Vacuity / hypothesis strength.** A hypothesis so strong the
     statement is empty, or so weak the conclusion is trivial.
   - **(e) Hypothesis laundering.** A **`\leanok` node carrying a
     load-bearing hypothesis** (the hard part assumed, not proved)
     that is neither discharged in the Lean body nor the conclusion
     of a node it `\uses{...}`. This is a dishonestly-green node and
     should be red. §A is the **between-phases safety net** for the
     per-commit honesty gate in `blueprint/CLAUDE.md` (*every
     hypothesis of a `\leanok` node is discharged*) — that gate
     should have caught it at the commit that added `\leanok`; this
     walk is where a missed one surfaces. Walk every `\leanok` node's
     hypotheses against its `\uses` edges, not just the ones with
     suspicious prose. (Observed in practice: a producer lemma
     assuming the very property it was named to construct.)
2. Re-read each prose proof. If it suggests "the Lean does X via Y"
   where Y is harder than X, that's a candidate for Lean
   simplification — the blueprint shouldn't be carrying a smoothness
   gloss the Lean can't sustain.
3. Look for "formalization aside" remarks. Each one is a flag: the
   round's first response is to attempt a Lean simplification that
   eliminates the aside. Only if simplification fails does the aside
   stay (and become more concrete about what residual cost remains).
4. **Scan Lean doc-comments for deferral language**, not just the
   blueprint prose — the most honest "we didn't finish this" signals
   often sit in a docstring rather than a TeX aside:
   ```sh
   grep -rniE "next phase|for now|not yet|we do not (yet )?prove|left to the reader|structural step|deferred|\bTODO\b" {{PROJECT_NAME}} --include='*.lean'
   ```
   Each hit is a self-acknowledged gap. Either close it or, if it is
   genuinely out of scope, confirm the *blueprint* node honestly
   reflects the reduced Lean claim — a deferral living only in a
   docstring while the blueprint asserts the full result is exactly
   the silent divergence §A exists to catch.
5. **Ground headline nodes against the source.** Steps 1–4 audit
   blueprint↔Lean; blueprint and Lean can agree while both drift
   from the source. For each chapter's headline nodes, spot-check the
   blueprint statement against the source material in `.refs/` (the
   math being formalized). Blueprint↔Lean agreement certifies internal
   consistency, not faithfulness to the source.

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
  cycle. This bullet is *site-specific*; §E covers the
  complementary *project-wide* question (is the project
  under-reaching for `grind` / `fun_prop` / `gcongr` etc. across
  many proofs?), which §C alone has historically missed.
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

Compression is **primarily a per-commit constraint** (`CLAUDE.md`
*Before each commit → Compress in-commit*; `notes/CLAUDE.md`
*Forward-weighted note*) — a note should rarely be finished-heavy by the
time a cleanup round runs. §D is the **safety net**: it catches notes
that slipped past the per-commit gate (and is where a never-promoted
cross-cutting lesson referenced in 2+ files / 2+ phases finally lifts).
Concretely, when a `notes/PhaseN.md`'s *Decisions made* outweighs its
forward sections (or it trips the ~500-line tripwire), or such a lesson
has gone unlifted:

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

Two ad-hoc flavors are recognized beyond the standard A–E pass:

- **Misformalization review** — a post-completion faithfulness pass
  over the whole corpus: §A's faithfulness direction (failure modes
  (a)–(e), the deferral-language grep, grounding against `.refs/`)
  run end-to-end as the round's sole scope. §A's faithfulness
  checklist is the codified residue of this flavor.
- **Presentation & organization cleanup** — doc-only: parallel
  audits of the blueprint (readability for the target audience,
  Lean detail leaking into reader-facing prose), the public
  surfaces (README, home page, doc-gen front page, theorem
  discoverability), and the internal docs. No Lean proof changes;
  the operative gate is `blueprint/verify.sh` green plus
  `blueprint/lint.sh` (the static checks from `blueprint/CLAUDE.md`).

The log follows the standard `notes/PhaseN.md` template — see
`notes/CLAUDE.md` *Template for `notes/PhaseN.md`*. Sub-organisation
of *Decisions made* is encouraged when many sweeps happen in one
round; the cleanup round's "Lemma checklist" is the task list
across (A)–(E).

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

Refactor passes *are* in scope when surfaced by an A–E audit —
§C explicitly lists "API extraction", "Definitional refactor", and
"Cross-proof unification" as long-proof dispositions, and a B-sweep
that surfaces a missing fused lemma is itself a small refactor.
Land each surfaced refactor in-round as its own commit per *Workflow*
rule 3, not as a forward-work carry-over. The exclusion is on
*free-form* refactors started without an audit anchor — those still
belong in a phase plan or `DESIGN.md` *Choices to revisit*.

## Workflow

1. **Open the work log** with the round's planned scope (which of
   A–D, which files, which smells) **and run the §E round-open
   tactical-usage scan** — file the counts under a *Round-open
   tactical-usage scan* heading in the work log, then file any
   surfaced §T-style audit wedges alongside the §A–§D task list.
   One commit just for the log skeleton + task list + scan output
   is fine; the visible-in-commit-history record that the scan ran
   is part of the §E discipline.
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
