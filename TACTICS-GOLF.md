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
   project helpers `@[fun_prop]` so they participate in the search.
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

**Keep `omega` in the back pocket.** For goals that are pure linear
integer arithmetic with no equational reasoning to do (and where you
don't need any lemma hints), `omega` is faster and more readable. Default
to `grind` because most goals mix arithmetic with equational steps, but
`omega` is the right call for purely arithmetic ones.

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
`Continuous.comp` /`continuous_pi` chains. Local `Continuous` hypotheses
in scope are picked up automatically.

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
