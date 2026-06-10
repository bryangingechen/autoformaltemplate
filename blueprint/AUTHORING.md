# blueprint/AUTHORING.md — blueprint authoring conventions (carleson-style)

This file is the **read-on-demand reference** for blueprint prose
authoring: how to annotate `\begin{lemma}` environments, what label
prefixes / cross-reference macros / citation keys to use, what to
include vs. skip from the Lean, how mirror-module appendices work,
and how verbose prose proofs should be.

It is **not** auto-loaded. Read it when:

- Writing a new blueprint chapter (or appendix) for a phase that's
  landing forward Lean work.
- Adding a new entry (definition, lemma, theorem) into an existing
  chapter.
- Updating an existing entry — flipping `\leanok`, adjusting
  `\lean{...}`, restating against a refactored signature.
- Opening a new mirror-module appendix per *Blueprint appendices
  for mirror modules* below.
- Settling a "does this lemma deserve a blueprint entry?" question
  per *What to include vs. skip*.

For the auto-loaded operating manual covering static checks
(`checkdecls`, `\uses{}` reachability, `\cite{}` resolution, the
honesty and supersession gates), local build (`inv bp`, `inv web`,
`verify.sh`), the file layout, and the mandatory end-of-session
friction review, see `blueprint/CLAUDE.md`. For workflow modes
(backfill vs forward) and selectivity rationale, see
`blueprint/DESIGN.md`.

