# {{PROJECT_NAME}}/CLAUDE.md — Lean source operating manual

This file is the **agent-facing operating manual** for working with
the project's Lean source. It auto-loads when an agent reads any
`.lean` file under this directory.

Top-level `../CLAUDE.md` covers project-wide process (reading order,
hand-off contract, citations, project history). This file carries
the Lean-specific discipline: build/lint gates, friction review,
MCP tool guidance, and the symptom-indexed quirks index.

For the blueprint side (TeX, dep-graph, `checkdecls`, `inv bp`/`inv
web`), see `../blueprint/CLAUDE.md`. For notes/phase-log discipline,
see `../notes/CLAUDE.md`.

## Reading order

In addition to the project-wide reading order in `../CLAUDE.md`:

- **`../TACTICS-QUIRKS.md`** — rescue reference, symptom-indexed.
  Skim the section titles at session start (they're enumerated in
  the [Quirks index](#quirks-index-skim-this-first) below). When a
  build fails with an unfamiliar Lean error, the inline index below
  is the first place to look.
- **`../TACTICS-GOLF.md`** — golfing / improvement reference. Read
  at cleanup time (when the `simplify` skill fires, or when
  shrinking/polishing a proof before commit), **not** during
  first-draft writing.
- **`../notes/FRICTION.md`** — optional skim for an open
  upstream-eligible item to land alongside the session's main work.

## Quirks index (skim this first)

When a `lake build` fails with an unfamiliar Lean error, scan these
bullets. If one matches, jump to the named section of
`../TACTICS-QUIRKS.md` for the fix:

- `omega`/`grind` fails despite hypotheses that should bridge →
  check for `set`-aliased terms (§ 1) or for commutativity /
  distributivity that needs pre-normalization (§ 2)
- *"Unknown identifier X"* after `rcases ⟨rfl, rfl⟩` or `subst`
  between two free vars → § 3 *`subst` between two free variables
  picks the wrong one*
- *"motive is not type correct"* after `simp only`, citing a
  hypothesis not in the displayed goal → § 4 *`simp only` leaves
  residual subterms*
- `simp [name]` on a `set`-bound lambda doesn't unfold (or `⊢ sorry
  () c = …` glitch) → § 5 *`set name := fun … + simp [name]`*
- `interval_cases (Fintype.card V)` won't close by `rfl` → § 6
  *`interval_cases` is for free variables*
- `And.foo not found` / `SubNamespace.X.foo not found` via dot
  notation → § 7 *Dot notation only consults the type's head
  namespace*
- `simp_all` produces a confusing residual with a hypothesis you
  expected to eliminate → § 8 *`simp_all` cross-contaminates*
- `set V₊ := …` / `let V₊ := …` (or any identifier with `₊ ₋ ₌`)
  errors with *"expected token"* at the subscript column → § 9
  *Subscript `₊` (U+208A) is not a valid identifier character*
- *"MVar does not look like a recursive call: ... → V → Fintype V"*
  on a WF-recursive def whose `termination_by` uses `Finset.univ`,
  or *"Unknown identifier `visited`"* from `termination_by` after a
  `| visited, v => ...` pattern-match body, or `unused variable`
  lint on an `if h : ...` binder used only inside `decreasing_by` →
  § 10 *`termination_by` / `decreasing_by` elaboration rescue*
- *"Application type mismatch: heq has type X = some ⟨…⟩ but is
  expected to have type some ⟨…⟩ = some ⟨…⟩"* inside the `some`
  branch of a `match heq : <expr> with | …` term — § 11 *`match h :
  <expr> with` substitutes `expr ↦ pat` in the goal of each branch*
- *"Tactic `rewrite` failed: motive is not type correct"* when
  `rw [h]` uses `h : D.field = …` and the goal contains a local
  whose *type* references `D.field` — § 12 *`rw [h]` over a
  structure field whose value appears in another local's type*;
  build the rewritten container equation via `Finset.ext` and `rw`
  the equation as a unit.
- *"Application type mismatch"* on the first hypothesis used inside
  a `case caseN D h₁ ... =>` after `induction _ using funName.induct`,
  or *"Did not find an occurrence of the pattern"* on a `rw [hyp] at
  h` whose LHS visibly appears in `h` — § 13 *`induction … using
  funName.induct` on a function with `let` in its body*; name the
  `let`-bound parameter in the case-binder list, and apply `dsimp
  only at h` after `rw [funName] at h` to inline the inner `let`.
- `ring` reports *"unsolved goals"* on a sum-of-sums identity
  `Σ + B = B + Σ'` where `Σ` and `Σ'` are alpha-equivalent
  `Finset.sum`s (same Finset and body, different bound-variable
  name) — § 14 *`ring` fails on alpha-renamed `Finset.sum`s*; bind
  each sum identity as a named `have` and close the surrounding
  linear (in)equality with `omega` / `linarith`, both of which
  treat each `Finset.sum` as an opaque atom.
- *"Invalid `meta` definition `_eval`, `instFoo` is not accessible
  here; consider adding `public meta import X`"* on a `#eval (decide
  P)` (or any `#eval` synthesising an instance from a sibling
  `module` file) — § 15 *`#eval`-bearing `module` files need `public
  meta import` for the imported `Decidable` / elaboration instances*:
  keep `public import X` for compile-time visibility and add a
  second-form `public meta import X` for meta-time visibility.

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

