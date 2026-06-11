# {{PROJECT_TITLE}} — Design Notes

This file holds the **rationale** for cross-cutting design choices —
the *why* behind the conventions documented operationally in
`ROADMAP.md` and `CLAUDE.md`. Open it when you actually want to
question a decision; the default answer is *don't*.

Conventions that bear on the *what* (directory layout, status, phase
plan) live in `ROADMAP.md`. Per-session process discipline lives in
`CLAUDE.md`. Tactical-level proof advice lives in `TACTICS-GOLF.md`
and `TACTICS-QUIRKS.md`.

This file grows as the project does. Each section below is a
cross-cutting decision; add new sections as new ones come up.

---

## Mirror directory for missing mathlib lemmas

If, while proving something here, we hit a lemma that *should* exist
in mathlib proper (because it's about `SimpleGraph`, `Sym2`,
`Set.ncard`, `Finset`, etc., and is not specific to the project's
mathematics), we put it under

```
{{PROJECT_NAME}}/Mathlib/<exact mathlib path>
```

For example, a missing lemma about `SimpleGraph.edgeSet` that would
naturally live in `Mathlib/Combinatorics/SimpleGraph/Basic.lean` goes
into `{{PROJECT_NAME}}/Mathlib/Combinatorics/SimpleGraph/Basic.lean`.

The mirror keeps each candidate lemma in the file it would land in
upstream, so promotion to mathlib is a copy-paste with the file's
existing context. The Lean namespace stays the standard one
(`SimpleGraph`, `Set`, …), not the project's.

Each file in the mirror should open with a docstring stating that the
contents are upstream candidates and which mathlib path they target.

The directory is created lazily — don't pre-populate it. See
`notes/FRICTION.md` "Mirrored" for the per-lemma rationale and the
authoritative list of paths currently in use; the running tree
under `{{PROJECT_NAME}}/Mathlib/` is the ground truth.

---

## Strengthen the existing lemma, don't proliferate variants

When a downstream proof needs a lemma close to one that already
exists but with slightly different hypotheses — typically *weaker*
hypotheses, e.g. a subset where the existing lemma takes an equality
— **strengthen the existing lemma in place** rather than adding a
new named variant. Two sibling lemmas that differ only in one
hypothesis create API noise and make name choice arbitrary for
future readers.

When to keep both:
- The two lemmas actually carry mathematically distinct content
  (different proof structures, different conclusion forms).
- One is the "atomic" form and the other is a named convenience
  that's referenced repeatedly with the convenience form's
  arguments pre-cooked.

When to merge:
- The "new" lemma can be a one-line corollary of the strengthened
  form — drop the corollary, refactor the consumer onto the general
  form.
- Both forms have the same proof skeleton with one substitution
  changed — generalize the substituted argument, drop the
  specialization.

---

## Reshape past results in place, don't parallel-extract

When a later phase refactors a definition or signature (an
`Option`-returning function becomes a verdict-bearing inductive, a
`noncomputable` body acquires a computable wrapper, a predicate gets
a sharper decidable instance), **reshape the existing declarations
in place** rather than landing the new shape alongside the old one
as a sibling. The deprecation path is cheaper than the parallel-API
maintenance burden, and the blueprint stays in sync because there's
only one node to update.

The exception is when the old shape has external callers (downstream
projects, published API) and a deprecation cycle is needed. In that
case land the new shape, route every internal caller onto it, mark
the old shape `@[deprecated]`, and remove it at the next major
version bump.

---

## Cross-project engineering principles

Portable rules distilled from ancestor projects' dead ends. Unlike
the sections above (project-shaped conventions) these are
*pre-seeded*: they were paid for elsewhere, so the project starts
with them. Each carries its statement plus the diagnostic *tell*;
the worked examples live in the ancestors' logs and are trimmed
here.

### Forward-mode reduction chains: build the keystone first

Forward mode's natural cadence — one dep-graph node = one commit =
one lemma — is right when nodes *fan out* and get reused. It goes
wrong when the work is a **linear reduction**: discharging a goal
one hypothesis at a time then produces a telescoping chain of
single-use wrappers, each with exactly one caller (the next link),
a short proof, and a large signature — and the wrappers are shaped
against a *guessed* final consumer. When the remaining work is a
linear reduction onto one hard **keystone**, build the keystone —
or at least pin its honest target statement and validate the
consumer API against it — *before* growing the reduction chain;
collapse single-use steps into `have`/`obtain` inside one theorem
rather than named public lemmas. **The tell:** a phase emitting one
thin wrapper lemma per commit while every hand-off says "the real
work is still ahead." Blueprint corollary: in forward mode the
dep-graph *is* the plan, so a chain of wrapper-shaped Lean lemmas
usually means the *blueprint's* decomposition is the unnatural one
— fixing the blueprint to the honest mathematical decomposition is
causal, not cosmetic.

### Constructibility recon before scheduling a producer build