The conventions follow
[fpvandoorn/carleson](https://github.com/fpvandoorn/carleson/blob/master/blueprint/src/)
and other leanblueprint projects.

## Annotation order inside each environment

```latex
\begin{lemma}[Short descriptive title]
  \label{lem:my-lemma}
  \lean{Namespace.my_lemma}
  \leanok
  \uses{def:foo, lem:bar}
  Statement of the lemma, in mathematical English.
\end{lemma}
\begin{proof}
  \leanok
  \uses{lem:helper-used-in-proof-only}
  One- to three-sentence mathematical proof, in English.
\end{proof}
```

- `\label{...}` first; everything else cross-references it.
- `\leanok` says "this is formalized in Lean."
- `\lean{Fully.Qualified.Name}` links to the API docs. May contain
  multiple comma-separated names for group lemmas (e.g. corner
  cases).
- `\uses{...}` on the **statement** declares the dependencies of the
  statement; `\uses{...}` on the **proof** declares dependencies of
  the argument. The dep-graph distinguishes them.
- Always write a prose proof alongside `\leanok` — don't degenerate
  to leanok-only stubs. The dep-graph is the formal map; the prose
  is the human map.

### Dep-graph node colors

The two `\leanok` slots above are **not redundant** — each paints a
different part of the dep-graph node, and the canonical green node
needs both:

- The **node border** tracks the *statement*. `\leanok` on the
  theorem/lemma environment → **green border**; omitted → blue/orange
  border.
- The **node background** tracks the *proof*. `\leanok` inside
  `\begin{proof}` → **green background** (dark-green once all ancestors
  are green too); omitted → **blue background**.

The trap: a `\leanok` on the statement *only* gives a green border but
a **blue background** — the node reads as "statement formalized, proof
still to do," even when the Lean proof is complete. This is invisible
to the per-commit gates (`checkdecls` resolves `\lean{...}` names; it
doesn't read node color), so a chapter can ship statement-green /
proof-blue and pass every gate. When a lemma is fully formalized in
Lean, both `\leanok`s land together — match the template above.
(Contrast the all-red, no-`\leanok`-anywhere case below.)

### Sorry-blocked statements

A theorem whose Lean declaration exists but whose body is `sorry`
(typical for forward-mode work, or for downstream phases stated in
an upstream chapter) is encoded as:

```latex
\begin{theorem}[...]
  \label{thm:my-theorem}
  \lean{Namespace.my_theorem}   % the Lean declaration exists
  \uses{...}                    % dep edges to its statement-level deps
  Statement.
\end{theorem}
\begin{proof}
  Sketch of the intended proof, in prose.
\end{proof}
```

i.e. `\lean{...}` is kept (the symbol resolves; the API doc page
exists), but `\leanok` is omitted on **both** the theorem environment
and the proof. The dep-graph then colors the node red. Carleson's
convention is to rely on this absence-of-`\leanok` signal alone; no
`\notready` macro is needed.

The same red-not-green discipline applies to a node whose Lean
declaration is `sorry`-free but **launders a load-bearing hypothesis**
(assumes the hard part rather than proving it or `\uses`-linking a
node that does). That is also a red node, for the same reason — the
obligation is not yet discharged. See `blueprint/CLAUDE.md` *Static
checks before commit → the honesty gate* for the test.

## Label prefixes

Use semantic prefixes consistently:
- `def:` for definitions
- `lem:` for lemmas
- `thm:` for theorems
- `cor:` for corollaries
- `prop:` for propositions
- `sec:` for sections

This makes `\Cref{}` output read naturally
("Definition 1.2", "Lemma 3.4") thanks to `cleveref`.

## Cross-references

Use `\cref{...}` / `\Cref{...}` (cleveref), never bare `\ref`. Both
`print.tex` and `web.tex` load cleveref with `capitalize`, so
`\Cref{lem:foo}` produces "Lemma 1.2" with the right capitalization.

## Citations

The blueprint loads a BibTeX bibliography from `src/bibliography.bib`
in both entry points (`print.tex`, `web.tex`) with the `amsalpha`
style. Cite published work with `\cite{key}`, combining multiple
citations with comma separation: `\cite{tayWhiteley1985,jordan2016}`.

Key convention: `firstAuthorYear` for single-author works
(`laman1970`), camelCased authors for multi-author works
(`tayWhiteley1985`, `graverServatiusServatius1993`).

Top-level `CLAUDE.md → Referencing prior work` has the accuracy bar.
For the blueprint specifically:

- **Before adding a new bib entry**, verify title, authors,
  journal/series, volume, year, and page range against a primary
  source — DOI landing page, publisher metadata, or NASA ADS for
  older journals. Don't copy from second-hand citations without
  cross-checking.
- **Match attribution to who proved it.** When the modern
  presentation matters, name both: *"classical strategy of X--Y
  YEAR, in the modern presentation of Z YEAR §2.2"*.
- **Verify any §N pointers** — §N must exist in the cited work and
  contain what you claim. Drop the section pointer rather than
  guess.

`leanblueprint pdf` (CI) and `inv bp` (local) drive `latexmk`, which
runs `bibtex` and produces `print/print.bbl`. `inv bp` also copies
that file to `src/web.bbl` so the subsequent `inv web` plastex run
renders the bibliography page and resolves in-prose `\cite{}`s. Both
formats use the same `amsalpha` style, so labels like `[TW85]`,
`[Jor16]` are stable across formats.

## What to include vs. skip

**Be selective.** The blueprint is a reader's doc for a human
audience, not a 1:1 mirror of the Lean. A typical Lean file has
many small declarations that don't merit a blueprint entry. The
default presumption is *exclude*; only include declarations that
clear one of the bars below.

- **Include**:
  - Definitions of project-level concepts.
  - Theorems a reader would name out loud.
  - Lemmas with non-trivial mathematical content used at a phase
    boundary or feeding a main theorem.
- **Skip**:
  - Pure tautologies that follow immediately from a definition.
  - Constructors / accessors whose only job is to absorb
    membership or And-projection boilerplate. The fact they prove is
    already legible from the type signature.
  - Mirror lemmas under `{{PROJECT_NAME}}/Mathlib/` — these are
    upstream-eligible facts. They don't belong in the main-line
    chapters alongside project content; the dedicated *appendix
    chapter per mirror module* mechanism in
    *Blueprint appendices for mirror modules* below is where they
    land instead.
  - Small bridge / glue lemmas whose names or statements are likely
    to change as the API stabilizes. These are also the highest-
    churn artefacts, and blueprinting them means re-editing the
    blueprint on every Lean refactor.
- **Group**: closely related corner cases under one `\begin{lemma}`
  with multiple comma-separated names in `\lean{...}`.
- **Phase-N-prep lemmas that live in Phase-M files** still belong
  in the chapter for **file M**, not phase N. The blueprint reader
  cares about the formal landscape, not about which agent-session
  added a given lemma.

Heuristic that captures most of the above: *if the lemma's name or
statement is likely to change as the API stabilizes, that's a sign
it's churn-prone internal infrastructure — skip it.* See
`blueprint/DESIGN.md` for the rationale.

## Blueprint appendices for mirror modules

Mirror lemmas under `{{PROJECT_NAME}}/Mathlib/<exact upstream path>`
are upstream-eligible facts (see `../ROADMAP.md` *Engineering
conventions*), so they are skipped from the main-line chapters per
*What to include vs. skip* above. They are, however, the kind of
infrastructure a reader of the blueprint needs to be able to see
the dep-graph for — they're not project-internal glue. The
convention is therefore **one blueprint appendix chapter per mirror
module**, named `blueprint/src/chapter/appendix-<topic>.tex` and
wired into `chapter/main.tex` under an "Appendices" comment block.

**Trigger.** When a commit lands (or modifies) a mirror module
`{{PROJECT_NAME}}/Mathlib/<path>/<Module>.lean` — whether that
commit is forward work in a phase or a cleanup-round mirror
move — open the matching
`blueprint/src/chapter/appendix-<topic>.tex` in **the same
commit**, with the appendix's `\lean{...}` pins and prose proofs
in place from day one. Don't carry "open appendix later" as a
deferred TODO; the asymmetric cost — one careful commit at the
mirror-landing time vs. an N-task cleanup-round retro-build — is
the whole reason for the rule (one ancestor project paid an
eight-commit cleanup-round retro-build for appendices skipped this
way).

**Conventions for the appendix chapter.**

- **File naming.** `appendix-<topic>.tex` where `<topic>` derives
  from the mirror module's path-tail (e.g. `appendix-bigop.tex`
  for a big-operator mirror module). Group two tightly-coupled
  mirror modules under one appendix when their dep-graph forms a
  single branch.
- **Label prefix.** Lemma / definition labels use the
  `lem:appendix-<topic>-...` / `def:appendix-<topic>-...` prefix
  family — explicit so cross-references from main-line chapters
  are visibly appendix-bound and the dep-graph layer is legible.
- **Wire-in order.** Add an `\input{chapter/appendix-<topic>.tex}`
  line to `chapter/main.tex` under the "Appendices" comment
  block, **in main-text dependency order**, not alphabetical:
  appendices are sorted by the first main-line chapter that
  consumes one of their results, ties broken by position within
  that chapter — the reader meets each appendix in the order the
  main narrative needs it, and the rendered appendix sequence
  retells the main-text story. To compute the slot for a new
  appendix, scan the main chapters in `main.tex` order for the
  first occurrence of any of the new appendix's `\label{}`s (via
  `\uses{}` / `\Cref{}`); each `\input` line carries a trailing
  `% <chapter>` comment recording its first consumer.
  Cross-appendix `\uses{}` edges should stay consistent with this
  order (an appendix should not consume a later appendix's
  results); if a new appendix would invert that, flag it rather
  than silently reordering.
