# Tactics — golf reference

This file is the project's **golfing reference**: proof patterns we
use repeatedly and the "always do X" rules that turn verbose
first-draft proofs into idiomatic ones. Read this when reviewing,
shrinking, or polishing a proof — at the `simplify` skill / cleanup
pass time, **not** during first-draft writing.

For **rescue / build-failure recovery** (when a `lake build` fails
with a mysterious Lean error), see `TACTICS-QUIRKS.md` instead — it's
symptom-indexed and lighter.

> **Friction vs. idiom.** This file holds *general* lessons — rules
> that apply across the project. One-shot frictions (a specific
> missing lemma, a specific bug) live in `notes/FRICTION.md`. Don't
> mix them: a "use X instead of Y" rule belongs here; a "I needed
> lemma Z and mirrored it" entry belongs in FRICTION.

## Sections

1. **`grind` workflow** — when to reach for `grind`, how to feed it
   hints, how to debug it when it fails.
2. **Mirror-first rule** — if you needed a lemma upstream-eligible,
   mirror it before landing the proof.
3. **`fun_prop` for continuity / differentiability** — replace explicit
   `Continuous.add` / `Continuous.comp` chains with `by fun_prop` and tag
   project helpers `@[fun_prop]` so they participate in the search;
   value-form `HasDerivAt` / `HasFDerivAt` goals stay on the named
   chain-rule API regardless of tagging.
4. **Lean LSP MCP** — when to use `lean_*` tools vs. the `Read` + `lake
   build` workflow, the local-first search order, and known-broken
   external services.
5. **`linear_combination` with rational coefficients** — pass
   `(norm := (field_simp; ring))` when the combination's scaling factor
   is a rational function of an in-scope free variable; the default
   `ring` post-check fails on such denominators.
6. **Bake let-bound predicate shapes into helper signatures** — when
   factoring a cross-`.induct`-case helper that consults a `let`-bound
   predicate `P`, bake `P`'s specific lambda directly into the helper's
   parameter type instead of taking `P` abstract + an `hP_def` equation.
7. **`gcongr` for monotonicity-chain rewrites** — reach for `by gcongr`
   on `mul_le_mul_of_nonneg_*` / `mul_lt_mul_of_pos_*` / `add_le_add`-shape
   goals; its positivity discharger cannot extract per-index facts from a
   `∀`-quantified hypothesis — pre-extract a per-index `have` first.
8. **`dsimp only` over `change <RHS>` for definitional goal reshape** —
   when the reshape is definitional (let-elimination, beta-reduction,
   named unfolding), `dsimp only [names]` is shorter and name-anchored,
   so it survives signature drift; `change` stays for propositional
   bridges and refine-binder shaping.
9. **Drop `simp`-default rewrites from a multi-step `rw` chain** — when
   ≥2 rewrites of a 4+ argument `rw [a, b, c, d]` chain sit in `simp`'s
   default set, fuse to `simp [<non-default-hints>]`, naming only the
   hypothesis equations and `←`-direction rewrites.
10. **Collapsing indicator sums** — factor a constant out with
    `← Finset.mul_sum` before `Finset.sum_ite_eq'`; the collapse fires
    only when the `if` is the whole summand.
11. **Strong induction on a derived measure** —
    `induction hN : m G using Nat.strong_induction_on generalizing G`;
    `generalizing` is mandatory, the IH threads the measure-equation
    first (`IH _ hlt G' rfl …`), and don't `subst hN`.
12. **Iterating `+1` around a cyclic `Fin m`** — to propagate a
    consecutive-equality `f i = f (i+1)` to a global one, induct over
    `Fin.ofNat m j` on ℕ (not `(j : Fin m)` ascription, not
    `Fin.induction`); `Fin.ofNat_val_eq_self` returns to `i`.
