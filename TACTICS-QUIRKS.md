# Tactics — rescue / build-failure recovery

This file is the project's **rescue reference**: when a `lake build`
fails with an unfamiliar Lean error, look here before iterating. Each
section is indexed by symptom (the error message or proof shape
you'd see), with the fix and a worked case study.

For **golfing / improvement** patterns (turning a verbose proof into
an idiomatic one), see `TACTICS-GOLF.md` instead — read at cleanup
time, not first-draft.

> **Friction vs. idiom.** Cross-cutting rules — "if you see pattern
> X, prefer Y" — live here. One-shot frictions (a specific lemma we
> needed and mirrored) live in `notes/FRICTION.md`.

## Symptom index (skim this first)

When a `lake build` fails with an unfamiliar Lean error, scan these
bullets. If one matches, jump to the named section below for the fix.

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
  notation, or *"Invalid field `foo`"* on `x.foo` while `T.foo x`
  type-checks in the same file → § 7 *Dot notation only consults
  the type's head namespace*
- `simp_all` produces a confusing residual with a hypothesis you
  expected to eliminate → § 8 *`simp_all` cross-contaminates*
- `set V₊ := …` / `let V₊ := …` / `let h̄ := …` / `let h⁰ := …` (or
  any identifier with `₊ ₋ ₌`, a combining-mark like macron `̄` or
  tilde `̃`, or a math-class superscript like `⁰`) errors with
  *"expected token"* at the non-ASCII column → § 9 *Subscript `₊`
  (U+208A) is not a valid identifier character*
- *"MVar does not look like a recursive call: ... → V → Fintype V"*
  on a WF-recursive def whose `termination_by` uses `Finset.univ`,
  or *"Unknown identifier `visited`"* from `termination_by` after a
  `| visited, v => ...` pattern-match body, or `unused variable`
  lint on an `if h : ...` binder used only inside `decreasing_by` →
  § 10 *`termination_by` / `decreasing_by` elaboration rescue*
- *"Application type mismatch: heq has type X = some ⟨…⟩ but is
  expected to have type some ⟨…⟩ = some ⟨…⟩"* inside the `some`
  branch of a `match heq : <expr> with | …` term → § 11 *`match h :
  <expr> with` substitutes `expr ↦ pat` in the goal of each branch*
- *"Tactic `rewrite` failed: motive is not type correct"* when
  `rw [h]` uses `h : D.field = …` and the goal contains a local
  whose *type* references `D.field` → § 12 *`rw [h]` over a
  structure field whose value appears in another local's type*
- *"Application type mismatch"* on the first hypothesis used inside
  a `case caseN D h₁ ... =>` after `induction _ using funName.induct`,
  or *"Did not find an occurrence of the pattern"* on a `rw [hyp] at
  h` whose LHS visibly appears in `h` → § 13 *`induction … using
  funName.induct` on a function with `let` in its body*
- `ring` reports *"unsolved goals"* on a sum-of-sums identity
  `Σ + B = B + Σ'` where `Σ` and `Σ'` are alpha-equivalent
  `Finset.sum`s (same Finset and body, different bound-variable
  name) → § 14 *`ring` fails on alpha-renamed `Finset.sum`s*
- *"Invalid `meta` definition `_eval`, `instFoo` is not accessible
  here; consider adding `public meta import X`"* on a `#eval
  (decide P)` in a `module` file → § 15 *`#eval`-bearing `module`
  files need `public meta import`*
- *"unknown tactic"* on a bare `ring` / `linarith` / `nlinarith` /
  `positivity`, or *"Unknown constant `Finset.mul_sum`"* /
  *"Unknown constant `Finset.sum_comm`"* on a `simp only` / `rw`
  step, or *"Invalid field `det`: The environment does not contain
  `Function.det`"* on `(M : Matrix n n ℝ).det` despite
  seemingly-sufficient imports → § 16 *Mathlib basic-files don't
  transitively pull tactic / big-operator-algebra /
  matrix-determinant modules* (see the need → import table there)
- *"invalid -D parameter, unknown configuration option
  'linter.style.header'"* (or any lakefile-set `linter.*` / `pp.*`
  option reported unknown) on a file that previously built → § 17
  *a `/-! … -/` module docstring placed above the `import` block
  truncates the header*
- *"Function expected"* / *"Application type mismatch"* when a
  standalone `have` restates a subterm that type-checks fine in the
  goal → § 18 *Restating a subterm in a standalone `have` can fail*
- *"Type mismatch … has type `A ↔ ?` but is expected to have type
  `A' ↔ …`"* on `refine h.trans ?_` where `A'` is only defeq to
  `A`, or *"Did not find an occurrence"* on `rw [map_eq_zero_iff …]`
  over a defeq-abbrev codomain → § 19 *`Iff.trans` requires a
  syntactic side-match, not just defeq*
- *"motive is not type correct"* / `._proof_N` debris in the goal
  after `rw [someDef]` where `someDef` is a mathlib op built via
  `.copy` → § 20 *use the `@[simps!]` lemmas, never `rw` the `def`*
- `rw [if_pos rfl]` reports *"Did not find an occurrence"* on a
  goal shaped `(fun i ↦ if i = j then …) j` → § 21 *use
  `simp only [↓reduceIte]`*
- *"typeclass instance problem is stuck … `(i : α) → Module ?m
  (?φ i)`"* on a difference of `LinearMap.proj`s over a Pi type →
  § 22 *type-ascribe the first summand to the full `LinearMap`
  type*
- *"the first type argument to `HSMul` is a metavariable"* at a
  `t • _` under an unannotated `∀ t, …` binder → § 23 *ascribe the
  binder's type*
- `ext x` on an equation of duals of an exterior-power submodule
  binds a generating-vector tuple, not a point of the carrier →
  § 24 *apply `LinearMap.ext` explicitly*
- *"motive is not type correct"* on `rw [hsub]` where the rewritten
  `Submodule` sits under `finrank R ↥(…)` → § 25 *flip the equation
  and rewrite the hypothesis instead*
- `rw [map_sum]` reports *"Did not find an occurrence"* on
  `b.repr (∑ …)`, or forcing it fails to synthesize
  `AddMonoidHomClass` / times out → § 26 *route the coordinate
  through `Finsupp.lapply t ∘ₗ repr.toLinearMap`*
- `rw [← Cardinal.le_def]` reports *"Did not find an occurrence"*
  on a `Nonempty (α ↪ β)` goal where `α` and `β` live in different
  universes → § 27 *use `Cardinal.lift_mk_le'`*
- *"(deterministic) timeout at `whnf`"* / *"maximum number of
  heartbeats"* while unfolding a basis/dual-coordinate iso over a
  heavy carrier in place, or while the elaborator infers a
  heavy-carrier implicit argument → § 28 *extract a generic helper
  over an abstract basis; pass heavy arguments explicitly*
- the same `whnf`/`isDefEq` timeout on a rank-nullity step
  (`finrank_range_add_finrank_ker`, `quotKerEquivRange`) over a
  `Submodule` or quotient of a heavy carrier → § 29 *run
  rank-nullity on the plain Pi map*
- *"failed to synthesize `Module.IsTorsionFree …`"* (or any
  "obvious" algebraic instance) in a narrow-import file when a
  full-mathlib scratch succeeds → § 30 *add the instance's defining
  import*