- **Chapter prose preamble.** Open with a short preamble naming
  the consumer site(s) in the main-line chapters and pointing at
  the running mirror-module inventories in `../ROADMAP.md`
  *Engineering conventions* and `../notes/FRICTION.md` `[mirror]`
  entries. Don't duplicate the inventory; point at it.
- **Cross-references at consumer sites.** When a main-line
  chapter's proof consumes an appendix lemma, add the appendix
  label to the proof's `\uses{...}` edge and surface the consumer
  link with a one-sentence cross-reference in the prose. The
  appendix lemma participates in the proof-side `\uses{}`, not
  the statement-side one.
- **`\lean{...}` + `\leanok`** land on both the statement and the
  proof environments from day one, per *Annotation order inside
  each environment* above (mirror lemmas land already-formalized
  in Lean; there is no forward-mode red phase for an appendix
  entry).

When the rule fails in practice — a mirror module landed without
the matching appendix and the next session has to backfill — open
the appendix in the very next commit rather than letting it
accumulate. If a single agent session lands multiple mirror
modules, each gets its own appendix commit; don't batch.

## Proof verbosity

Match the carleson style: one to three sentences, in English, that
gesture at the argument without trying to be exhaustive. A reader who
wants the full proof clicks through to the Lean. Examples:
- Trivial: "Immediate from the definition."
- Short: a one-sentence sketch of the key step.
- Multi-step: ~10 lines for the most detailed proofs in a chapter.