13. **State a ℕ count `a − b + c` as `a + c − b`** — subtraction last,
    so the single truncating `−` lands on a provably-large-enough
    quantity (otherwise the statement is off-by-one at a boundary and
    `omega` can't prove it).
14. **LI family of `finrank`-many vectors spans `⊤`** — `LinearIndependent`
    + `Fintype.card ι = finrank` ⟹ `span (range v) = ⊤`, via
    `basisOfLinearIndependentOfCardEqFinrank` + `coe_…` + `Basis.span_eq`.
15. **`(∑ i, f i).comp g` — go pointwise** — no `LinearMap.sum_comp` exists
    and `map_sum` won't fire on `· ∘ₗ g`; discharge a `∘ₗ`-outside-
    `Finset.sum` identity with `LinearMap.ext` + `LinearMap.congr_fun` +
    `LinearMap.sum_apply`.

---

## 1. `grind` workflow

Most closing tactics here are `grind`. This section is the practical
reference: when to reach for it, how to feed it hints, how to debug it
when it fails, and the iteration loop we use to land proofs.

For the full reference see the Lean manual, chapter
*The `grind` tactic*. This document is the project-specific subset
plus tricks worth knowing.

### TL;DR workflow

Replace any closing `omega` / `simp` / `linarith` with `grind` first.
If it works, you're done. If it doesn't:

1. Stage facts as `have` lines so they sit on `grind`'s "whiteboard."
2. If `grind` still fails, switch to `grind?` and inspect:
   - **The suggestion line** — `grind?` prints a `grind only [...]`
     call with exactly the lemmas it actually used.
   - **The diagnostics** — when `grind` fails it dumps the whiteboard:
     known equalities, the cutsat assignment, the E-matching theorems
     it considered. Read this to see *what `grind` thinks is true*.
3. Once `grind` succeeds with hints, run `grind?` once and replace it
   with the suggested `grind only [...]` form. That's the final shape.

`grind only` is preferred over `grind` for landed proofs: it pins the
exact lemma set, doesn't drift if mathlib re-tags `@[grind]` lemmas,
and runs faster.

### Invocation forms

| Call | Effect |
|---|---|
| `grind` | Use ambient `@[grind]`-annotated library + heuristics. Default for exploration. |
| `grind [foo, bar]` | Same, plus `foo`, `bar` as one-shot hints. |
| `grind only` | Use *only* what's listed (and a small core). More deterministic. |
| `grind only [foo, bar]` | The form `grind?` recommends; what we land on. |
| `grind?` | Run, then print a `grind only [...]` suggestion. The iteration tool. |

The hint list accepts prefix tags `=`, `←`, `→`, `_=_`, `!`. These tell
`grind` how to use that particular lemma — `=` for left-to-right
rewrite, `←` for backwards reasoning, etc. (see "Annotations" below).
You don't normally write these yourself; copy them verbatim from the
`grind?` suggestion.

### How `grind` works (one paragraph)

`grind` maintains a "whiteboard" of known facts. Cooperating engines
read from and add to it: congruence closure (equality propagation),
constraint propagation, E-matching (instantiates `@[grind]`-annotated
quantified lemmas when patterns match), guided case analysis,
and theory solvers — `cutsat` for linear integer arithmetic and a
commutative ring solver. It always proves goals by deriving a
contradiction; conclusion and premises are treated symmetrically.

What this buys us beyond `omega`:
- Equational reasoning across multiple terms (congruence closure).
- Library lemmas fire automatically once their pattern matches a term
  on the whiteboard (E-matching).
- Mixed arithmetic + equational goals close in one step.

What it *doesn't* do:
- It does **not** unfold non-`abbrev` definitions. Expose the
  structure with `refine ⟨?_, ?_⟩` (for `And`-shaped defs) or pass
  the def name as a hint (`grind only [MyDef]`) to unfold it on the
  whiteboard.
- It does **not** automatically apply `@[simp]` lemmas. They need a
  separate `@[grind =]` annotation, or pass them as hints.
- It is **not** for goals with combinatorially explosive case-split
  structure (large pigeonhole, N-queens, SAT-like). Different tools
  exist for those (`bv_decide`, etc.).

### Reading a `grind` failure

When `grind` can't close, it prints its whiteboard. Two sections matter:

```
[cutsat] Assignment satisfying linear constraints
  [assign] Fintype.card (Fin 2) := 5
  [assign] s.card := 2
```

This shows the *integer assignment* `cutsat` found that satisfies all
the constraints `grind` knew about. If something obviously wrong is
assigned a "free" value (e.g. `Fintype.card (Fin 2) := 5`), `grind`
didn't have the fact pinning it. Add the missing lemma as a hint
(`Fintype.card_fin`, in this case).

```
[ematch] E-matching patterns
  [thm] Nat.card_eq_fintype_card: [Nat.card #1]
  [thm] Sym2.rel_iff': [Sym2.Rel #2 #1 #0]
```

Theorems whose patterns `grind` considered. If a lemma you think
should fire doesn't appear here, its pattern didn't match (often
because of a hidden coercion, or the relevant term hasn't reached the
whiteboard yet — try a `have` to surface it).

### Annotations (reference)

You won't usually add these in this directory — we pass lemmas as
hints — but you'll see them in `grind?` output and may need them in
upstream PRs.

| Attribute | Pattern from | Meaning |
|---|---|---|
| `@[grind =]` | LHS | Rewrite LHS → RHS when LHS appears. Use for simp-style lemmas. |
| `@[grind _=_]` | both sides | Bidirectional rewriting. |
| `@[grind ←]` | conclusion | Try the lemma when its conclusion matches a goal. |
| `@[grind →]` | hypotheses | Fire when the hypotheses match the whiteboard. |
| `@[grind]` | (default) | Heuristic combination of above. |
| `@[grind <=]` | conclusion, then hypotheses | Multi-pattern; conclusion-first. |

Custom patterns:
```lean
grind_pattern foo => pat₁, pat₂ where guard cond, x =/= y
```
Fires `foo` only when both `pat₁` and `pat₂` match simultaneously.

### Tricks worth knowing

**Stage facts on the whiteboard with `have`.** If a closing `grind`
fails, lifting an intermediate fact to a `have` line (even with a
trivial proof) often makes it succeed:

```lean
fun hH => by
  have := hG.some_fact
  have := hH.some_fact_with_precondition (by grind only)
  have := Set.ncard_lt_ncard h_subset finite_witness
  grind only
```

The `have` lines surface facts `grind` couldn't synthesize on its
own. Once they're on the whiteboard, the closing `grind only` often
finishes by linear arithmetic alone.

**Use `(by grind)` in argument positions.** When applying a lemma like
`hH.foo (precondition)`, write `hH.foo (by grind)` rather than
`have h := …; hH.foo h`. Saves a line.

**Inject finite-cardinality facts directly.** `grind` will not derive
`Fintype.card (Fin 2) = 2` on its own. Pass `Fintype.card_fin`,
`Nat.card_fin`, or `Nat.card_eq_fintype_card` as hints whenever the
goal involves cardinalities of concrete finite types. The `[cutsat]`
diagnostic will tell you when it's missing — it'll assign a wrong
value to the cardinality.

**`grind` doesn't always pick up coercions.** A goal with `↑s` where
`s : Finset V` may need `Finset.coe_univ` (or whichever coercion lemma
applies) as an explicit hint. The `grind?` suggestion will show a `!`
prefix on lemmas it found via this kind of pattern matching.

**When in doubt, run `grind?` and copy the answer.** It is, by
construction, the minimal hint set that works for the current proof.
The `=`/`←`/`→`/`!` prefixes in the suggestion are syntactically valid
in `grind only` calls — paste verbatim.

**Default `simp` before `grind` can subsume `change` + multi-`rw` staging.**
If you find yourself writing `change ... ; rw [lemma_A] ; simp only [B, C]
; split_ifs <;> grind` to shape a goal into `grind`-ready form, try
collapsing the prologue to `simp [lemma_A]` (default simp set, not
`simp only`, and with just the lemma that's not in `@[simp]`). The
default set tends to absorb the wrapper / coercion boilerplate that
`change` was unfolding by hand, and `grind` itself does the `split_ifs`
work.

**Name the rewrite, don't paraphrase the goal.** A `change <unfolded
form>` whose only job is to expose what a downstream `rw` / `simp`
needs is friction whenever the unfold has a named lemma. Replace
with the `rw` / `simp only` form for self-documentation:
`change x ∈ Set.Ioi 0` → `rw [Set.mem_Ioi]`;
`change (s.restrict f) x = …` → `rw [Set.restrict_apply]`;
unfolding a local `set`/`let` binding `h_def : foo = expr` → `rw
[h_def]` (or fuse into a downstream `simp only [h_def, …]`). No-op
`change`s (goal-form unchanged before/after the `change`, sitting
next to a `linarith` / `ring` / `simp` that operates on the same
display) are pure noise and remove cleanly — usually the only thing
they did was add a visible signpost the proof body already carries
via the named hypothesis next to it.

**Keep `omega` in the back pocket.** For goals that are pure linear
integer arithmetic with no equational reasoning to do (and where you
don't need any lemma hints), `omega` is faster and more readable. Default
to `grind` because most goals mix arithmetic with equational steps, but
`omega` is the right call for purely arithmetic ones.

**Synthesize typeclass instances from data, not from a dichotomy.**
When a helper lemma requires `[Nontrivial X]` / `[Nonempty X]` / similar
and you'd otherwise reach for `by_cases h : Subsingleton X` to handle
both sides, check whether the data the *other* branch is built from
already supplies the instance you need. If so, branch on that data
condition instead — the typeclass becomes a one-line
`haveI : Nontrivial X := nontrivial_of_ne v b hne` inside the branch
that needs the helper, and the easy sub-case (where the data condition
fails) usually collapses to a direct calculation that subsumes the
Subsingleton case. (Observed in: a compactness proof that replaced
`by_cases h : Subsingleton V` — with separate singleton-vs-Nontrivial
branches that mostly duplicated end-game calculations — by a case
split on membership in a distinguished vertex set, synthesizing
`Nontrivial V` from a witness distinct from `v` via
`nontrivial_of_ne` in the branch that needed it.) The dichotomy is
the leftover of "the helper wants `Nontrivial`"; the data branch is
the *cause*, and branching there eliminates the leftover.

> Three `omega`/`grind`/`nlinarith` quirks that show up at
> first-draft time (set-aliased atoms, commutativity/distributivity)
> live in `TACTICS-QUIRKS.md` §§ 1–2, where they're indexed by symptom
> for mid-proof lookup.

### Where `grind` doesn't help

For symmetry with the above: it is also useful to know what `grind`
*won't* close, so you don't waste a cycle trying.

- **Goals bottoming out in a case-split on a non-`abbrev` pair-like
  shape** (such as the two orientations of a symmetric pair) that
  `grind` does not perform on its own. Use an explicit `rintro` /
  `rcases` to dispatch the case-split, then let `grind` close each
  branch.
- **Pure linear arithmetic with staged `have`s.** When the closing
  step is just chaining the staged facts via `+` / `≤`, `omega` is
  faster and the proof is more readable. Reserve `grind` for goals
  that mix arithmetic with a rewrite or with E-matching against a
  library lemma.

---

## 2. Mirror-first rule

If a proof would benefit from a lemma that morally belongs upstream
(`SimpleGraph`, `Set.ncard`, `Finset`, `Sym2`, etc., not specific to
the project's mathematics), put it under `{{PROJECT_NAME}}/Mathlib/<exact mathlib path>`
in the same commit and refactor the proof to call it. Don't inline a
hand-rolled version in a project file — that loses the upstream-able
artifact.

Concretely:
- The Lean namespace stays the upstream one (`Set`, `SimpleGraph`,
  `Sym2`, etc.). The mirror file imports the upstream module and adds
  alongside it.
- File path mirrors the upstream path exactly: a future PR is then
  copy-paste.
- The directory `{{PROJECT_NAME}}/Mathlib/` is created
  lazily; don't pre-populate.
- Each mirrored lemma also gets a `[mirrored]` entry in
  `notes/FRICTION.md` with its mirror-file path.

See `DESIGN.md` "Mirror directory" for the full mechanics.

Why we go to this trouble: the resolved entries in
`notes/FRICTION.md` are the running list of "lemmas the project found
mathlib should have." They mature into upstream PRs. Inlining a
hand-rolled version skips that pipeline.

### Search mathlib before mirroring

Before reaching for a mirror, sweep `lean_loogle` (type pattern) or
`lean_leanfinder` (concept). The "mirror it ourselves" instinct
bloats the project surface, and mathlib's API is denser than it
looks.

**Rule of thumb: search by *type pattern of what you need*, not by
your guess of what mathlib calls it** — names drift, types don't.
Recurring shape: an apparently project-specific glue lemma
(e.g. "linear maps agreeing on a spanning set are equal", "2 ≤
s.card from two distinct witnesses") dissolves into a one-line
upstream find once you query loogle by the expression's *type
signature* rather than guessing at the canonical name.

---

## 3. `fun_prop` for continuity / differentiability

`fun_prop` chains continuity (and differentiability, measurability, etc.)
facts automatically; prefer it over hand-written `Continuous.add` /
`Continuous.comp` / `continuous_pi` chains and over hand-written
`ContDiff.comp` / `ContDiffAt.comp` / `Differentiable.comp` chains.
Local `Continuous` / `ContDiff` / `Differentiable` hypotheses in scope
are picked up automatically.

**Property-form goals are in reach; value-form derivative goals are
not, even when tagged.** `fun_prop` discharges goals of the shape
`Continuous f`, `Differentiable 𝕜 f`, `ContDiff 𝕜 n f`,
`ContDiffAt 𝕜 n f x` — the *function-property* family. For
value-form goals like `HasDerivAt f f' x` / `HasFDerivAt f L x` the
situation is subtler: mathlib *does* `@[fun_prop]`-tag selected
value-form lemmas (`HasFDerivAt.comp`, `.fst` / `.snd` / `.prodMk`,
etc.), so tagging a bare `HasDerivAt` head is at least syntactically
legitimate — but empirically the discharger architecture cannot
synthesize a chain-rule derivative term that unifies with a
goal-specific derivative, and `fun_prop` still fails even with the
predicate and the relevant chain rules (`HasDerivAt.comp`, `.add`,
`hasDerivAt_id`, …) all tagged. **Net rule: don't reach for
`fun_prop` on value-form `HasDerivAt` / `HasFDerivAt` goals,
regardless of tagging — the named chain-rule API (`.comp`,
`.comp_of_eq`, `.congr_of_eventuallyEq`) is the canonical fix.**

**Discharger limitation: `∀`-quantified preconditions.** When
`fun_prop` needs a per-index fact like `f e ≠ 0` to apply a
preconditioned chain rule (e.g. `ContDiffAt.rpow`), it cannot
extract that fact from a universally-quantified hypothesis like
`hf : ∀ e, 0 < f e` already in scope. Pre-extract a per-index
`have hne : f e ≠ 0 := (hf e).ne'` first — the same limitation is
shared by the `gcongr` and `positivity` dischargers (see § 7). In
practice the named `.comp` chain is often shorter than the
pre-extraction dance; pick whichever reads better.

### Pattern

When a project helper returns a `Continuous` fact that future continuity
goals need to chain through, tag the helper:

```lean
@[fun_prop]
private theorem continuous_myMap_apply ... : Continuous … := …
```

Downstream goals like `Continuous (fun p => fun i => myMap p (preimg i))`
then close in one line:

```lean
have h_cont : Continuous … := by fun_prop
```

instead of the multi-line `continuous_pi (fun i => continuous_pi (fun e => …))`
nest.

### When the goal mentions a project-internal `def`

`fun_prop` does *not* unfold non-reducible `def`s. If the goal mentions
`MyMap p x` (which is a `def`), surface the underlying expression with
a `simp only [myMap_def]` first, then `fun_prop`. The tagged helper
itself usually does this internally.

### `Function.update` continuity

`Continuous.update` (mathlib, `Topology/Constructions.lean`) directly
closes the "pi-typed function with one coordinate replaced" pattern.
`fun_prop` finds it automatically.

---

## 4. Lean LSP MCP

`.mcp.json` at the repo root registers
[`lean-lsp-mcp`](https://github.com/oOo0oOo/lean-lsp-mcp). Full tool
catalog at the upstream
[`docs/tools.md`](https://github.com/oOo0oOo/lean-lsp-mcp/blob/master/docs/tools.md);
this section is the *project-specific* tactical guidance.

### TL;DR

- Run `lake build` once before the first LSP-touching call (warms up
  `lake serve`); skip if you've recently built.
- Look up a lemma by *concept*: `lean_loogle` (type pattern) or
  `lean_leanfinder` (semantic).
- Look up a lemma by *project-internal name*: `lean_local_search`.
- Look up a lemma by *current goal*: `lean_state_search` or
  `lean_hammer_premise`.
- Inspect a proof state: `lean_goal` (line for before/after, line+col
  for at-position).
- Quick "does X exist / what's its signature": `lean_hover_info` at the
  identifier's start column.
- Sanity-check the file: `lean_diagnostic_messages` instead of
  `lake build`-on-loop.

### Cold start

First `lean_goal` / `lean_diagnostic_messages` call after starting a
session triggers `lake serve`; expect a ~30-second wait or a one-time
LSP timeout. Subsequent calls in the same session are fast (≪ 1 s).
Mitigations:

- Run `lake build` *before* the first MCP call — this is the README's
  standing recommendation and avoids the cold start entirely.
- If a tool times out once, retry — the timed-out call still kicks
  `lake serve` into action.

### Search decision tree

Before reaching for any tool, decide what you're searching by:

| Question | Tool |
|---|---|
| Does `Foo.bar_baz` exist in this project? | `lean_local_search` |
| What's the project name for "X"? | `lean_local_search` (prefix match) |
| Mathlib lemma with type pattern `_ * (_ + _) = _ * _ + _ * _`? | `lean_loogle` |
| Mathlib lemma about "submodule generated by linearly independent set"? | `lean_leanfinder` |
| What closes the current goal? | `lean_state_search` |
| Which premises should I feed to `simp`/`aesop`? | `lean_hammer_premise` |

After a hit: `lean_hover_info` at the identifier's start column to
confirm the signature before invoking it in a proof.

### Avoid `lean_leansearch`

`leansearch.net` has been down for an extended period (HTTP 521 from
its Cloudflare front-end as of late 2025 / early 2026). Skip it
entirely; `lean_loogle` and `lean_leanfinder` cover the same use cases
with different query styles, and `lean_local_search` handles
project-internal lookups.

### `lean_multi_attempt` for tactic A/B testing

When you've narrowed a failing step to "one of these tactics should
close it", `lean_multi_attempt` runs several candidates against the
exact source position in one round-trip and reports which succeeded.
Faster than editing-and-rebuilding for each guess, especially when
each rebuild takes 30+ seconds. Example payload:
`["simp", "ring", "omega", "exact?", "tauto"]`.

### When the MCP is unavailable

The MCP server is a *convenience*, not a dependency. If `uvx` can't
reach PyPI, or the LSP refuses to start, or you're working from an
environment without network, the standard `Read` + `lake build`
workflow remains the source of truth: read the relevant `.lean` file,
edit, rebuild, inspect the compiler output. Don't block on MCP issues.

---

## 5. `linear_combination` with rational coefficients

`linear_combination` closes ring-level equations by accepting a linear
combination of hypotheses whose sum equals `lhs − rhs` of the goal.
Its default post-normalizer is `ring`, which **does not** simplify
divisions by a free-variable polynomial like `(s − 1)`. When the
natural scaling factor for one of the hypotheses is `c / (s − 1)`
(for some in-scope `c`), the `ring` check rejects the proof even
though the equation is correct as a rational identity. The fix is to
override the normalizer:

```lean
linear_combination (norm := (field_simp; ring))
  (c_a / (s - 1)) * h_combo + (B / (s - 1)) * h_cb_rel
```

`field_simp` clears the `(s − 1)` denominator first (using in-scope
non-zero hypotheses); `ring` finishes the polynomial identity check.
Pre-declare `have hs1_ne : s - 1 ≠ 0 := sub_ne_zero.mpr hs1` if
`field_simp` can't find the witness automatically.

**When to reach for it.** Whenever you'd write
`linear_combination ... / x * h` and the post-normalizer fails: try
`(norm := (field_simp; ring))` before pre-deriving the cleared form
manually. The cost is one `field_simp` invocation; the win is
keeping the proof at the level of the algebraic identity rather
than its denominator-cleared variant.

---

## 6. Bake let-bound predicate shapes into helper signatures

When a function's body has `let P : V → Bool := fun w => …` and you
want to factor a cross-`.induct`-case helper that consults `P`'s
shape, the naïve extraction (a top-level helper taking `P` as a
parameter) doesn't work: the helper's body can't `simp only [P, …]`
unfold because `P` is a free variable from its point of view. The
standard workaround — pass `P`'s shape as a `hP_def : ∀ w, P w = …`
equation argument, optionally with a `:= by rfl` default — adds
plumbing or relies on autoParam to elide it. **The shorter route**:
bake `P`'s specific lambda directly into the helper's parameter
type. At each `.induct` callsite the case-binder `P` (let-bound by
`.induct` to that exact lambda) defeq-reduces, so Lean unifies the
helper's bound `fun w => …` with the callsite's `P` without any
explicit equation argument.

### Pattern

```lean
-- Helper: bake `P`'s lambda into the parameter's type.
lemma MyResult.reachable_of_addPred
    {D : SomeState V} {u v : V}
    (r : MyResult D
           (fun w => decide (P₁ D w) && decide (w ≠ u) && decide (w ≠ v))) :
    Goal := …
```

```lean
-- Callsite (inside a `.induct` `case` whose body let-binds `P`
-- to exactly that lambda): no `hP_def`, no `simp [P]` plumbing.
case case3 D h₁ h₂ P r hr_eq ih =>
  …
  exact ih (r.reachable_of_addPred …) h
```

### When it doesn't apply

- If callsites need to pass *different* lambdas (a generic reusable
  helper across multiple predicate shapes), keep `P` abstract and
  take `hP_def` as a hypothesis.
- If you can't get to a place where `r : MyResult D P` is in scope
  with `P` let-bound (no `.induct`-style binding), there is no defeq
  channel for the unification.

---

## 7. `gcongr` for monotonicity-chain rewrites

`gcongr` is the right closer for the bread-and-butter
monotonicity-chain shape: a goal `f X ≤ f Y` (or `<`) where the
context supplies `X ≤ Y` (or `<`) and the appropriate positivity /
nonnegativity preconditions for the outer `f`. Keep the named
term-mode API (`Finset.sum_le_sum h`) when it's strictly shorter
than the tactic form.

### TL;DR

| Goal shape | Reach for | Note |
|---|---|---|
| `w * X ≤ w * Y` with `X ≤ Y`, `0 ≤ w` | `by gcongr` | discharger pulls `0 ≤ w` from `hw : 0 ≤ w` in scope |
| `w * X < w * Y` with `X < Y`, `0 < w` | `by gcongr; exact <0 < w>` | discharger reduces to the positivity precondition |
| `a + c ≤ b + d` with `a ≤ b`, `c ≤ d` | `by gcongr` | inside `calc` use `_ ≤ ... := by gcongr` |
| `∑ e ∈ s, f e ≤ ∑ e ∈ s, g e` with `h : ∀ e ∈ s, f e ≤ g e` | keep `Finset.sum_le_sum h` | gcongr works but `by gcongr with e he; exact h e he` is strictly longer |
| `∑ e ∈ s, f e < ∑ e ∈ s, g e` with `∀ e ∈ s, f e ≤ g e` + 1 strict witness | keep `Finset.sum_lt_sum hle ⟨e₀, ...⟩` | gcongr fires the wrong rule (all-strict) |
| Outer factors differ (`w * Z ≤ w * X + w * Y`, `Z ≤ X + Y`) | keep `have ... := mul_le_mul_*; linarith` | algebraic step, not a monotonicity step |

### Pattern

The conversion is uniform: replace a term-mode
`mul_le_mul_of_nonneg_left h₁ h₂` (or `_right`, or
`mul_lt_mul_of_pos_*`, or `add_le_add h₁ h₂`) with `by gcongr` and
let `gcongr`'s discharger find `h₁` (the inner ≤) and `h₂` (the
positivity precondition) by name in the local context.

When the positivity precondition lives behind a `∀`-quantified
hypothesis (e.g. `hw : ∀ e, 0 < w e`), pre-extract a per-index
`have` first:

```lean
have hw_e : 0 < w e := hw e   -- gcongr discharger needs this in scope
have : w e * X ≤ w e * Y := by gcongr
```

The `∀`-quantified-hypothesis limitation is shared with `fun_prop`
(§ 3, preconditioned chain rules) and `positivity` — the mathlib
discharger architecture does not extract per-index facts from `∀`
hypotheses. Pre-extracting the per-index `have` is the standing
pattern.

### When the named API stays

Three structural cases keep the named term-mode API ahead of `by
gcongr`:

- **Outer factors differ.** Goal `w * Z ≤ w * X + w * Y` from
  `Z ≤ X + Y`. `gcongr` makes no progress because the RHS isn't a
  monotonicity step in `Z`; the chain needs an algebraic
  rearrangement (`have hwz := mul_le_mul_of_nonneg_left h hw.le;
  linarith`).
- **`Finset.sum_lt_sum` strict-witness shape.** When the hypotheses
  are `∀ e ∈ s, f e ≤ g e` plus a strict witness
  `⟨e₀, he₀, f e₀ < g e₀⟩`, the right rule is `Finset.sum_lt_sum`,
  which `gcongr` does not select — instead it fires the all-strict
  rule (`∀ e, f e < g e`), producing the wrong subgoal.
- **Line-count loss against term-mode `Finset.sum_le_sum`.** For
  `∑ e ∈ s, f e ≤ ∑ e ∈ s, g e` with `h : ∀ e ∈ s, f e ≤ g e`,
  `Finset.sum_le_sum h` is one term; `by gcongr with e he; exact
  h e he` is one tactic plus a follow-up. The term wins.

### Project-helper tags

Tag a project helper `@[gcongr]` only when an actual call site needs
it for `gcongr` to fire — the "only when observed needed" rule from
§ 3's `@[fun_prop]` discussion applies here too. Most
inequality-chain steps reach mathlib's `mul_le_mul_*` /
`Finset.sum_*` directly and need no project tags.

### When it doesn't apply

- **Goal isn't a monotonicity chain.** `gcongr` looks for an outer
  function (`*`, `+`, `^`, `/`, `∑`, …) shared between LHS and RHS
  and a hypothesis bridging the inner arguments. Goals where the
  outer differs, or where the chain crosses a non-monotone step,
  stay on the named API.
- **Multi-step chains with intermediate algebra.** A goal that
  *combines* a monotonicity step with a `ring`-rewrite or a
  `linarith` arithmetic step usually doesn't compress past `have
  := <monotone-step>; linarith`. `gcongr` does monotonicity; `ring`
  / `linarith` do algebra.

---

## 8. `dsimp only` over `change <RHS>` for definitional goal reshape

When `change <RHS>` is doing nothing more than a *definitional*
reshape — let-eliminating a `let` / `set` / inner-`have` binding,
beta-reducing a lambda application, or unfolding a definition via a
named lemma — reach for `dsimp only` instead. The `change` form
restates the full RHS (typo-prone, signature-fragile); `dsimp only`
names the unfolding facts and lets Lean compute the reshape. It is
shorter, name-anchored rather than form-anchored (so it survives
signature drift), and composes with subsequent `rw` / `refine`
chains without the next tactic having to re-match the restated form.

### Pattern

Three shapes this fires on:

```lean
-- (a) Lambda-beta reduction after a `set`-bound name: the closing
-- `simp [offset]` already beta-reduces; drop the `change`.
set offset := d + 1
…
-- change offset - (d : ℝ) = 0   ← delete
simp [offset]
```

```lean
-- (b) Let-elimination after `unfold` exposes a `let`-bound body:
-- `dsimp only` inlines the inner binding and exposes the `if`.
unfold myDef
dsimp only        -- not: change 0 < (if h : posSet.Nonempty then … else 1)
split_ifs
```

```lean
-- (c) Named-lemma unfolding of a let-bound linear map.
let g : (T → ℝ) →ₗ[ℝ] F := Fintype.linearCombination ℝ fun t : T => (t : F)
…
dsimp only [g, Fintype.linearCombination_apply]   -- not: change ∑ t : T, …
rw [Finset.univ_eq_attach, …]
```

The diagnostic signal for *"`change` is covering for a definitional
reshape, use `dsimp only`"*: the goal **before** `change` and the
goal **after** the next tactic differ only by definitional unfolding
(no propositional equality fires between them), and the `change`'s
RHS spelling restates a substring that would unfold under `dsimp`
given the right lemma names.

### When `change` (or the named lemma) stays

- **Propositional rewrites stay on `rw` / `simp`.** `dsimp only`
  *only* fires on definitional equalities (`rfl`-reducible
  unfoldings, beta, eta, let, projection). A coercion bridge that
  needs `Set.ncard_eq_toFinset_card'` or `Finset.coe_filter` (both
  propositional equalities, not `rfl`) stays on the named lemma —
  `dsimp only [Set.ncard_eq_toFinset_card']` will *not* fire.
- **`change` to fix a goal display for the next `refine`'s
  elaboration.** When the next tactic is a `refine` with explicit
  binder names whose types must literally syntactic-match the goal,
  `change` is the right tool. `dsimp only` may over-reduce.
- **Long restated RHS as documentation.** A two-screen `change …`
  whose RHS *is* the math the proof is asserting (rather than a
  trivial definitional reshape) stays — its prose-value is the
  reshape and removing it hurts readability.

### Diagnostic procedure

When you find yourself writing `change <RHS>` between two tactics:

1. Probe the goal at the position with `lean_goal`.
2. Probe `dsimp only` (no args) and `dsimp only [<candidate lemma>]`
   via `lean_multi_attempt` at the same position.
3. If either produces a goal the next tactic can fire on, replace
   `change <RHS>` with the `dsimp only` form. If neither does, the
   `change` is covering for a propositional rewrite (named lemma
   stays) or a refine-binder shape (`change` stays).

---

## 9. Drop `simp`-default rewrites from a multi-step `rw` chain

When a 4+ argument `rw [a, b, c, d]` chain encodes a single
mathematical step and two or more of its rewrites sit in `simp`'s
default set, drop those from the hint list and reach for `simp
[<non-default-hints>]`. The shape is "fuse the chain into one tactic
by letting `simp` apply its default rewrites for free, only naming
the hypothesis equations and `←`-direction rewrites that aren't
already simp-tagged".

### Pattern

```lean
-- `map_add` + `map_smul` + `add_sub_cancel` are in simp's default set.
-- Old:
have heach : ∀ i, f (ε • Pi.single i 1 + z i) = y := by
  intro i
  rw [map_add, map_smul, hfz i, add_sub_cancel]
-- New: only the `hfz i` hypothesis equation is named.
have heach : ∀ i, f (ε • Pi.single i 1 + z i) = y := by
  intro i
  simp [hfz i]
```

The same fusion applies when the chain mixes hypothesis equations
with `@[simp]`-tagged algebra lemmas (`inner_neg_left`, `map_add`,
`map_smul`, `add_sub_cancel`, `ContinuousLinearMap.coe_coe`,
`Finset.sum_empty`, …) or `rfl`-shape coercion-bridge lemmas that
simp normalises automatically (`Subtype.coe_eta`, etc.): keep the
hypothesis equations and `←`-direction rewrites in the hint list,
drop the rest.

Distinct from the *recognise-the-mathlib-fused-lemma* shape (§ 2
*Mirror-first rule* — when mathlib ships a lemma that bundles the
whole chain, e.g. `inv_smul_smul₀` or `Finset.sum_erase`, one named
lemma replaces it outright). The small-hint-list shape applies when
no fused lemma exists but `simp` already covers the mechanical
rewrites.

### Diagnostic procedure

1. Probe `simp [<full hint list>]` and `simp [<non-default subset>]`
   at the position via `lean_multi_attempt`.
2. If `simp` with the non-default subset closes (or produces a goal
   the next tactic can fire on), drop the simp-default rewrites from
   the hint list.
3. If `simp [<full hint list>]` lints any of the rewrites as
   "unused", that's the unblocking signal: simp already handles them
   via the default set — drop them.

### When the named `rw` chain stays

- **`rw` ordering is load-bearing.** When the chain's order matters
  (one rewrite must land *before* another substitutes the variable
  it mentions), `simp`'s normalisation order may not reproduce it.
  Pin the order with `rw [<load-bearing>]; simp` instead (the dual
  pattern: `simp` handles the default-set tail after the
  named-rewrites lead).
- **The chain mentions a `set`-bound name on the LHS.** `simp` may
  not unfold the `set`-bound name unless it's in the hint list; add
  the name to the simp arg list, or pre-unfold with `dsimp only`
  first (§ 8).
- **The non-default subset has only one rewrite and the chain is
  short.** `rw [h₁]` is already minimal; don't fuse for its own
  sake.

---

## 10. Collapsing indicator sums — `← Finset.mul_sum` before `Finset.sum_ite_eq'`

`Finset.sum_ite_eq'` (and `Finset.sum_ite_eq`) collapses `∑ x, if x = a
then f x else 0` to `f a`, but **only fires when the `if` is the whole
summand** — `simp [Finset.sum_ite_eq']` silently no-ops on
`∑ x, c * (if x = a then 1 else 0) * g x` because a constant factor `c`
(or a trailing `g x`) sits outside the indicator. The fix is to first
factor the constant out with `← Finset.mul_sum`, then normalize each
summand to `if x = a then (1 * g x) else 0` via `ite_mul` / `one_mul` /
`zero_mul` (and `mul_ite` / `mul_one` / `mul_zero` for a leading
factor), at which point `Finset.sum_ite_eq'` collapses it.

Concretely (expanding a signed-indicator row
`∑ x, b * (ite_v − ite_u) * m x` to `b * (m v − m u)`):

```lean
simp only [mul_assoc, ← Finset.mul_sum, mul_sub, sub_mul, ite_mul, one_mul,
  zero_mul, Finset.sum_sub_distrib, Finset.sum_ite_eq', Finset.mem_univ, if_true]
```

The diagnostic that you've hit this: a `simp only [Finset.sum_ite_eq',
…]` whose `Finset.sum_ite_eq'` argument the linter then flags as
*unused* — the indicator never reached the collapsible shape. Reach for
`← Finset.mul_sum` (constant factor) or restructure the summand before
re-adding it.

---

## 11. Strong induction on a derived measure (`induction hN : m G using Nat.strong_induction_on`)

To induct on a *derived* `ℕ` measure `m G` of an object `G` (a vertex
count, an edge count, a rank, …) rather than a structural argument,
the idiom is

```lean
intro G
induction hN : m G using Nat.strong_induction_on generalizing G with
| _ N IH =>
  intro hG₁ hG₂   -- the hypotheses you didn't pre-`intro`
  …
```

Two things to know:

- **`generalizing G` is mandatory** — otherwise the IH is fixed to
  the *current* `G` and is useless. The motive then quantifies over
  every object of the measure's value, and the IH reads
  `IH : ∀ k < N, ∀ G, m G = k → <hyps> → <goal>`.
- **The IH carries the measure-equation `m G' = k` as an explicit
  argument**, threaded *first*, before the object's own hypotheses.
  So a recursive call on a smaller `G'` is
  `IH _ hlt G' rfl hG'₁ hG'₂` (the `rfl` discharges `m G' = m G'`),
  and the strict-decrease proof `hlt : m G' < N` uses `hN ▸ (the
  measure-drop lemma)` to rewrite `N` back to `m G`. **Do not
  `subst hN`** — `hN : m G = N` binds the abstract `N` the goal and
  `IH` are stated against; substituting it re-expresses the goal in
  `m G` and desyncs from `IH`'s `< N`. Keep `hN` and `rw [hN]` /
  `hN ▸` locally where you need the concrete count.

---

## 12. Iterating `+1` around a cyclic `Fin m` (`Fin.ofNat`-based ℕ-induction)

To turn a *consecutive* equality `∀ i : Fin m, f i = f (i + 1)` (the
`+1` being cyclic `Fin m` addition) into a *global* one
`∀ i, f i = f 0` — the "constant around a cycle" step — three obvious
moves fail and one works:

- `(j : Fin m)` for `j : ℕ` does **not** coerce: the parser reads it as
  a type ascription, so you get *"Type mismatch: j has type ℕ but is
  expected to have type Fin m"* (and `(↑j : Fin m)` / `Nat.cast` trip
  *"failed to synthesize NatCast (Fin m)"* — the `NatCast` instance
  wants the literal `n+1` shape, not `Fin m` under `[NeZero m]`).