Before scheduling a producer/existence node (`∃ realization`,
"attains rank `r`", a counting/dimension target) as a *build*
commit, run a **constructibility recon**: trace the conclusion's
target quantity (rank, count, dimension) through the intended
construction and confirm the arithmetic **closes** — not merely
that the `\uses` edges type-check. If the source states the step in
a few lines, that compression usually *is* the content; expand it
to a complete gap-free argument against the primary source *before*
decomposing into Lean nodes. Decompose-then-build is right only
when the math is settled; when the math is the hard part, invert
the order. Sharpenings, each a distinct failure mode:

- **Design the LAYER, not just the node.** When a producer layer
  shares a motive/invariant, per-node recon catches local
  short-by-one gaps but is blind to a too-weak shared invariant.
  Run one layer-level design pass — read the whole producer family
  against the source, asking what each producer needs *from* the
  motive and supplies *to* it — before the first producer build.
- **Verify the recon's load-bearing claims, don't assert them.** A
  recon may use a feasibility verdict word ("bounded",
  "green-reuse", "plumbing", "no wall") only for a claim checked
  against ground truth, and must say how — otherwise label it
  **"asserted (unverified)"**. Two cheap mandatory checks at every
  recon crux: *consumer-fit* (write the reused lemma's conclusion
  and the consumer's required hypothesis side by side; confirm the
  shapes match) and *quantitative-against-the-exact-lemma* (any
  rank/dimension/count equality cites the exact lemma yielding it,
  with its real hypotheses, or is derived from first principles).
  Recon at *build fidelity* — a from-memory sketch is not a recon.
- **Recon the quantifier domain of each consumed brick's
  hypotheses**, not just its conclusion shape. A `∀`-domain over
  the ambient type vs. over a subobject is exactly the mismatch a
  type-level "feed the bricks together" plan is blind to; a
  conclusion-shape match is necessary, not sufficient.
- **A seed's property doesn't automatically survive to a
  generically-chosen output.** Before scheduling work to
  "recover/thread property `P` of a producer's output", trace the
  construction to where the output point is actually chosen and
  confirm it has `P` — the survival question often reveals a
  shorter path.