**First make Lean as painless as the math; only then add prose
asides.** When a math step turns out harder to formalize than to
state, the *first* response is to fix the Lean: a better proof
strategy, an upstreamable helper, sharper mathlib tactic /
proof-automation use. Only when those attempts fail do we add a brief
prose aside calling out the residual gap. "The Lean is just verbose"
is a smell, not a fact of life — friction we accept in the blueprint
we also accept in the Lean, and the next phase pays for it.

**Be honest about formalization cost, both ways.** Don't formalize
Lean-tactic noise into the prose — the math should read as math. But
once the Lean-simplification attempts above are exhausted, don't
elide the residual *substantive* formalization cost either: if a
one-line math step still expands to a named infrastructure lemma or a
non-obvious construction in Lean, note that briefly so the prose is a
faithful map of the formal proof, not a polished version that
pretends Lean was easy. Use judgment:

- *Omit* (Lean noise invisible to the math): `omega` / `grind` /
  `simp` closes, type-class elaboration, mathlib-level glue.
- *Note* (a one-line math step that grew real Lean infrastructure):
  a hand-rolled `Equiv` for a "canonical" move, a named helper
  standing in for a one-step correspondence, a case-split the math
  wouldn't take — one clause, so the prose is a faithful map, not a
  polished fiction.
- *Don't over-note* (the basis-free anti-pattern): prose narrating
  *how the formalization models* an object ("basis-free, deferring
  coordinatization", "abstract graded piece rather than a basis") is
  changelog, not math. One clause max, and only when the modelling
  choice is load-bearing for a later node; else cut it (it belongs
  in the Lean doc-comment).

**Document design-decision asides when the formalization route
diverges from the standard reference.** The rules above govern prose
honesty for a *fixed* proof. A distinct rule governs the *choice* of
which proof to formalize: when an entry's route departs from a
natural source (the standard textbook or survey treatment), call out
the deviation in a *Design decision* aside in the chapter or
appendix preamble. Both forms are worth documenting: *"we don't take
the more abstract route because ..."* (skipping a more general lemma
that would imply ours) and *"we don't take the cheaper
consumer-specific shortcut because ..."* (skipping a project-shaped
corollary in favor of the upstream-eligible general API). Pre-empts
the next agent re-litigating the choice and clarifies the
upstream-eligibility framing for future mathlib contribution.

**Optional carve-out: crux nodes earn full exposition.**
Terse-by-default is the rule above; a project may additionally adopt
the deliverable of a fully detailed, self-contained exposition of its
source's hardest arguments. Under that carve-out, a node whose
difficulty is *source-side mathematical* (the source compresses a
genuinely hard argument) earns a full, followable prose proof.
Capture-now / write-later: during the phase, record candidates as
one-line entries in a cross-phase notes ledger; *write* the expanded
exposition at phase-close, once the argument is `sorry`-free. The
carve-out is for mathematical difficulty in the **source's math**,
not the project's formalization setup — a reroute caused by a
project-side mistake does not earn an entry.