- `rw [← f.sum_repr y]` (or any `rw` of a function-valued equation)
  unexpectedly rewrites `y i` applications elsewhere in the goal →
  § 31 *scope with `conv_lhs` / `conv_rhs` / `nth_rewrite`*

---

## 1. `omega`/`grind` treat `set`-aliased terms as opaque atoms

When a proof opens `set name := expr with name_def` and later
receives a hypothesis mentioning `expr` literally (typically from a
downstream lemma call), the two views are defeq but `omega`/`grind`
see them as distinct atoms and won't bridge across.

**Fix:** one explicit `rw [← name_def] at h_expr_form` (or
`rw [name_def] at h_alias_form`) before invoking the tactic.

The `set` tactic's substitution scope is bounded by *current*
goals/hypotheses, not future tactic outputs — this is intrinsic, not
a bug. Same pattern bites `grind`.

---

## 2. `omega` doesn't carry commutativity or distributivity on atoms

If `omega` has `k * #s` on one side and `#s * k` on the other (or
`k * #(s ∪ t) + k * #(s ∩ t)` vs. `k * #s + k * #t`), it sees four
unrelated atoms and fails.

**Fix:** pre-normalize.

- For commutativity: `rw [mul_comm]` so the form `omega` sees matches
  the goal.
- For distributivity: stage a `have h_mul : … := by rw [← Nat.mul_add,
  ← Nat.mul_add, Finset.card_union_add_card_inter]` and hand the
  multiplied identity to `omega` alongside the unmultiplied facts.

One-liner alternative: `linear_combination k * h.symm`, but this
requires `Mathlib.Tactic.LinearCombination` to be in scope.

---

## 3. `subst` between two free variables picks the wrong one

When `h : a = b` has both sides free in scope, `subst h` eliminates
one — and Lean's heuristic is "the *less-recently-introduced* free
variable when both qualify." Two recurring traps:

- `rcases Sym2.eq_iff.mp h_eq with ⟨rfl, rfl⟩ | ⟨rfl, rfl⟩` inside
  an `induction e with | h u v => …` after a `by_cases h_eq : s(u, v)
  = s(a, b)`: the `rfl` patterns substitute *the theorem binders
  `a, b`* (older) rather than the case-split intros `u, v` (newer).
  A follow-up `have hflip : p b - p a = …` then fails with `Unknown
  identifier b`.
- `by_cases hvc : v = c; · subst hvc`: substitutes `c` (the function
  signature variable, older) and leaves `v`. Subsequent uses of `c`
  fail.

**Fix:** bind the equalities to named hypotheses and use `rw`, which
doesn't eliminate from the context:

```lean
rcases h_pair_eq with ⟨h1, h2⟩ | ⟨h1, h2⟩
· rw [h1, h2]; …
· rw [h1, h2, /- sign flip -/]; …
```

When `grind` is the closer it papers over this — both branches close
regardless of which variables remain. Reach for named hypotheses
only when downstream tactics depend on a specific name.

---

## 4. `simp only` leaves residual subterms that block `rw` motives

If you `simp only […]` and then a follow-up `rw [h]` fails with
*motive is not type correct*, citing a hypothesis (like `he`) that
doesn't appear in the displayed goal — suspect a `simp`-produced
residual subterm hiding inside an `Eq` proof.

**Fix:** insert `change <displayed clean form>` between the
`simp only` and the `rw`:

```lean
simp only [foo_apply, Pi.zero_apply, Function.comp_apply]
change ⟪p u - p v, x u - x v⟫_ℝ = 0
rw [h1, h2]; …
```

The `change` re-elaborates the goal at the surface type, discarding
the residual.

---

## 5. `set name := fun t => …` + `simp [name]` doesn't unfold lambdas

`simp [name]` on a `set`-introduced abbreviation whose body is a
lambda often fails (or worse, gives a `⊢ sorry () c = …`-style
elaboration glitch).

**Fix:** prefer `let` plus explicit `have`-lemmas that state the
reductions you need:

```lean
let p_t : ℝ → MyType := fun t => Function.update p₀ c (p₀ c + t • w)
have h_p_t_c : ∀ t, p_t t c = p₀ c + t • w :=
  fun _ => Function.update_self c _ p₀
have h_p_t_ne : ∀ t v, v ≠ c → p_t t v = p₀ v :=
  fun _ v hvc => Function.update_of_ne hvc _ p₀
```

Reference the `have`-lemmas in downstream reasoning rather than
trying to round-trip through `simp [p_t]`.

---

## 6. `interval_cases` is for free variables, not function applications

`interval_cases (Fintype.card V)` enumerates the cases but does
**not** substitute `Fintype.card V` in the context — so an arm's
`Fintype.card V = 2` won't close by `rfl`. `interval_cases` only
performs `subst` on free *variables*.

**Fix:** for value equations on function applications, derive the
equation as a named hypothesis via `omega` (or `decide`, etc.) and
hand it to downstream lemmas explicitly:

```lean
by_cases hV3 : 3 ≤ Fintype.card V
· -- high branch
· -- low branch
  have hcard2 : Fintype.card V = 2 := by
    have := h.some_cardinality_bound
    omega
  exact h.consequence_of_card_eq_two hcard2
```

---

## 7. Dot notation only consults the type's head namespace

Three related traps:

- **Sub-namespace lookup fails.** Inside `namespace Foo.Bar`,
  with `h : G.IsP`, writing `h.some_lemma` looks up
  `Foo.IsP.some_lemma`, **not**
  `Foo.Bar.IsP.some_lemma`. Error appears as ``And.some_lemma not
  found`` because Lean unfolds `IsP → … → And` while searching.
  Fix: call by explicit name from inside the sub-namespace —
  `IsP.some_lemma h …` resolves correctly via the partial-prefix
  lookup.
- **Same-name wrapper recurses.** Inside `theorem
  Foo.mono`, writing `hI.mono h` resolves `.mono` to *the function
  being defined* (Lean prefers the head namespace of the term's
  *stated* type before unfolding), not the upstream `Bar.mono`
  you intended. Spell out the upstream name explicitly when
  wrapping a same-named upstream lemma.
- **File-local re-namespace breaks projection.** A lemma written
  `theorem T.foo …` while the file sits inside an enclosing
  namespace (`namespace MyProject.Area`) lands at the full name
  `MyProject.Area.T.foo`. A later `x.foo` on `x : T` then fails
  with *"Invalid field `foo`: the environment does not contain
  `T.foo`"* — even though `T.foo` *resolves as an identifier* (the
  enclosing namespace is open). Dot/projection notation does
  **not** use the open-namespace search: it looks for `foo` in the
  *structure head's own root namespace*, and the file-local
  `…Area.T.foo` is a different namespace. Fix: either call it by
  the (partially-qualified) identifier `T.foo x` instead of the
  projection, or define the lemma inside an explicit `namespace T
  … end T` block so it really lands in the root `T` namespace.
  Cheap tell: `x.foo` errors but `T.foo x` type-checks in the same
  file.

---

## 8. `simp_all` can cross-contaminate with destructive equality hypotheses

If `simp_all` encounters `hij : 0 = X`, it may rewrite *every*
occurrence of `0` in the context to `X` — including inside
hypotheses you wanted to keep. When `simp_all` produces a confusing
residual goal involving a hypothesis you expected to eliminate,
suspect cross-rewriting. Route through a derived quantity that
doesn't trigger it:

```lean
have h_norm : ‖p i‖ = ‖p j‖ := congrArg _ hij
revert h_norm <;> simp [hp_def]
```

---

## 9. Subscript `₊` (U+208A) is not a valid identifier character

Pasting an identifier like `V₊` or `s₊` from blueprint / notes prose
into Lean produces a baffling `expected token` error at the column
of the subscript-plus, and the parser then dumps the local context
with the partial name as `V : ?m.… := sorry`. Lean's identifier
rules (per Unicode XID_Continue) accept letters and digit-like
subscripts (`₁ ₂ ₃ … ₀`) but classify `₊` (U+208A "subscript plus
sign") as a math symbol, not a letter — it cannot continue an
identifier. Same for `₋` (U+208B), `₌` (U+208C), `₍ ₎`.

The same XID_Continue rule rejects other math-symbol-class Unicode
that's easy to paste from prose and looks like it should work:

- **Superscript digits other than the identifier-eligible subset.**
  Some compose-class superscripts (e.g. `⁰` U+2070) are classified
  as numeric symbols rather than letters / continue-class digits, so
  `h⁰` and similar bindings error the same way. Use `h0` instead.
- **Combining marks like macron `̄` (U+0304) and tilde `̃` (U+0303).**
  `h̄` is *not* a single codepoint — it's `h` + combining macron, and
  the combining mark is not a continue character. `hbar`, `htilde`,
  etc. work; the prose / blueprint can continue to render `\bar h`.

Replace with an alphanumeric suffix (`V_pos`, `Vpos`, `Vp`, `hbar`,
`h0`) when binding via `set` / `let` / `intro`. Blueprint / prose can
keep the original `₊` / superscript / combining-mark notation; only
the Lean identifier needs to change. Friction signal: any time the
parser dumps the local context with a partial name and `expected
token` at the column of a non-ASCII glyph that "looks like" a letter
or digit, the Unicode XID_Continue classification is the first
suspect.

---

## 10. `termination_by` / `decreasing_by` elaboration rescue

Defining a well-founded recursive function with a non-trivial
termination measure trips three closely-related elaboration quirks.
All three are cheap to apply prophylactically.

**a. Typeclasses used only in the termination measure must be bound
explicitly on the def, not via `variable`.** A `variable [Fintype V]`
auto-binds typeclasses by usage order — if the function body only
needs `[DecidableEq V]` but the `termination_by (Finset.univ \
visited).card` clause uses `[Fintype V]`, Lean inserts `[Fintype V]`
at the *end* of the auto-bound signature (after the explicit args).
The recursive-call recognizer then sees a function whose trailing
implicit doesn't match the call site, producing the cryptic
*"MVar does not look like a recursive call: ... → V → Fintype V"*
(with `Fintype V` shown as a trailing argument it can't unify).
Pinning the typeclasses explicitly on the def — `def f [Fintype V]
[DecidableEq V] (...) : ...` — fixes the order and the error.

**b. `termination_by` doesn't see pattern-match binders from
`| pattern => body` style.** Writing the body with
`def f : ∀ (visited : Finset V) (v : V), ... | visited, v => …` and
then `termination_by (Finset.univ \ visited).card` errors with
*"Unknown identifier `visited`"* — the `visited` in the pattern is
local to the match, not visible to the trailing clauses. Restructure
to named def params: `def f (visited : Finset V) (v : V) : ... :=
body`; `visited` is then in scope for `termination_by` /
`decreasing_by`.

**c. Hypotheses bound by `if h : ...` and used only in `decreasing_by`
still trigger `unused variable` lint.** Lean's WF tactic block runs
in a context that includes the path conditions to the recursive
call — `if hv : v ∈ visited then none else …` makes `hv : ¬ v ∈
visited` available inside `decreasing_by` to discharge the sdiff
strict-monotonicity proof. But the linter doesn't recognize WF-block
usage and warns `unused variable hv`. Rename the binder to `_hv` —
underscore-prefixed names are valid identifiers in Lean (still
referenceable as `_hv` inside `decreasing_by`) and the linter
silences itself.

**Bonus: `mutual` recursion fails structural recursion when a
helper's parameter type depends on the other helper's parameter.**
A `mutual` block whose helpers' children-list parameter is typed
`List {u // u ∈ succ v}` fails structural recursion because the
list's element type depends on the function parameter `v`. Workaround:
collapse into a single function with the children loop inlined via
`List.findSome?` on `(succ v).attach`. Lean's WF tactic can see the
recursive call inside the `findSome?` lambda; the
`(Finset.univ \ visited).card` measure dispatches in one
`decreasing_by` proof.

---

## 11. `match h : <expr> with | pat => …` substitutes `expr ↦ pat` in the goal of each branch

Using term-mode `match h : <expr> with | pat => body` introduces
`h : <expr> = pat` *and* refines the goal of `body` by substituting
`<expr>` with `pat`. The hypothesis `h` carries the un-substituted
direction (`<expr> = pat`); the goal is the substituted form. The
two are not the same expression, even though they hold the same
information.

**Symptom:** *"Application type mismatch: heq has type X = some ⟨w, p⟩
but is expected to have type some ⟨w, p⟩ = some ⟨w, p⟩"* when trying
to use `heq` to discharge a goal that was *itself* about `X` and now
reads as a tautology after the substitution.

**Fix.** Two options depending on what you need:

- If the goal collapsed to `pat = pat`, just return `rfl`:
  ```lean
  match heq : someFunction v with
  | some ⟨w', p'⟩ => exact ⟨w', p', rfl⟩
  | none => …
  ```
- If you need the un-substituted form of `heq` (e.g. to feed it to a
  lemma that wants `X = none`), restructure to a `by_contra` over the
  un-substituted goal and `cases h_eq : <expr> with` inside (tactic
  mode `cases :` preserves both directions):
  ```lean
  by_contra hne
  have hnone : someFunction … = none := by
    cases h_eq : someFunction … with
    | none => rfl
    | some wp => exact absurd h_eq (hne wp.1 wp.2)
  exact absurd … (helper … hnone …)
  ```

---

## 12. `rw [h]` over a structure field whose value appears in another local's type

If a hypothesis `h : D.field = ...` is used with `rw [h]` (or
`conv => rw [h]`) and the goal contains a local `p` whose *type*
mentions `D.field`, the rewrite tries to abstract the type-level
occurrence and fails with *motive is not type correct*.

**Symptom.** *"Tactic `rewrite` failed: motive is not type correct"*
on a goal where `D.field` appears in a Finset / membership form,
plus a `p`-derived term (`p.foo`, `p.bar`) appears elsewhere — and
`p`'s type references `D.field`.

**Fix.** Don't use `rw [h]` to substitute the field. Instead, build
the rewritten *Finset* (or whatever container) equation as a `have`
via `Finset.ext`, then use that equation as a single `rw` unit
whose motive is the trivial container-level one (e.g.
`λ s, s.card`):

```lean
have h_decomp : D.arcs.filter P =
    (D.arcs \ p.arcsFinset).filter P ∪ p.arcsFinset.filter P := by
  ext x; simp only [Finset.mem_filter, Finset.mem_union,
    Finset.mem_sdiff]
  -- ... explicit forward/backward via by_cases on x ∈ p.arcsFinset
rw [h_decomp, Finset.card_union_of_disjoint …]
```

The `ext` block constructs the equation pointwise, never substituting
`D.arcs` anywhere. Once the equation exists, the subsequent `rw`
abstracts only the container, not its underlying field. The same
trick generalises to any container-equality-via-`rw` step that
crosses a local with a value-dependent type.

---

## 13. `induction … using funName.induct` on a function with `let` in its body

The auto-generated `funName.induct` recursor for a function defined
with `termination_by` faithfully mirrors the function's body — which
means a `let x := <expr>` (or `have x := <expr>`) in the body
becomes a `let`/`have` clause in each affected case of the recursor.
Two related traps surface together when using `induction _ using
funName.induct`:

**a. The `let`-bound name consumes a case-binder slot.** When you
write `case caseN D h₁ h₂ ... =>` to name the binders for a case,
each `let x := <expr>;` in the case's hypothesis chain takes a
slot. The displayed signature shows it as `let x := …;` rather than
`∀ x, …`, but it elaborates as a real binder. If you skip its name,
Lean shifts the remaining names by one and produces a confusing
type error on whatever now-misaligned hypothesis you first try to
use.

**Symptom.** *"Application type mismatch: hypothesis `hX` has type
`<wrong type>` but is expected to have type ..."* where the displayed
"wrong type" matches the `let`-bound term (e.g. `V → Bool` when the
let binds `P : V → Bool`).

**Fix.** Include the let-bound name in the case's binder list. For
a case introduced by `let P := …;` followed by `∀ (r : …), …`, write
`case caseN D h₁ h₂ ... P r ... =>` rather than
`case caseN D h₁ h₂ ... r ... =>`. Use `#check @funName.induct` (or
`lean_hover_info` via MCP) to see the exact let / have / ∀ chain in
each case before naming.

**b. The inner `let`-binding shadows the case binder when rewriting.**
After `rw [funName] at h` unfolds the function definition in a
hypothesis, the inner `let x := <expr>;` introduces a fresh local
binding for `x` *inside* `h`, distinct from the case binder of the
same name. A subsequent `rw [hyp] at h` where `hyp`'s LHS references
the case-binder `x` will fail with *"Did not find an occurrence of
the pattern"* because the pattern uses the case-binder `x` while
the occurrence in `h` uses the inner let-bound `x` — they're
different terms even though they print identically.

**Symptom.** `rw [hyp] at h` whose LHS visibly appears in `h`
fails with *"Did not find an occurrence of the pattern"*; the
displayed `h` contains a `let x := …;` clause shadowing your case
binder.

**Fix.** Apply `dsimp only at h` *after* the `rw [funName] …`
unfold to inline the inner `let`, replacing every `x` in `h` with
`<expr>`. The case-binder `x` and the inlined `<expr>` in `h` now
elaborate to the same term, and the subsequent `rw [hyp] at h`
works.

**Bonus: `match c with | ... | none => none` doesn't auto-reduce
when `c` becomes `none`.** After `rw [hu_none, hv_none] at h`
substitutes both discriminees in a nested `match`, `h` ends up as
`(match none with | some r => … | none => match none with | some r
=> … | none => none) = some D'`. `Option.noConfusion h` fails
because the LHS hasn't reduced to a constructor. Discharge with
`exact nomatch h` (or `cases h`, or `simp at h`), all of which
trigger the match reduction as part of pattern-matching the
hypothesis. The fix is one tactic and never the deep-issue, but
worth knowing so you don't reach for `Option.noConfusion` first.

---

## 14. `ring` fails on alpha-renamed `Finset.sum`s — `omega` / `linarith` as atom extractor

A goal shaped `Σ + B = B + Σ'` where `Σ` and `Σ'` are
alpha-equivalent `Finset.sum`s — same Finset, same body modulo a
bound-variable rename — fails to close with `ring`. The atom
extractor checks *syntactic* identity on lambda bodies, not full
defeq, so `∑ x ∈ s, f x` and `∑ y ∈ s, f y` register as distinct
atoms even though they're propositionally equal.

The rescue exploits a property already documented in § 1:
`omega` (over ℕ) and `linarith` (over ordered fields) treat each
`Finset.sum` as an *opaque atomic term*, which means they don't care
whether two surface forms alpha-match — both forms reduce to the
same atom symbol in their internal representation.

**Symptom.** A residual goal like
`∑ x ∈ V' \ {u, v}, f x + (f u + f v) = f u + f v + ∑ w ∈ V' \ {u, v}, f w`
where the LHS / RHS bound variables (`x` vs `w`) don't match,
`ring` reports *"unsolved goals"*, `ring_nf` produces a non-closing
form, and `omega` directly doesn't see the equation (the two sums
are still separate atoms even after `omega` normalisation).

**Fix.** Don't try to make the two sums syntactically equal. Bind
each sum identity (e.g. `Finset.sum_sdiff`, `Finset.sum_pair`) as a
named `have` hypothesis with the bound variable Lean prefers, then
let `omega` / `linarith` close the surrounding linear (in)equality
using the sum-identity `have`s as opaque facts:

```lean
have h_sdiff : ∑ x ∈ V' \ ({u, v} : Finset V), f x +
                 ∑ x ∈ ({u, v} : Finset V), f x =
               ∑ x ∈ V', f x := Finset.sum_sdiff huv_sub
have h_pair : ∑ x ∈ ({u, v} : Finset V), f x = f u + f v :=
  Finset.sum_pair huv
have h_pos : 0 < ∑ w ∈ V' \ ({u, v} : Finset V), f w := by omega
```

The two `have`s name the two pieces; `omega` chains them through
the linear arithmetic without needing the bound variables to align.

If the rescue doesn't fire (e.g. the surrounding identity is
non-linear), the next reach is
`Finset.sum_congr rfl (fun _ _ => rfl)` to rename the bound variable
explicitly before `ring`.

