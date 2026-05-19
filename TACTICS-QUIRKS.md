# Tactics — rescue / build-failure recovery

This file is the project's **rescue reference**: when a `lake build`
fails with an unfamiliar Lean error, look here before iterating. Each
section is indexed by symptom (the error message or proof shape
you'd see), with the fix and a worked case study.

For **golfing / improvement** patterns (turning a verbose proof into
an idiomatic one), see `TACTICS-GOLF.md` instead — read at cleanup
time, not first-draft.

> **`{{PROJECT_NAME}}/CLAUDE.md`** carries an inline
> symptom-indexed pointer table at the top — when a build fails,
> that table is the first place to skim. The table's bullets point
> at the sections below for the fix.

> **Friction vs. idiom.** Cross-cutting rules — "if you see pattern
> X, prefer Y" — live here. One-shot frictions (a specific lemma we
> needed and mirrored) live in `notes/FRICTION.md`.

## Sections

1. **`omega`/`grind` treat `set`-aliased terms as opaque atoms**
2. **`omega` doesn't carry commutativity or distributivity** on
   opaque atoms — pre-normalize.
3. **`subst` between two free variables picks the wrong one** —
   use named hyp + `rw`.
4. **`simp only` leaves residual subterms that block `rw` motives** —
   insert `change`.
5. **`set name := fun t => …` + `simp [name]` doesn't unfold lambdas** —
   prefer `let` + explicit `have` lemmas.
6. **`interval_cases` is for free variables, not function applications** —
   derive the equation via `omega` and name it.
7. **Dot notation only consults the type's head namespace** —
   sub-namespace lookup and same-name wrapper traps.
8. **`simp_all` can cross-contaminate with destructive equality
   hypotheses** — route through a derived quantity.
9. **Subscript `₊` (U+208A) is not a valid identifier character** —
   use alphanumeric suffix.
10. **`termination_by` / `decreasing_by` elaboration rescue** —
    explicit typeclass binding on the def, named def params over
    pattern-match binders, `_h`-prefixed `if h :` binders to silence
    the unused-variable lint.
11. **`match h : <expr> with | pat => …` substitutes `expr ↦ pat` in
    the *goal* of each branch** — return `rfl` when the goal collapses
    to `pat = pat`, or restructure to `by_contra` + `cases h_eq : …`.
12. **`rw [h]` over a structure field whose value appears in another
    local's type** — motive failure. Build the rewritten Finset
    equality via `Finset.ext`, then `rw` the equation as a unit.
13. **`induction … using funName.induct` on a function with `let` in
    its body** — name the `let`-bound case-binder; `dsimp only at h`
    after `rw [funName] at h` to inline the inner-let shadow; use
    `nomatch h` (not `Option.noConfusion`) to discharge
    match-with-`none`-discriminee contradictions.
14. **`ring` fails on alpha-renamed `Finset.sum`s — `omega` /
    `linarith` as atom extractor** — bind each sum identity as a
    named `have` and close the surrounding linear (in)equality with
    `omega` / `linarith`; both treat each `Finset.sum` as an opaque
    ℕ / ordered-field atom, sidestepping `ring`'s lambda-body
    syntactic-identity check.
15. **`#eval`-bearing `module` files need `public meta import` for
    the imported `Decidable` / elaboration instances**.

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

Two related traps:

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

Replace with an alphanumeric suffix (`V_pos`, `Vpos`, `Vp`, `S`)
when binding via `set` / `let` / `intro`. Blueprint prose can keep
the `₊` notation; only the Lean identifier needs to change.

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