- **A standing hypothesis needs a satisfiability witness, not just
  green consumers.** A hypothesis every consumer takes as given is
  never checked satisfiable by a green build: a mis-transcribed
  definition (e.g. a source's strict `1 < …` transcribed as mere
  nonemptiness) can make a branch hypothesis vacuous while phases of
  conditional theorems stay green on top of it. When a branch
  hypothesis *quantifies over* a transcribed definition ("no X
  exists", "every X satisfies …"), (a) re-verify the transcription
  against the primary source's exact inequality, and (b) exhibit a
  satisfying instance the first time a phase consumes the
  hypothesis — a one-line witness (`lean_run_code`) is cheap; churn
  on a vacuous branch is not.

### Match the source's argument structure, not just its conclusion

A locally-sound modeling choice can silently re-express a published
proof's key structural step as a *different* argument with a
different — possibly intractable — obligation, even while the types
and counts line up. At the layer-design / constructibility-recon
pass, explicitly check: *does my composition lemma have the same
shape as the source's?* **The tell:** the arithmetic closes but
every pass needs a fresh hypothesis to bridge a gap the source does
not have. Two corollaries:

- **Green-with-a-red-sibling is not green.** A green node that
  defers its hard half as a red sibling must have that red half's
  feasibility re-verified *before* downstream nodes build on the
  green half's assumed shape.
- **Prefer the source's `∃`/open-locus genericity over
  `∀`-over-generic-position.** Condition a deferred residual on the
  specific (e.g. Zariski-open) locus the construction actually
  lands in, never on "every general-position instance" — the latter
  usually demands "generic ⟹ maximal" which is false. The tell that
  you over-quantified: a sibling object in the same construction
  gets the analogous property from a narrower condition than you
  are demanding.

### Size-reducing induction: check the motive on the reduced instances

When a producer/existence statement is proved by an induction that
reduces the object's size, check that the motive is satisfiable for
the *reduced* instances, not just the top one — and prefer a
formulation intrinsic to the object over one referencing a fixed
ambient type (an absolute property over the ambient is often
unsatisfiable for every proper sub-instance, leaving the capstone
green only as a conditional over unsatisfiable hypotheses). **The
tell:** a base-case hypothesis that effectively pins the ambient to
the object (e.g. `∀ w, w = u ∨ w = v`).

### Narrowing an induction motive requires an IH-application census

Before narrowing an induction motive from the source's generality
(all-`k` → `k = 0`, all-`d` → `d = 3`, …), **census every IH
application in the source's full proof tree** — including
applications to auxiliary objects built inside case interiors — and
check each target lies in the narrowed domain. The reduction
skeleton's children are not the complete list: a case interior can
apply the theorem to an auxiliary object that is *not* a child of
the reduction, so the narrowed proof *consumes* the general
statement rather than subsuming it; a skeleton-level audit ("both
reduction arms preserve the narrowed invariant") then passes while
being precisely the audit that doesn't matter. Corollary: when
scoping deferred work as "apply X to Y", **verify Y satisfies X's
hypotheses at scoping time** — an ancestor project's "apply the IH
to `G_v`" deferral hid a false hypothesis for four days and six
sub-phases, even though the falsifying fact was already formalized
in-repo. **The tell:** the narrowing rides in alongside an unrelated
re-plan, justified by a parenthetical ("the general statement is
recovered the same way") rather than a proof-tree walk.

### Mirror a source's case analysis by its discriminating parameter

When mirroring a source's case analysis, pin each project node to
the source's case by the **discriminating parameter** the source
keys on, and check the target arithmetic matches that case — don't
inherit a case name by surface analogy ("it's a degree-2 split, so
it's Case II"). A conflation here hides exactly the case the source
considered hard. This is the case-analysis analogue of the
citation-verification bar in `CLAUDE.md` *Referencing prior work*.

### Generalize to the weakest typeclass the statement supports

When a lemma's statement is genuinely algebraically generic, state
it at the weakest typeclass / algebraic assumption that supports
it, and let specialization happen by type ascription at the call
site — not by a parallel declaration duplicating the proof. The
empirical policy is **per-leaf typeclass pin minimization**: each
leaf adopts the weakest typeclass its body actually uses, not one
uniform strong pin everywhere. **Where to stop:** statements whose
hypotheses are genuinely regime-specific stay regime-specific — two
lemmas that read alike informally but have different hypotheses,
conclusions, and proofs are sibling corollaries of a shared
foundational substrate, not points on a generalization ladder; a
faux-unified statement assuming both hypotheses is strictly weaker
than each sibling. Generalize at the layer where uniformity
genuinely holds, and let the parent prose name the shared
substrate.

### Destructive vs. additive migration: pick by caller graph

When a project-wide refactor replaces one signature shape with
another, the per-decl migration is either *destructive* (rewrite in
place; every in-Lean caller migrates in the same commit) or
*additive* (leave the legacy decl; add a new-shape wrapper that
delegates). **Pick by the caller graph, not by signature count.**
Destructive migration is build-safe per-file only when the migrated
decl has zero direct in-Lean callers (or the caller cascade is
bounded within one commit); when the legacy decl fans out into
downstream phases and no total `(old shape) → (new shape)` adapter
exists at the data layer, the destructive cascade is unbounded.
Standard sequencing: **additive sweep** (one wrapper per decl, in
one batched commit) → **headline flip** (the top-level theorems
construct the new form natively, routing through the wrappers) →
**incremental destructive retirement** (one decl per commit: delete
the wrapper, rewrite the body decl, update the now-wrapper-only
callers). Diagnostic for "this slice is truly leaf-eligible": its
**only** in-Lean caller is its own wrapper.

### Test the constructor shape against the awkward consumer

When designing an inductive's constructor data, the typical
consumer looks cleanest when the constructor bundles everything it
needs; it is the *awkward* consumer that reveals whether the
bundle's contents do different jobs. **If even one consumer
consumes only the "structural" subset of the bundle and synthesizes
or ignores the rest, the constructor is over-coupling two concepts
— split it: keep the structural part in the constructor, lift the
analytic / situational part to a sibling predicate.** Before
committing the shape, walk *each* consumer that will pattern-match
on the constructor — including the awkward ones — and ask whether
it actually consumes every field. Sibling of the migration rule
above: both say "pick by the worst case, not the typical case", one
for migration strategy and one for type design.

---

## Choices to revisit

Decisions made under uncertainty that should be revisited if the
underlying assumption changes. Each entry names the choice, the
condition that would trigger reconsideration, and the alternative.
When an entry's trigger surface has been fully exercised without
forcing reconsideration, move it to *Settled decisions* below.

<!-- Example entry (delete when populating):

- **Predicates as `def` not `abbrev`.** Decision: keep
  `IsSparse` / `IsTight` / etc. as non-reducible `def`s. Trigger
  for reconsideration: if 5+ proof sites end up with explicit
  `refine ⟨?_, ?_⟩` boilerplate solely to expose the def's
  structure, the cost-benefit shifts toward `abbrev`. Alternative:
  convert to `abbrev` and accept reducibility in matching/elaboration.

-->

TODO: populate as decisions accumulate.

---

## Settled decisions

Decisions originally filed under *Choices to revisit* whose trigger
surface is now fully landed and exercised without surfacing the
condition that would have forced reconsideration. Kept here as
design history — the next agent doesn't have to re-derive *why* the
project picked one shape over another, but should not treat these
as open for re-litigation absent new evidence.

<!-- Each entry: the decision (with where it was made), the
alternative considered, and the evidence that settled it — which
phases exercised the trigger surface and what would be required to
re-open it. -->

TODO: populate as *Choices to revisit* entries graduate.