- `Fin.induction` is for `Fin (n+1)` with the **non-wrapping**
  `Fin.succ : Fin n → Fin (n+1)`, a different operation from cyclic
  `+1`.

The idiom:

```lean
have hofNat : ∀ p : ℕ, Fin.ofNat m p + 1 = Fin.ofNat m (p + 1) := fun p => by
  apply Fin.ext; simp [Fin.add_def, Nat.add_mod]
have hnat : ∀ j : ℕ, f (Fin.ofNat m j) = f 0 := by
  intro j
  induction j with
  | zero => rw [Fin.ofNat_zero]
  | succ p ih => rw [← hofNat, ← hstep, ih]
have := hnat i.val
rwa [Fin.ofNat_val_eq_self] at this   -- Fin.ofNat m ↑i = i
```

`Fin.ofNat m : ℕ → Fin m` is the canonical (`[NeZero m]`) cyclic map;
`Fin.ofNat_zero`, `Fin.ofNat_val_eq_self`, and the one-line `hofNat`
successor fact (`Fin.ext` + `simp [Fin.add_def, Nat.add_mod]`, since
both sides are `(p+1) % m`) are all you need. The cyclic index type
`Fin m` *is* the cycle — no walk/connectivity primitive is required
to chain the per-step equalities.

---

