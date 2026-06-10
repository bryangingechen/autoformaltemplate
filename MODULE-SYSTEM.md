# MODULE-SYSTEM.md — Lean module-system conversion reference

This file is the **operational reference** for converting a project
Lean file to Lean's module system (`module` + `public import` +
`@[expose] public section`), or for fixing a file that drifted out
of the pattern. It is read **on demand** — when converting a file
or debugging a `module`-related build failure — not as session-start
orientation.

For session-start Lean-side discipline (build/lint gates, friction
review, MCP guidance), see `{{PROJECT_NAME}}/CLAUDE.md`. For
build-failure rescue on `module`-related errors specifically, see
`TACTICS-QUIRKS.md` § 15 (*`#eval`-bearing `module` files need
`public meta import`*), symptom-indexed in the *Symptom index* at
the top of `TACTICS-QUIRKS.md`.

## Why

Project files use Lean's module system (`module` + `public import`
+ `@[expose] public section`) for the same reason mathlib does:
downstream files only see the public interface of an imported
module, not its full elaboration state. The mechanic is uniform
across all files and matches the upstream reference
`Mathlib/Analysis/InnerProductSpace/PiL2.lean`.

## Conversion procedure

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

## Constraints and gotchas

- **A `module` file can only `import` other `module` files.** If
  you add a new project-internal import, the imported file must
  already be `module`-converted. (Build error: *"cannot import
  non-`module` X from `module`"*.)
- **Recent mathlib is ~98 % `module`-converted**, so almost
  every `Mathlib.X` import already satisfies the constraint. The
  remaining files are deep upstream pieces most projects don't
  depend on. If the project depends on a non-mathlib Lake package
  whose files are still non-`module`, any project file importing
  one of them must itself stay non-`module` — the exception is
  contained, since non-`module` files import `module` files freely.
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