---

## 15. `#eval`-bearing `module` files need `public meta import` for the imported `Decidable` / elaboration instances

`#eval` elaborates its argument at **meta time**, synthesising
`Decidable` / `Repr` / `ToExpr` / etc. instances through the
*meta-time* environment. In a `module` file, a plain
`public import X` exposes `X`'s declarations only to the importing
file's compile-time and runtime layers — not to meta-time
elaboration. Symptom on the first `#eval (decide P)` from a
freshly-converted `module` file:

```
Invalid `meta` definition `_eval`, `instDecidableP` is not accessible
here; consider adding `public meta import X`
```

The compiler error names exactly the module to add as a `public meta
import`. The fix is to keep the existing `public import X` line and
add a second-form `public meta import X` immediately after it. The
two import lines coexist: `public import` covers runtime visibility
(for `def` / `theorem` bodies that reference `X`'s declarations);
`public meta import` covers meta-time visibility (for `#eval` /
`#check` / `#reduce` / `decide`-tactic elaboration that reaches into
`X`'s instance pool).

```
public import {{PROJECT_NAME}}.SomeModule
public meta import {{PROJECT_NAME}}.SomeModule
```

— same module imported twice in different roles. Without the second
line, every `#eval (decide …)` reports the *"not accessible here"*
error pointing at the missing instance.

**Closest mathlib precedent.** `Mathlib/Tactic/Check.lean` and
several other tactic-bearing files in `Mathlib/Tactic/` use `public
meta import` for `Lean.Elab.*` / `Lean.PrettyPrinter.*` (where the
tactic implementation needs Lean elaborator-internals at meta time).

**When this fires vs. doesn't.** The rule is *what kind of
visibility does the consumer need?*

- `def foo := …` using `X`'s declarations in its body → `public
  import X` is sufficient.
- `theorem bar : … := by simp [X.lemma]` → `public import X` is
  sufficient (the `simp` lemma database is populated at compile
  time).
- `#eval P` where `P` reduces through `X`'s instances → needs
  `public meta import X`.
- `example : … := by decide` where `decide` synthesises an instance
  defined in `X` → needs `public meta import X`.

The alternative — dropping `module` for the `#eval`-bearing file —
works (non-`module` files can `import` `module` files freely) but
breaks the project's uniform module convention.

---

## 16. `ring` / `linarith` / `Finset.mul_sum` / `Finset.sum_comm` report *"unknown tactic"* or *"unknown constant"* despite a `Mathlib.Data.Real.Basic` import

Mathlib's trend is to shrink the import surface of foundational
files: `Mathlib.Data.Real.Basic` no longer transitively imports
`Mathlib.Tactic.Ring`, `Mathlib.Algebra.BigOperators.Ring.Finset`,
`Mathlib.Algebra.BigOperators.Group.Finset.Sigma`, etc. This is
independent of the module system — it's just that "I have ℝ in
scope, so `ring` should work" is no longer reliable.

Symptoms, all from the same root cause:

- *"unknown tactic"* at a bare `ring` / `linarith` / `nlinarith` /
  `polyrith` / `positivity` / `field_simp` line.
- *"Unknown constant `Finset.mul_sum`"* on a `simp only [...,
  Finset.mul_sum, ...]` step.
- *"Unknown constant `Finset.sum_comm`"* on a `rw [Finset.sum_comm]`
  step.

**Fix:** add the specific module directly. The relevant pinning:

| Need | Import to add |
|---|---|
| `ring` / `ring_nf` | `Mathlib.Tactic.Ring` |
| `linarith` / `nlinarith` | `Mathlib.Tactic.Linarith` |
| `Finset.mul_sum`, `Finset.sum_mul`, `Fintype.sum_mul_sum` | `Mathlib.Algebra.BigOperators.Ring.Finset` |
| `Finset.sum_comm`, `Finset.sum_sigma` | `Mathlib.Algebra.BigOperators.Group.Finset.Sigma` |
| `Finset.sum_ite_eq`, `Finset.sum_ite_eq'` | `Mathlib.Algebra.BigOperators.Group.Finset.Piecewise` (typically transitively available; named here for completeness) |
| `Matrix.det` (the `.det` projection on a `Matrix n n R`, and lemmas like `Matrix.isUnit_iff_isUnit_det`) | `Mathlib.LinearAlgebra.Matrix.NonsingularInverse` (the *invertibility* + Cramer's-rule lemmas live here; `Mathlib.LinearAlgebra.Matrix.Determinant.Basic` is enough for `Matrix.det` itself). Note that `Mathlib.LinearAlgebra.Matrix.ToLin` does **not** transitively pull this in — `(M : Matrix n n ℝ).det` errors as *"Invalid field `det`: The environment does not contain `Function.det`"* because `Matrix` is a `def` alias for `n → n → ℝ` and the elaborator falls through to the `Function`-head namespace when `Matrix.det` is not in the environment. |

When in doubt, `lean_loogle` on the constant name reports its
defining module under the `module` field of each hit.

**Don't** chase this by importing `Mathlib` (the umbrella file) —
it bloats compile time and obscures the genuine dependencies.

---

## 17. A `/-! … -/` module docstring above the `import` block truncates the header

**Symptom.** `lake build` on a file fails with
*"invalid -D parameter, unknown configuration option
'linter.style.header'"* (or whichever `linter.*` option the
lakefile's `leanOptions` set first) — on a file that built fine
before a documentation-only edit, with no mention of the docstring
in the error.

**Cause.** The Lean parser ends the module *header* at the first
non-`import` command. A `/-! … -/` module docstring is a command
(unlike a plain `/- … -/` block comment, which is whitespace), so
placing it above the imports makes the header empty: the file then
imports nothing, Mathlib's linter framework is absent from the
environment, and the lakefile-injected `-Dlinter.style.header=…`
option is rejected as unknown. The reported error points at the
option, not at the real problem.

**Fix.** Put the docstring *after* the import block (the standard
mathlib layout: copyright `/- … -/` comment, imports, `/-! # … -/`
module docstring). Only plain block comments may precede `import`.

---

## 18. Restating a subterm in a standalone `have` can fail (`Function expected`) where the goal type-checks

When a goal contains a subterm like
`Pi.single (j e) v c x * m x c` (a `Pi.single`-indexed family of
functions, applied at `c` then `x`), restating that **same** subterm
inside a fresh `have`/`suffices` can fail with *"Function expected
at `Pi.single …`"* or *"Application type mismatch"* — even though
the goal itself elaborates fine.

The cause: in the goal, the implicit motive of `Pi.single` (the
family type, e.g. `Fin d → (α → ℝ)`) is **pinned** by the
surrounding lemma that produced the term, whose statement fixed the
family's type. Re-stating the subterm in isolation strips that
context, so the elaborator must re-infer the motive from the literal
expression alone — and picks the wrong one (treating a
function-valued family member as the *value* rather than the
*family member*).

**Fix:** don't restate — operate on the goal in place, where the
motive stays pinned. Use `rw [Finset.sum_congr rfl fun x _ => …]`,
`rw [Finset.sum_eq_single …]`, or `simp only [...]` to transform
the subterm directly. Observed in: collapsing an inner `Pi.single`
sum inside a matrix-row computation — the standalone
`have hinner : ∀ x, ∑ c, Pi.single … = …` failed to elaborate while
the same collapse via `rw [Finset.sum_eq_single …]` on the goal
worked.

---

## 19. `refine h.trans ?_` / `Iff.trans` requires a syntactic side-match, not just defeq

When a helper iff `h : A ↔ B` is meant to bridge a goal `A' ↔ C`
where `A'` is only *definitionally* equal to `A` (not
syntactically), `refine h.trans ?_` fails with a *"Type mismatch …
has type `A ↔ ?` but is expected to have type `A' ↔ …`"*.
`Iff.trans` unifies its first component against the goal's LHS up
to reducible transparency only, so the two must match
*syntactically*; a `def`-unfolding or binder-shape difference
defeats it. Typical offenders:

- a wrapper-vs-base projection that is `rfl` but not syntactically
  equal: `F.IsGood` vs `F.toBase.IsGood`, where the former
  `def`-unfolds to the latter;
- a dependent existential `∃ (_ : p), q` vs a conjunction-style
  `p ∧ q` (both encode "`p` and `q`" but are different `Exists` /
  `And` head symbols).

**Fix:** don't compose with `.trans`. Open the goal iff with
`constructor` and discharge each direction with `exact`, which
closes up to full defeq — or, when one side already matches, `rw`
the matching iff and then `constructor`.

**Same rule for `rw` of a `map_eq_zero_iff`-family lemma when the
codomain is a `def`-wrapper.** `rw [map_eq_zero_iff _ e.injective]`
(or `LinearEquiv.map_eq_zero_iff`) pattern-matches `?f ?x = 0`
*syntactically*; if the equiv's codomain is a defeq abbrev of the
type in the goal, the displayed `(e ⋯) x` elaborated through that
defeq and the `rw` reports *"Did not find an occurrence of the
pattern"*. Apply the lemma as a **term** instead — e.g.
`exact map_ne_zero_iff _ e.injective` after `rw`-ing the goal into
the matching iff shape — since `exact` unifies up to defeq.

---

## 20. `rw` on a mathlib op defined via `.copy` trips the motive — use the `@[simps!]` lemmas

Several mathlib operations are defined as a `.copy` of another
construction so that a field is *definitionally* the intended set —
e.g. `Graph.deleteEdges` is a `.copy` of a `restrict`, pinning the
edge set to `E(G) \ F`. Unfolding such a def with
`rw [deleteEdges]` (or `rw [IsLink, deleteEdges, …]`) exposes the
`.copy` wrapper, and `rewrite` then fails with *"motive is not type
correct"* / *"Did not find an occurrence of the pattern"*, because
the goal now carries the `.copy` proof obligations
(`deleteEdges._proof_2 …`) that abstract badly.

**Fix:** never `rw` the `def` itself. `.copy`-built ops are
typically `@[simps!]`-tagged, so the right tools are the
**generated simp lemmas**, which `simp only` applies cleanly
through the `.copy` — for `deleteEdges`:

- `vertexSet_deleteEdges` — `V(G.deleteEdges F) = V(G)`;
- `deleteEdges_isLink` — `(G.deleteEdges F).IsLink e x y ↔ G.IsLink e x y ∧ e ∉ F`;
- `edgeSet_deleteEdges` — `E(G.deleteEdges F) = E(G) \ F`;
- `deleteEdges_inc`, `deleteEdges_isLoopAt`, …

Whenever an `rw [someDef]` leaves `._proof_N` debris in the goal,
check whether `someDef` is built with `.copy` (or otherwise carries
proof fields) and switch to its `simps` lemmas.

---

## 21. `rw [if_pos rfl]` fails on a `(fun i ↦ if i = j then …) j` goal — use `simp only [↓reduceIte]`

**Symptom.** After `refine ⟨fun i => if i = j then … else …, …⟩` and
a `subst`/`by_cases` landing in the `i = j` branch, the goal still
shows the un-beta-reduced application
`(fun i ↦ if i = j then A else B) j`. `rw [if_pos rfl]` reports
*"Did not find an occurrence of the pattern"* — the `if` is hidden
under an unapplied lambda, so there is no `ite` subterm at the
syntactic surface for `rw` to match.

**Fix.** `simp only [↓reduceIte]` does both the beta-reduction *and*
the `if (j = j)` → `then`-branch reduction in one step (the
`↓reduceIte` simproc fires after `simp`'s built-in beta). Plain
`simp only [if_pos rfl]` also works but flags `if_pos` as an
*unused* simp argument (the simproc did the reduction, not the
lemma) — a `linter.unusedSimpArgs` warning. So reach for the simproc
name `↓reduceIte`, not the lemma. The `else`-branch (`i ≠ j`) is
unaffected: `simp only [if_neg hij]` fires there normally because
the discriminant is a free `hij : ¬ i = j`, no beta-redex in the
way.

---

## 22. `LinearMap.proj i - LinearMap.proj j` over a Pi type leaves the fiber/`R` stuck

**Symptom.** A definition like

```lean
def diffAt (u v : α) : (α → W) →ₗ[ℝ] W := LinearMap.proj u - LinearMap.proj v
```

fails to elaborate with *"typeclass instance problem is stuck, it is
often due to metavariables: `(i : α) → Module ?m (?φ i)`"*, even
though the declared type pins both the domain `α → W` and codomain
`W`. The `-` (over the `LinearMap` module) unifies the two `proj`
summands' types with each other *before* either is unified against
the declared codomain, so the Pi fiber family `?φ` and the scalar
`?R` stay metavariables and the `Module` instance can't be
synthesized.

**Fix.** Type-ascribe the *first* summand to the full `LinearMap`
type; the second then unifies against it:

```lean
def diffAt (u v : α) : (α → W) →ₗ[ℝ] W :=
  (LinearMap.proj u : (α → W) →ₗ[ℝ] W) - LinearMap.proj v
```

`(R := ℝ)` on each `proj` alone is *not* enough — it pins the scalar
but leaves the fiber family `?φ` stuck; the whole-LinearMap
ascription is what fixes `?φ`. The companion `_apply` lemma is then
not `rfl` (in a `module`-mode `public section` the `proj`
subtraction doesn't reduce to the projection form): close it with
`rw [LinearMap.sub_apply, LinearMap.proj_apply, LinearMap.proj_apply]`.

---

## 23. Unascribed `∀ t, … t • x …` binder leaves the `•` scalar type a metavariable

**Symptom.** A statement of the form

```lean
theorem foo … : ∀ t, P = (… (fun i => a i + t • (0 : W)) …) := …
```

fails with *"typeclass instance problem is stuck: `HSMul ?m W W` …
the first type argument to `HSMul` is a metavariable"* at the
`t • …` position. The `∀ t,` binder gives `t` no type annotation,
and nothing else in the body forces it (here `t • (0 : W)` with `W`
fixed pins the *result* type but not the *scalar* type `?m`), so
`t`'s type is undetermined when the `HSMul` instance is sought. The
same trap fires for any `∀ x, … x • _ …` / `∀ x, f x _` where the
binder's type is only weakly constrained by the body.

**Fix.** Ascribe the binder: `∀ t : ℝ, …`. The single annotation
propagates and the `HSMul ℝ W W` instance resolves. (Distinct from
§ 22: there the *fiber/scalar of a `LinearMap` subtraction* was
stuck; here it's the *bound variable's own type* that's free.)

---

## 24. `ext x` on an equation of duals of an exterior-power submodule descends too far

**Symptom.** Proving an equation of `Module.Dual ℝ ↥(⋀[ℝ]^k M)`
functionals — e.g. `∑ i, c i • r i = 0` where each
`r i : Module.Dual ℝ ↥(⋀[ℝ]^k M)` — by `ext x` binds
`x : Fin k → M` (the *generating-vector tuple* of the exterior
power) instead of the intended point of the carrier, and the goal
becomes a `LinearMap.compAlternatingMap … (exteriorPower.ιMulti ℝ k)
x = …` between `AlternatingMap`s. A later `… x` / `congrFun … x`
then errors with *"Application type mismatch: x has type
`Fin k → M` but is expected to have type …"*. Cause: the dual is a
`↥(⋀[ℝ]^k M) →ₗ[ℝ] ℝ`, and the generic `ext` tactic picks the
exterior-power `AlternatingMap` ext lemma (which peels through
`ιMulti` to the tuple of generators) over plain `LinearMap.ext`.

**Fix.** Don't use the `ext` *tactic*; apply `LinearMap.ext`
explicitly so the introduced point has the carrier type:

```lean
have hk : (∑ i, c i • r i : Module.Dual ℝ ↥(⋀[ℝ]^k M)) = 0 :=
  LinearMap.ext fun x => by
    simpa [LinearMap.sum_apply, LinearMap.smul_apply] using hval x
```

Relatedly, apply such a functional equation at a point with
`LinearMap.congr_fun h x` rather than
`congrFun (congrArg DFunLike.coe h) x` — the latter routes the RHS
`0` through the universe-polymorphic `DFunLike.coe` and fails with
*"numerals are data … the expected type is universe polymorphic and
may be a proposition"*.

---

## 25. `rw [hsub]` over a `Submodule` equation under `finrank R ↥(…)` trips the motive — flip the equation and rewrite the *hypothesis*

**Symptom.** A `Submodule`-valued equation `hsub : A = B` and a goal
of the form `… finrank R ↥A … ≤ …`. Rewriting the goal with
`rw [hsub]` fails with *"Tactic `rewrite` failed: motive is not type
correct"*. Cause: the submodule `A` sits under the
`↥`-coercion-to-type inside `Module.finrank R`, so the rewrite
motive `fun S => Module.finrank R ↥S ≤ …` carries a dependent
coercion `↥S` and is not type-correct in general (same family as
§ 12 and § 20 — `rw` motive traps over dependent positions).

**Fix.** When the matching fact lives in a *hypothesis*
`hp : … finrank R ↥B … ≤ …` (a `≤`-Prop, not a position under a
fresh motive), rewrite the hypothesis with the **reversed** equation
and close by `exact`:

```lean
rw […, ← hsub] at hp   -- turns `↥B` in `hp` into `↥A`, matching the goal
exact hp
```

Rewriting `at hp` rather than on the goal sidesteps the motive
type-correctness check (the hypothesis's type is just a `Prop`). The
general rescue axis: *if `rw [eq]` on the goal trips the motive but
the same content is already in a hypothesis, flip `eq` and rewrite
the hypothesis instead.*

---

## 26. `map_sum` won't push `Basis.repr` (a `LinearEquiv` to `Finsupp`) through a `∑` — route through `Finsupp.lapply t ∘ₗ repr.toLinearMap`

**Symptom.** A goal carrying `b.repr (∑ i ∈ s, f i) t` (a single
basis coordinate of a `Finset.sum`), and `rw [map_sum]` (or
`simp only [map_sum]`, or a `conv` focused on the subterm) reports
*"Did not find an occurrence of the pattern `?g (∑ x ∈ ?s, ?f x)`"*
even though `b.repr (∑ …)` is visibly a morphism applied to a sum.
Forcing the morphism explicitly (`rw [map_sum (b.repr)]`) instead
fails with *"failed to synthesize `AddMonoidHomClass (M ≃ₗ[R] (ι →₀
R)) ?m ?m`"* / *(deterministic) timeout at typeclass*. Cause: the
codomain of `Basis.repr` is `Finsupp` (`ι →₀ R`), and the
`AddMonoidHomClass` instance for the bundled `M ≃ₗ[R] (ι →₀ R)`
(needed for `map_sum` to fire) does not synthesize — so `map_sum`
silently won't unify `?g := b.repr`. The same snag blocks the
`.toLinearMap` form `M →ₗ[R] (ι →₀ R)`.

**Fix.** Don't push `repr` through the sum at all. The coordinate
you actually want is the *`R`-valued* linear functional
`Finsupp.lapply t ∘ₗ b.repr.toLinearMap` (codomain `R`, whose
`map_sum` synthesizes fine). When the sum's terms are themselves a
linear image (e.g. `L (c i • bs i)` for a `LinearEquiv` `L`), fold
the outer linear maps into one composite and rewrite the whole
coordinate to that composite by a `show … from rfl`, then `map_sum`
fires:

```lean
rw [show b.repr (L (∑ i, c i • bs i)) t
      = (Finsupp.lapply t ∘ₗ b.repr.toLinearMap ∘ₗ L.toLinearMap)
          (∑ i, c i • bs i) from rfl,
  map_sum]
refine Finset.sum_congr rfl fun i _ => ?_
rw [map_smul, smul_eq_mul, LinearMap.comp_apply, Finsupp.lapply_apply,
  LinearMap.comp_apply]
```

The `show … from rfl` holds because `Finsupp.lapply t (g x) = (g x)
t` definitionally; routing through the scalar-codomain composite is
the whole trick (`Finsupp.lapply` is in
`Mathlib.LinearAlgebra.Finsupp`). General axis: *a `map_sum` /
`map_smul` that silently won't match a `Basis.repr`-of-a-sum is the
`Finsupp`-codomain `AddMonoidHomClass` synthesis failing — compose
with `Finsupp.lapply t` to drop the codomain to the scalar ring
first.*

---

## 27. `Nonempty (α ↪ β)` from a cardinality bound across *different universes* — use `Cardinal.lift_mk_le'`, not `le_def`

**Symptom.** You have `α` finite (or `#α ≤ #β`) and want an
embedding `Nonempty (α ↪ β)`, and reach for
`Cardinal.le_def : #α ≤ #β ↔ Nonempty (α ↪ β)`. The
`rw [← Cardinal.le_def]` fails with *"Did not find an occurrence of
the pattern `Nonempty (Function.Embedding.{?u+1, ?u+1} ?α ?β)`"* —
because `le_def` requires `α β : Type u` in the **same** universe,
but here e.g. `α : Type u_1` and `β : Type` (mathlib hands back
certain index types in `Type 0` — observed with the index of a
transcendence basis).

**Fix.** Use the cross-universe form `Cardinal.lift_mk_le' :
lift.{v} #α ≤ lift.{u} #β ↔ Nonempty (α ↪ β)` (stated for
`{α : Type u} {β : Type v}`). `rw [← Cardinal.lift_mk_le']` then
leaves a goal on lifted cardinals; close it with the `lift`-flavored
cardinal lemmas (`Cardinal.lift_lt_aleph0`,
`Cardinal.aleph0_le_lift`) rather than the un-lifted ones. General
axis: *any cardinal comparison whose two sides live in different
universes needs the `lift_*` companion lemma; the bare form is
same-universe only.*

---

## 28. Unfolding a basis/dual-coordinate iso *in place* over a heavy carrier `whnf`-times-out — extract a generic helper over an abstract basis

**Symptom.** A proof step computes a coordinate or matrix entry of a
linear map through a basis-coordinate iso `φ : W ≃ₗ[R] (Fin n → R)`
built from a *concrete, heavy* `W` (e.g. the dual of a Pi type over
an exterior-power submodule), say
`φ (f.dualMap (φ⁻¹ (Pi.single l 1))) j`. Unfolding `φ`
(`dualBasis_equivFun`, `funCongrLeft_apply`, `dualMap_apply`, …)
*in place* inside a large proof context hits *"(deterministic)
timeout at `whnf`"* or *"at `isDefEq`, maximum number of
heartbeats"* — the elaborator keeps reducing the heavy carrier
type.

**Fix.** Lift the coordinate/matrix-entry computation into a
**standalone (`private`) lemma stated over an abstract
`b : Basis ι R W`** (and `e : Fin n ≃ ι`, `f : W →ₗ[R] W`), with `φ`
written `b.dualBasis.equivFun.trans (LinearEquiv.funCongrLeft R R
e)`. Proven against the *abstract* basis it elaborates in isolation
with no `whnf` on the concrete type; the call site then `rw`s in its
concrete `φ`/`f` and is left with a lightweight goal (e.g.
`b.dualBasis (e l) (f (b (e j)))`, a Kronecker `0`/`1` for a
projection `f`). **The abstract restatement is the rescue, not a
`set_option maxHeartbeats` bump** (which still times out). Note
`Basis.equivFun`/`dualBasis` need `[Finite ι] [DecidableEq ι]` in
the lemma *statement* (`haveI := Fintype.ofFinite ι` in the proof,
else the `unusedFintypeInType` linter fires on a `[Fintype ι]`
binder).

**Call-site variant.** The same timeout fires when an
`exact helper _ …` leaves a **heavy-carrier-typed argument
implicit** and the elaborator must *infer* it by unifying the
helper's conclusion against the goal — solving the metavariable
reduces the heavy term. Fix: pass the heavy-carrier argument as an
**explicit literal** so the match is syntactic, not search. Related
corollary: prefer `fin_cases q` on a subtype directly over
`obtain ⟨⟨i, j⟩, hij⟩ := q` + nested `fin_cases` — the latter leaves
beta-redex artifacts in hypotheses that block `omega`.

**Membership-witness variant.** The same timeout fires when a
membership lemma whose hypothesis mentions a heavy wrapped term
(`F.graph.IsLink …` for a heavy composite `F`) is invoked at a goal
where the elaborator must unify a supplied plain fact (`G.IsLink …`)
against the wrapped form. Fix: don't call the membership lemma —
inline the membership witness as an anonymous constructor inside a
local `have` helper that takes the plain fact as an *explicit
argument* (a supplied witness is defeq-checked cheaply; an inferred
goal is not).

---

## 29. Rank-nullity on a map into/out of a `Submodule`/quotient of a heavy carrier `whnf`-times-out — run it on the *plain Pi* map

**Symptom.** A rank-nullity step
`LinearMap.finrank_range_add_finrank_ker g` (or
`g.quotKerEquivRange`, `Submodule.liftQ`,
`(LinearMap.range g).finrank_le`, a `Submodule.ker g` fed to an
`[AddCommGroup]`-requiring lemma) where `g`'s domain or codomain is
a *`Submodule`* or a *`Submodule.Quotient`* over a heavy carrier
(e.g. a Pi type over an exterior-power submodule) hits
*"(deterministic) timeout at `whnf`/`isDefEq`"* — even at a huge
`maxHeartbeats`. `Submodule` / `Submodule.Quotient` each carry an
`AddCommMonoid` instance *separate* from their `AddCommGroup`;
`LinearMap`/`mkQ` record the `AddCommMonoid`, while the
rank-nullity lemma wants `AddCommGroup.toAddCommMonoid`. The two are
defeq but only via a `whnf` that recursively reduces the heavy
carrier — so the *normally trivial* monoid-vs-group reconciliation
blows up.

**Fix.** Run the rank-nullity on the map whose **domain and codomain
are plain Pi function types** (`α → W`), never a
`Submodule`/quotient. Concretely:

- keep the cut as a *full* map out of the Pi type (don't
  `.comp …subtype`-restrict to a `Submodule` domain):
  `finrank_range_add_finrank_ker` on the Pi domain dodges the
  diamond;
- make the codomain a *single* `Submodule.pi` quotient
  (`(ι → W) ⧸ N`), **not** a pi of fiber quotients `∀ i, W ⧸ p i` —
  the single quotient is one `Submodule.Quotient` instance, light
  enough for `finrank_range_add_finrank_ker`; split it to the
  fiber-quotient product *only* for the finrank count, via
  `Submodule.quotientPi` + `Module.finrank_pi_fintype` (import
  `Mathlib.LinearAlgebra.Quotient.Pi`);
- recover the restricted statement with
  `Submodule.finrank_sup_add_finrank_inf_eq` +
  `(ker ⊔ S).finrank_le` against the full Pi finrank — all on
  `Submodule`s of the *Pi* type, no map-instance reconciliation.

This is the same medicine as § 28 (the heavy carrier must stay out
of the elaborator's `whnf`), here applied to instance-diamond
reconciliation rather than a basis-coordinate unfold. **A
`maxHeartbeats` bump is not the fix — it still times out.**

---

## 30. An "obvious" algebraic instance fails to synthesize in a narrow-import file — add the instance's defining import

**Symptom.** Proving `LinearIndependent K (fun _ : Unit => x)` (or
any subsingleton-indexed family) from `x ≠ 0` via
`LinearIndependent.of_subsingleton (default) hx0` fails in a
narrow-import file with *"failed to synthesize
`Module.IsTorsionFree K M`"* — even though `K` is a `DivisionRing` /
`Field`, where the family obviously is independent. A full-mathlib
scratch (`lean_run_code`, `#eval`) masks the gap: it imports the
instance transitively, so the same `exact` succeeds there and only
fails once dropped into the actual (mirror) file.

**Cause.** `LinearIndependent.of_subsingleton` is stated over
`[IsDomain R] [Module.IsTorsionFree R M]`. For a division-ring
module the instance is `DivisionSemiring.to_moduleIsTorsionFree`,
which lives in `Mathlib.Algebra.Module.Torsion.Field` — **not**
reachable from `Mathlib.LinearAlgebra.LinearIndependent.Basic` +
`Mathlib.LinearAlgebra.Span.Basic` alone.

**Fix.** Add the import that defines the instance (here `public
import Mathlib.Algebra.Module.Torsion.Field`, the smallest carrier).
Alternatives that avoid the import sometimes exist at the cost of a
line (here `LinearIndependent.of_subsingleton' (i) (fun r hr =>
(smul_eq_zero.1 hr).resolve_right hx0)`, the zero-ring-safe variant
needing no torsion-free instance). **General rule:** when a mirror /
narrow-import file fails to synthesize an "obvious" algebraic
instance (`IsTorsionFree`, `NoZeroSMulDivisors`, …) that a
full-mathlib scratch finds, the instance's *defining import* is
missing — add it, don't reach for `set_option`.

---

## 31. `rw [← f.sum_repr y]` (or any `rw [eq]` rewriting a *function* term) hits the function's partial applications too — target the side with `conv`

**Symptom.** Rewriting a function-valued term — e.g.
`rw [← (Pi.basisFun R η).sum_repr y]` to expand `y` in its basis —
unexpectedly blows up the *other* side of the goal: a clean RHS
`∑ i, x i * y i` becomes
`∑ i, x i * (∑ j, repr y j • basisFun j) i`, and the proof no longer
closes. The rewrite was meant to touch only the standalone `y`.

**Cause.** `rw [eq]` rewrites *every* occurrence of `eq`'s LHS as a
*term*, and a bare function name `y : η → R` is a term that also
occurs inside each partial application `y i`. So `← sum_repr y`
matches the `y` in `y i` and rewrites it, not just the standalone
`y` you had in mind.

**Fix.** Scope the rewrite to one side:
`conv_lhs => rw [← (Pi.basisFun R η).sum_repr y]` (or `conv_rhs`,
`nth_rewrite k`). **General rule:** when an `rw` of an equation
whose LHS is a *function-valued* term over-rewrites, the unintended
hits are its partial applications elsewhere in the goal — narrow
with `conv_lhs`/`conv_rhs`/`nth_rewrite` rather than re-stating the
lemma.