## Module-system conversion

Project files use Lean's module system (`module` + `public import`
+ `@[expose] public section`) for the same reason mathlib does:
downstream files only see the public interface of an imported
module, not its full elaboration state. The mechanic is uniform
across all files and matches the upstream reference
`Mathlib/Analysis/InnerProductSpace/PiL2.lean`.

When converting a new file, or when fixing a file that drifted out
of the pattern:

1. **After the copyright block, insert a blank line then `module`.**
   ```
   /-
   …
   -/
   module
   ```
2. **Rewrite every `import X` to `public import X`** — both upstream
   mathlib imports and project-internal imports
   (`{{PROJECT_NAME}}.Mathlib.X`, `{{PROJECT_NAME}}.Y`).
3. **Between the doc block (`/-! … -/`) and the first
   `open`/`namespace`/declaration, insert an unnamed `@[expose]
   public section`.** Example:
   ```
   /-! # Title … -/

   @[expose] public section

   namespace Foo
   ```
   The section is unnamed and closes implicitly at end-of-file — no
   matching `end` is needed. Existing `namespace X / end X` pairs
   stay paired as before.

Constraints and gotchas:

- **A `module` file can only `import` other `module` files.** If
  you add a new project-internal import, the imported file must
  already be `module`-converted. (Build error: *"cannot import
  non-`module` X from `module`"*.)
- **Recent mathlib is ~98 % `module`-converted**, so almost
  every `Mathlib.X` import already satisfies the constraint. The
  remaining files are deep upstream pieces most projects don't
  depend on.
- **Non-`module` files can freely import `module` files**, so
  external consumers (blueprint snapshot tests, scratch files) work
  unchanged.
- **No `import` line for `module` itself** — the bare keyword on its
  own line is the marker, not an import.
- **`public section` is opaque intra-module too — not just
  cross-module.** A `def` in `public section` (no `@[expose]`) has
  its body hidden for elaboration-time defeq even within the same
  file (close to `@[irreducible]` semantics). Symptoms a new
  intra-file consumer trips: *"Not a definitional equality: the
  left-hand side"* on a `@[simp] … := rfl` projection lemma; *"Type
  mismatch … definitions were not unfolded because their definition
  is not exposed: foo ↦ N"* on a `match`-arm whose result type needs
  `foo`'s body. **Fix:** promote the specific `def` to `@[expose]
  def …`; the surrounding section can stay `public section`. The
  default for a new file is `public section`; reach for
  `@[expose] public section` only when *most* of the file's defs
  need body exposure.
- **`set_option backward.privateInPublic …` is technical debt and
  must be eliminated, not propagated.** The option is a `backward.*`
  compat knob that re-enables legacy "private-callable-from-public"
  semantics — it exists to ease the module-system migration and the
  reference manual explicitly says *"These warnings can be used to
  locate and eventually eliminate these references, allowing
  `backward.privateInPublic` to be disabled."* Do not introduce new
  opt-ins.

  Mechanics: the opt-in is required only when a private declaration
  participates in an *exposed* body — a `def` / `instance` body or
  signature in `@[expose] public section`. Proof bodies of `theorem`
  / `lemma` are in the *private scope* regardless of section
  attributes (per the reference manual *Modules and Visibility* /
  *Exposed and Unexposed Definitions*), so a `private lemma`
  referenced only from public `theorem` proof bodies needs no opt-in
  at all. When the build fails with *"Unknown identifier X. Note: A
  private declaration X (from the current module) exists but would
  need to be public to access here"*, the short-term fix is the
  per-declaration form applied to **both** the private declaration
  and its public consumer:
  ```
  set_option backward.privateInPublic true in
  set_option backward.privateInPublic.warn false in
  private def myHelper ...

  set_option backward.privateInPublic true in
  set_option backward.privateInPublic.warn false in
  noncomputable def MyConsumer ...
  ```
  The set_option lines go *before* the doc-comment, not after — the
  doc-comment must immediately precede the declaration it documents.
  **A `private theorem` tagged `@[fun_prop]` / `@[simp]` / `@[ext]`
  / etc.** that downstream tactics resolve by name also needs the
  opt-in, because the tactic database stores the private name and
  cross-module references then fail. For attribute-tagged
  helpers, demoting from `private` to plain public is often the
  cleaner fix and is preferred to a new opt-in.

## Lean LSP MCP — reach for it

`.mcp.json` at the repo root registers
[`lean-lsp-mcp`](https://github.com/oOo0oOo/lean-lsp-mcp); approve
the server on first prompt. File paths resolve against the project
root. **An MCP call is sub-second; an `edit + lake build` cycle is
30+ seconds — the cost asymmetry is the whole point.** Whenever you
would otherwise:

- guess at a closing tactic — use `lean_multi_attempt` at the proof
  position to A/B-test several candidates
  (e.g. `["grind", "omega", "simp", "ring"]`) in one round-trip,
  instead of editing-and-rebuilding for each guess. Same for
  finding the right `simp [...]` argument set.
- hunt for a mathlib lemma via `grep -rn` in
  `.lake/packages/mathlib` — use `lean_loogle` (type pattern) or
  `lean_leanfinder` (concept) instead; both are faster and return
  structured results.
- open an upstream `.lean` file to read a signature — use
  `lean_hover_info` at the identifier's start column.
- insert a `sorry` and rebuild to see what the intermediate goal
  looks like — use `lean_goal` at the line (omit `column` for
  before/after; pass `column` for an exact position).
- check the project's existing API for a name match — use
  `lean_local_search` instead of `grep -rn` on the project's
  `.lean` files.

Run `lake build` once before the first MCP call (warms `lake
serve`); skip if you've built recently this session. **Do not call
`lean_leansearch`** — its endpoint has been down since late 2025;
use `lean_loogle` / `lean_leanfinder` instead. Full decision tree,
cold-start details, and `lean_multi_attempt` payload shape in
`../TACTICS-GOLF.md` § 4.

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
`mathlibStandardSet` linter misses, so don't skip it.

Newly-added `@[simp]` attributes are the usual offenders — if the
LHS is reducible by existing simp lemmas, drop the `@[simp]` (the
lemma stays callable by name) rather than working around with
`@[nolint simpNF]`. Reserve `@[nolint unusedArguments]` for instance
args that are semantically required by the definition's contract
but not consumed by elaboration; always add a one-line comment
justifying it.

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
