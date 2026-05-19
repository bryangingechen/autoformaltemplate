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

## Choices to revisit

Decisions made under uncertainty that should be revisited if the
underlying assumption changes. Each entry names the choice, the
condition that would trigger reconsideration, and the alternative.

<!-- Example entry (delete when populating):

- **Predicates as `def` not `abbrev`.** Decision: keep
  `IsSparse` / `IsTight` / etc. as non-reducible `def`s. Trigger
  for reconsideration: if 5+ proof sites end up with explicit
  `refine ⟨?_, ?_⟩` boilerplate solely to expose the def's
  structure, the cost-benefit shifts toward `abbrev`. Alternative:
  convert to `abbrev` and accept reducibility in matching/elaboration.

-->

TODO: populate as decisions accumulate.