## 13. State a ℕ count `a − b + c` as `a + c − b` (subtraction last)

When the conclusion of a lemma is a natural-number count of the form
`a − b + c` (a residual after adding `c` and removing `b`), write it
with the **subtraction last**: `a + c − b`. The two are equal in ℝ /
ℤ but **not** in ℕ, where `−` truncates at `0`: at a boundary where
`b > a` (so `a − b = 0`), `(a − b) + c` reads `c` while the intended
value `a + c − b` is smaller. The failure shows up as the *statement*
being off-by-one at an extreme case — and then `omega` can't prove
it, because it's genuinely false in ℕ as written. Rule of thumb: do
the additions first so the single truncating `−` lands on a
provably-large-enough quantity (with `b ≤ a + c` available, `omega`
closes the rearrangement against the un-truncated facts).

---

## 14. LI family of `finrank`-many vectors spans `⊤`

To prove `Submodule.span R (Set.range v) = ⊤` from a
`LinearIndependent R v` whose index `ι` has
`Fintype.card ι = Module.finrank R V`, route through
`basisOfLinearIndependentOfCardEqFinrank h hcard : Basis ι R V` (the
LI family, having exactly `finrank`-many members, *is* a basis) and
`Basis.span_eq`. Two gotchas: the basis needs `[Nonempty ι]` (supply
it inline, e.g. `⟨⟨(0,1), by decide⟩⟩` for a subtype index), and
`Basis.span_eq` produces `span (range ⇑(basisOf…)) = ⊤`, whose
coercion is only *defeq* to `v` — finish by rewriting
`coe_basisOfLinearIndependentOfCardEqFinrank` to turn `⇑(basisOf…)`
back into `v` before the goal matches.

