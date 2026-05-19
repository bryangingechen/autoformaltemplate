# blueprint/CLAUDE.md — agent operating manual for the blueprint

This file is the **agent-facing operating manual** for working on the
blueprint (the LaTeX/plastex doc under `blueprint/src/`). It is the
blueprint analogue of the top-level `CLAUDE.md`; the project uses a
four-way split:

- `../CLAUDE.md` (root, always loaded) — project-wide process: reading
  order, hand-off contract, citations, project history.
- `../{{PROJECT_NAME}}/CLAUDE.md` — Lean source ops: build/lint
  gates, friction review, MCP tool guidance, quirks index.
- `../notes/CLAUDE.md` — phase-notes and friction-log discipline.
- This file — blueprint TeX ops: authoring conventions, static checks
  (including `checkdecls`), local builds (`inv bp` / `inv web`),
  dep-graph spot-check, forward-mode mechanics.

Read this file when a session involves writing or revising blueprint
TeX — typically when a new phase lands and needs a chapter, or when an
existing chapter falls out of sync with the Lean.

For **workflow-mode discussion** (backfill vs forward, when to use
which), see `blueprint/DESIGN.md`. This file carries operational
rules; `DESIGN.md` carries the rationale.

## Reading order

At session start, in order:

1. **This file** — process and authoring conventions.
2. **`blueprint/DESIGN.md`** — workflow modes and selectivity
   rationale. Skim once per project; re-read when the workflow mode
   for a phase is under discussion.
3. **`../ROADMAP.md`** — what's done, what's mid-stream, which phase
   the new chapter (if any) corresponds to.
4. **`../notes/PhaseN.md`** for the chapter being written — gives the
   lemma checklist, definitions, decisions made during the phase.
5. **The Lean files themselves** for the relevant phase (skim doc-
   comments, file headers, and main lemma statements). Doc-comments
   often already contain the prose proof or rationale, ready to be
   adapted.
6. **Existing chapters** under `src/chapter/` — match their style.

## Authoring conventions (carleson-style)

The blueprint follows the convention used by
[fpvandoorn/carleson](https://github.com/fpvandoorn/carleson/blob/master/blueprint/src/)
and other leanblueprint projects. Key rules:

### Annotation order inside each environment

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

#### Sorry-blocked statements

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

### Label prefixes

Use semantic prefixes consistently:
- `def:` for definitions
- `lem:` for lemmas
- `thm:` for theorems
- `cor:` for corollaries
- `prop:` for propositions
- `sec:` for sections

This makes `\Cref{}` output read naturally
("Definition 1.2", "Lemma 3.4") thanks to `cleveref`.

### Cross-references

Use `\cref{...}` / `\Cref{...}` (cleveref), never bare `\ref`. Both
`print.tex` and `web.tex` load cleveref with `capitalize`, so
`\Cref{lem:foo}` produces "Lemma 1.2" with the right capitalization.

### Citations

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

### What to include vs. skip

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
    upstream-eligible facts. They belong upstream, not in the
    blueprint.
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

### Proof verbosity

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

**Be honest about formalization cost.** Don't formalize Lean-tactic
noise into the prose — the math should read as math. But once the
Lean-simplification attempts above are exhausted, don't elide the
residual *substantive* formalization cost either: if a one-line math
step still expands to a named infrastructure lemma or a non-obvious
construction in Lean, note that briefly so the prose is a faithful
map of the formal proof, not a polished version that pretends Lean
was easy. Use judgment:

- *Omit*: `omega` / `grind` automating arithmetic the prose already
  shows; `simp` collapses; type-class elaboration; mathlib-level
  glue that's invisible to the math.
- *Note*: hand-rolled `Equiv`s for type-level "canonical" moves; a
  named project-internal helper standing in for what the prose treats
  as a one-step correspondence; case-splits the Lean had to take that
  the math wouldn't.

## Static checks before commit

These are the **always-on per-commit gates** for any commit that
touches a `\lean{...}` pointer, a `\label{...}`, a `\uses{...}` /
`\cref{...}` reference, or a `\cite{...}` key. They catch the
failure modes that the plastex build would catch later, but faster,
and run in seconds. Don't carry them as a separate cleanup-round
task — `CLEANUP.md` §A is for divergence audits, not for re-running
gates that should already have been green on each commit.

**All `\lean{...}` names resolve to real Lean declarations.** The
authoritative check is `checkdecls`, which loads every project import
and looks up each name in the Lean environment. It must run against a
freshly-regenerated `blueprint/lean_decls` (produced by `inv web` from
the current `\lean{...}` set; the file is gitignored).

The bundled command — and the one to use by default — is:

```sh
blueprint/verify.sh        # runs inv bp, inv web, lake exe checkdecls
```

The script handles the cd/PATH/venv plumbing (computes the repo root
from its own location, falls back to `/Library/TeX/texbin` only if
`xelatex` isn't already on `PATH`), so it works from any cwd. Its
final step is `lake exe checkdecls blueprint/lean_decls`; that step
**prints nothing on success** — silence after the `==> lake exe
checkdecls …` banner is the green signal, not a missing output.
Non-zero exit + diagnostic on failure (the failing `\lean{...}` name
is named in the output).

The longhand, for when the script can't apply (a half-broken venv,
manual debug iteration, etc.):

```sh
( cd blueprint && source .venv/bin/activate && inv bp && inv web )
lake exe checkdecls blueprint/lean_decls   # exit 0, no output, = all names resolve
```

CI runs the same `checkdecls` command (via `docgen-action`) after
`leanblueprint web` regenerates `lean_decls`; a missing-declaration
failure is a hard merge blocker. The most common cause is forgetting
an enclosing `namespace Foo` in the `\lean{...}` pointer — e.g.
declarations inside `namespace Bar` need `Foo.Bar.IsP.foo`, not
`Foo.IsP.foo`.

**All `\uses{...}` and `\Cref{...}` labels are defined:**

```sh
grep -hoE '\\label\{[^}]+\}' chapter/*.tex | sed 's/\\label{//;s/}$//' \
  | sort > /tmp/labels.txt
grep -hoE '\\uses\{[^}]+\}' chapter/*.tex | sed 's/\\uses{//;s/}$//' \
  | tr ',' '\n' | sed 's/^ *//;s/ *$//' | sort -u > /tmp/uses.txt
comm -23 /tmp/uses.txt /tmp/labels.txt   # should be empty
```

Same idea for `\Cref{...}` / `\cref{...}`. Any output from `comm -23`
is a broken reference.

**All `\cite{...}` keys resolve, and every bib entry is used:**

```sh
grep -hoE '\\cite\{[^}]+\}' chapter/*.tex \
  | sed 's/\\cite{//;s/}$//' | tr ',' '\n' | sed 's/^ *//;s/ *$//' \
  | sort -u > /tmp/cite-keys.txt
grep -hoE '^@[a-z]+\{[^,]+' bibliography.bib | sed 's/^@[a-z]*{//' \
  | sort -u > /tmp/bib-keys.txt
comm -23 /tmp/cite-keys.txt /tmp/bib-keys.txt  # cites without entries
comm -13 /tmp/cite-keys.txt /tmp/bib-keys.txt  # entries never cited
```

Both `comm` outputs should be empty.

## Local build

The blueprint builds in two formats:
- **Web** (HTML + dep-graph) via plastex — primary; what CI deploys.
- **Print** (PDF) via xelatex — secondary.

One-time setup (Homebrew + `tlmgr` packages + a Python venv with
`pygraphviz`'s Apple-Silicon-specific install flags) lives in
`SETUP-AND-PITFALLS.md`. Run those once per machine; agents are not
expected to re-read them on every session.

### Running builds

From `blueprint/`, with the venv activated. Make sure TeX is on `PATH`
in the current shell. `which xelatex` should print
`/Library/TeX/texbin/xelatex`; if not, run

```sh
export PATH="/Library/TeX/texbin:$PATH"
```

This is the reliable fix. **Don't rely on
`eval "$(/usr/libexec/path_helper)"`** as the only PATH update —
agent-tool Bash invocations (and some non-login shells) do not pick up
`/etc/paths.d/TeX` from path_helper, so `xelatex` stays missing even
after running it. The explicit `export PATH=…` is unconditional.

Every Bash tool call from Claude Code spawns a fresh shell, so `PATH`
does not persist across calls. Prepend the export to the same compound
command as `inv bp` / `inv web` (e.g.,
`export PATH=… && cd blueprint && source .venv/bin/activate && inv bp`),
not as a separate call.

```sh
inv bp         # latexmk drives xelatex → blueprint/print/print.pdf,
               # and copies print.bbl to src/web.bbl for plastex.
inv web        # plastex → blueprint/web/index.html + dep_graph_document.html.
               # Reads src/web.bbl produced by inv bp; if you run inv
               # web standalone with no web.bbl, every \cite{} silently
               # renders as a broken-reference fallback.
inv serve      # preview the web build at http://localhost:8000
```

Run `inv bp` before `inv web` — the order matters for citations. CI's
`leanblueprint pdf` / `leanblueprint web` flow is the same, in the
same order.

When all you want is the per-commit gate (bp + web + checkdecls,
quietly), run `blueprint/verify.sh` from any cwd — see *Static checks
before commit* above. The standalone `inv` targets above remain the
right tool for iterative debugging.

After `inv web`, **open `blueprint/web/dep_graph_document.html`** in a
browser. This is the unique value-add over plain LaTeX: every node
should be green (formalized) for completed phases, with edges showing
the `\uses{}` dependencies. A missing or red node is the signal
something's off — a typo in `\lean{...}`, a missing `\leanok`, or a
broken `\uses{...}`.

### CI

CI runs the same builds via `leanprover-community/docgen-action` —
see `.github/workflows/push.yml` (master push, deploys) and
`push_pr.yml` (PRs, no deploy). The blueprint job runs alongside the
Lean build and the upstreaming dashboard; a TeX or `\lean{...}` error
fails the whole pipeline.

## File layout

```
blueprint/
├── CLAUDE.md            ← this file (operating manual)
├── DESIGN.md            ← workflow-mode rationale
├── SETUP-AND-PITFALLS.md ← one-time setup + symptom-indexed pitfalls
├── .gitignore           ← build artefacts + .venv/
├── requirements.txt     ← plastex / leanblueprint / invoke pins
├── tasks.py             ← invoke targets: web / bp / serve
├── verify.sh            ← bundled bp + web + checkdecls gate
└── src/
    ├── web.tex          ← entry for plastex (HTML + dep-graph)
    ├── print.tex        ← entry for xelatex (PDF)
    ├── bibliography.bib ← project references
    ├── extra_styles.css ← web-only style overrides
    ├── plastex.cfg      ← plastex configuration
    ├── latexmkrc        ← latexmk configuration
    ├── preamble/
    │   ├── common.tex   ← macros and theorem envs shared by both
    │   ├── print.tex    ← print-only packages and overrides
    │   └── web.tex      ← web-only packages and overrides
    └── chapter/
        ├── main.tex     ← top-level `\input{}` orchestration
        └── intro.tex    ← project introduction (phase plan, reading
                            guide, hyperlinks to live docs)
```

### Adding a new chapter

1. Create `src/chapter/phaseName.tex`.
2. Add an `\input{chapter/phaseName.tex}` line to `chapter/main.tex`.
3. Re-run `inv web` and check the dep-graph — the new chapter's
   nodes should connect cleanly to earlier chapters' nodes.

In **backfill mode**, each entry carries `\lean{...}` and `\leanok`
from the start and the new chapter's dep-graph nodes should be all
green when committed.

In **forward mode** (see `blueprint/DESIGN.md`), the same recipe
applies, but:
- Omit `\lean{...}` and `\leanok` in each entry — they get added
  as Lean lemmas land in subsequent sessions.
- Prose proofs can be one-line gestures at this stage; flesh out
  during the phase-end pass.
- `\uses{...}` chains should still reflect the intended proof
  dependency structure — they're the point of forward mode.
- The dep-graph will be mostly red on first build; that's the
  to-do list.

### Extending an existing chapter (later phase adds to an earlier file)

When a later phase adds infrastructure to a file whose chapter
already exists, the new entries land in the **same commit** as the
phase backfill that introduces them, and they are **interleaved
topically** into the existing chapter rather than appended at the
end. The reader navigating the chapter should see entries in the
natural mathematical order, not in the order phases happened to land
them. Phase-history information belongs in commit messages, not in
chapter structure.

A more aggressive variant is **restating existing entries in
place**: when a phase reshapes the return type or signature of an
already-blueprinted definition or algorithm, the node-level edits
land alongside the matching Lean per-layer commit, not as a phase
backfill at the end. The affected chapter spends a few commits with
selected nodes red until their Lean catches up; this is forward-mode
discipline applied to an existing chapter rather than a new one.

### Macros

Live in `preamble/common.tex`. The starting set is intentionally
minimal (`\N`, `\Z`, `\Q`, `\R`). When a chapter wants a recurring
piece of notation, add a macro there rather than inline-redefining
per chapter.

## Pitfalls

Build-time pitfalls (plastex warnings vs errors, the silent
`inv web`-without-`inv bp` citation-break trap, `_` in
`\texttt{...}`, math in section titles, Python 3.9 quirks, etc.)
live in `SETUP-AND-PITFALLS.md`. Skim that file when a build behaves
unexpectedly.

## Friction review (mandatory at end of session)

Same idea as the top-level `CLAUDE.md`'s friction review, narrowed to
the blueprint. The bar and destination depend on the workflow mode
(see `DESIGN.md` for the modes themselves):

- **Backfill mode** — friction is mostly TeX-level (macro behaviour,
  `\texttt{}` quoting, plastex warnings). Capture it in **this file**
  under "Pitfalls" or "Local build"; it doesn't cross-cut the rest
  of the project.
- **Forward mode** — friction can be structurally meaningful (the
  dep-graph encodes the proof plan). Cross-cutting items belong in
  `../notes/FRICTION.md` tagged `[blueprint]`.

Concrete questions, in either mode:

1. **Did any TeX construct fight you?** Macro that didn't behave as
   expected, an `\input{}` boundary that broke a numbering scheme, a
   plastex/leanblueprint quirk. Almost always: update this CLAUDE.md
   under Pitfalls.
2. **Did the dep-graph reveal a structural gap?** A `\uses{}` chain
   that's longer than the math actually needs, an orphan node, a
   cycle, a node that should really be split. Backfill: fix in this
   commit. Forward: fix or file a note — the dep-graph IS the plan,
   so an unexamined gap is technical debt.
3. **Did selection feel arbitrary?** If you spent time deciding
   whether a given Lean lemma deserves a blueprint entry, write the
   criterion you ended up using as a one-line note in this file
   under "Authoring conventions → What to include vs. skip". The
   next agent shouldn't relitigate the same call.

No new entries this session is fine — but only after you've checked.