When the LI family is **subtype-valued** (`v : ι → ↥S` for a
submodule `S`) but the LI you have is on the coercion
(`fun i => (v i : M)`), lift the independence across the inclusion
with `(LinearMap.linearIndependent_iff S.subtype
(Submodule.ker_subtype _)).1` — the `subtype ∘ v`-vs-`v` composite
is defeq, so no `simp` glue is needed.

---

## 15. `(∑ i, f i).comp g` — go pointwise, there is no distributing simp lemma

A `LinearMap` identity with a `∘ₗ` (or `.comp`) sitting *outside* a
`Finset.sum` in the **left** argument —
`(∑ i, c i • f i).comp g = ∑ i, c i • (f i).comp g` — does **not**
fall to `simp [LinearMap.smul_comp, …]`: there is no
`LinearMap.sum_comp`, and `map_sum` won't fire because `· ∘ₗ g`
isn't recognized as the hom being mapped over the `∑`. Don't hunt
for the distribution lemma.

**Pattern.** Drop to pointwise evaluation:
`LinearMap.ext fun x => ?_`, pull the hypothesis to `x` with
`have hx := LinearMap.congr_fun h x`, then `simpa only
[LinearMap.add_apply, LinearMap.comp_apply, LinearMap.sum_apply,
LinearMap.smul_apply, <per-term collapse at x>,
LinearMap.zero_apply] using hx`. The `sum_apply` pushes the `∑`
inside, and each summand's `.comp` collapses by a named per-term
lemma evaluated at `x` (supply it as `have e : ∀ j, … = … := fun j
=> LinearMap.congr_fun (per_term_lemma …) x` if `simp` can't
synthesize the endpoint side conditions).
