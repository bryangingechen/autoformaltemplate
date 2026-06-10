# blueprint/CLAUDE.md — agent operating manual for the blueprint

This file is the **agent-facing operating manual** for working on the
blueprint (the LaTeX/plastex doc under `blueprint/src/`). It is the
blueprint analogue of the top-level `CLAUDE.md`; the project uses a
four-way split:

- `../CLAUDE.md` (root, always loaded) — project-wide process: reading
  order, hand-off contract, citations, project history.
- `../{{PROJECT_NAME}}/CLAUDE.md` — Lean source ops: build/lint
  gates, friction review, MCP tool guidance, file-size triggers.
- `../notes/CLAUDE.md` — phase-notes and friction-log discipline.
- This file — blueprint TeX ops: static checks (including
  `checkdecls` and the honesty / supersession gates), local builds
  (`inv bp` / `inv web`), dep-graph spot-check, forward-mode
  mechanics. Authoring conventions (annotation order, label
  prefixes, cross-references, citations, what to include vs. skip,
  appendices for mirror modules, proof verbosity) live in
  `blueprint/AUTHORING.md` (read-on-demand).

Read this file when a session involves writing or revising blueprint
TeX — typically when a new phase lands and needs a chapter, or when an
existing chapter falls out of sync with the Lean.

For **workflow-mode discussion** (backfill vs forward, when to use
which), see `blueprint/DESIGN.md`. This file carries operational
rules; `DESIGN.md` carries the rationale.

## Reading order

At session start, in order:

1. **This file** — operational rules for the blueprint (static
   checks, local build, file layout, friction review).
2. **`blueprint/AUTHORING.md`** — read-on-demand reference for
   prose authoring conventions (annotation order, label prefixes,
   cross-references, citations, what to include vs. skip,
   appendices for mirror modules, proof verbosity). Consulted when
   writing a new chapter, adding/updating an entry, opening a
   mirror-module appendix, or settling a "does this lemma deserve
   a blueprint entry?" question. Not auto-loaded.
3. **`blueprint/DESIGN.md`** — workflow modes and selectivity
   rationale. Skim once per project; re-read when the workflow mode
   for a phase is under discussion.
4. **`../ROADMAP.md`** — what's done, what's mid-stream, which phase
   the new chapter (if any) corresponds to.
5. **`../notes/PhaseN.md`** for the chapter being written — gives the
   lemma checklist, definitions, decisions made during the phase.
6. **The Lean files themselves** for the relevant phase (skim doc-
   comments, file headers, and main lemma statements). Doc-comments
   often already contain the prose proof or rationale, ready to be
   adapted.
7. **Existing chapters** under `src/chapter/` — match their style.

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

The script handles cd/PATH/venv plumbing and works from any cwd; its
final `checkdecls` step **prints nothing on success** (silence after
the `==> lake exe checkdecls` banner = green; non-zero + the failing
`\lean{...}` name on failure). Longhand when the script can't apply:
`( cd blueprint && source .venv/bin/activate && inv bp && inv web )`
then `lake exe checkdecls blueprint/lean_decls`. CI runs the same
check (`docgen-action`); a missing-declaration failure is a hard
merge blocker. Most common cause: a missing enclosing `namespace` in
the `\lean{...}` pointer (`Foo.Bar.IsP.foo`, not `Foo.IsP.foo`).

**Last-line sentinel for `tail`-friendly monitoring.** Success prints
`blueprint/verify.sh: all gates passed.` as the last line; any failure
prints `blueprint/verify.sh: FAILED at <step> (exit <rc>).` via an
`EXIT` trap. `tail -1 <log>` is enough to tell pass from fail, which
matters because `verify.sh 2>&1 | tail -N` swallows verify.sh's
non-zero exit code by default (bash pipelines return the rightmost
command's exit, so `tail` clobbers the script's status unless the
caller also runs `set -o pipefail`). The sentinel makes that mistake
visible from the output alone.

**The other scriptable gates are bundled in `blueprint/lint.sh`** —
run it (from any cwd; sub-second, no venv/TeX/lake needed) on any
commit touching a `\label` / `\uses` / `\cref` / `\cite` or a
supersession marker. It checks:

- every `\uses{...}` and `\cref`/`\Cref{...}` target has a
  `\label{...}`;
- every `\cite{...}` key has a `bibliography.bib` entry, and every
  bib entry is cited somewhere;
- the supersession gate below.

It prints the offending names and exits non-zero on failure;
`blueprint/lint.sh: all static reference checks passed.` is green.

**No live-route node references a superseded one (the supersession
gate).** When a commit supersedes a route or argument — replaces a
chain of `\uses`'d nodes with a different one — it **owns reconciling
every node on the old route, both statement and proof, in the same
commit**, not merely marking the dead *leaf* and updating the live
node's statement. The failure mode this catches is a *live* node
whose statement says "route X is superseded" while its **proof still
routes through X**: self-inconsistent prose that falls through every
other gate (the honesty gate fires only on `\leanok` additions; the
per-commit re-read checks only what the commit changed, not
downstream red nodes; "superseded" in free prose alone has no
machine-readable status). The discipline:

- **Mark superseded nodes with a greppable, standardized marker.** Put
  the literal word `superseded` in the **environment title** — the
  `[...]` of `\begin{lemma}[...]` (e.g. `[Splice route (superseded):
  …]`). The title is the one line a one-environment-per-block `awk`
  can key on; restating it in the body prose (*"Red, superseded"*) is
  good for the reader but the **title** is what the check below
  greps. Keep the dead node (retain-with-marker) for the audit trail
  rather than deleting it — but make it inert.
- **A node still on a live route may not `\uses` (nor describe its
  live proof through) a superseded node.** Reroute its `\uses` edges
  and its prose onto the replacement in the *same* commit. A `\cref{}`
  *pointer* to a superseded node in an explicit audit-trail aside
  ("the earlier dead-ends, off the live route, are …") is fine; a
  `\uses` dependency edge or a live-proof step is not.
- **superseded-`\uses`-superseded is fine** — that is the internally
  consistent audit trail. The gate flags only a *non-superseded* node
  reaching into a superseded one.

The scriptable form is `blueprint/lint.sh`'s third check (two `awk`
passes feeding a `comm`: enumerate labels whose environment title
contains `superseded` — the `\label{}` on the line after `\begin` is
the project's invariant — then assert no non-superseded node's
`\uses` targets one). Any hit is a live node depending on a struck
one — reconcile it before commit. (Calibration, one ancestor
project: a live node's statement said "route superseded" while its
proof still routed through the dead chain — rot that survived for
phases because it lived in *red* nodes invisible to the
`\leanok`-gated honesty gate.)

**Every hypothesis of a `\leanok` node is discharged (the honesty
gate).** The checks above are name/label *resolution* checks — they
are blind to hypothesis *content*, and `checkdecls` happily passes a
`\lean{...}` declaration carrying any number of smuggled hypotheses
as long as the name exists. This gate is the semantic companion, and
it is the one a human must run by eye on any commit that **adds a
`\leanok`** (it is not scriptable, because "load-bearing vs ambient"
is a judgement call). The rule:

> A node may carry `\leanok` only if **every non-ambient hypothesis**
> of its `\lean{...}` declaration is either (a) discharged inside the
> Lean proof body, or (b) the *conclusion* of a node it `\uses{...}`.
> A load-bearing hypothesis that is neither — a dangling assumption
> with no node representing the obligation to prove it — means the
> node is **dishonestly green**. Keep it red (drop `\leanok`, keep
> `\lean{...}`) until the hypothesis is discharged or given its own
> tracked node.

"Ambient" = the lemma's genuine input data and typeclass/finiteness
assumptions (`[Fintype V]`, "Let $G$ be a graph with property P",
the input placement). "Load-bearing" = a hypothesis that *is* a
mathematical claim the lemma would otherwise have to prove. The
legitimate **green-modulo-X** pattern is exactly case (b): a node is
honestly green when its hypothesis *is* the conclusion of a `\uses`'d
node that stays red until discharged. The failure mode is case (b)
*claimed* but not *true* — a `\uses` edge that doesn't actually
conclude the hypothesis.

**Producer / existence lemmas get extra scrutiny.** A node whose
statement promises to *produce* something (`∃ p, …`, "attains full
rank") but whose Lean *assumes* the very object or bound it
claims to produce is the textbook smell — the deliverable smuggled in
as a hypothesis. (Calibration, one ancestor project: a realization
lemma shipped green while assuming the very placement it was named to
construct; the fix was to drop `\leanok`, keep the proven composition
carrier, and add a red node for the construction.) The between-phases
re-run of this gate is `CLEANUP.md` §A — but this is a *per-commit*
gate, run at the moment `\leanok` is added, not a debt deferred to a
cleanup round.

The gate has a *second half* — constructibility — and it is the one
that bites producers: even with every hypothesis honest, the intended
**proof step may not follow** or the **target count the construction
can't reach**. Before a producer node is scheduled as a *build*,
trace its target quantity (rank/count/dimension) through the
construction and confirm the **arithmetic closes** — not just that
`\uses` edges type-check; math-first when the math is the hard part.
(Calibration: a one-line `+(D−1)` vs `+D` shortfall once sat
undetected under four re-plans.) The recon discipline for this lives in
`../DESIGN.md` *Constructibility recon before scheduling a producer
build*.

The gate has a *third half* — structural fidelity. The second half
confirms the **arithmetic** closes; this one confirms the **shape**
does. When a `\leanok` (or to-be-built) node formalizes a step of a
published proof, its **composition lemma must reproduce the source's
argument *structure***, not just its conclusion and count. A
locally-sound modelling choice can re-express the source's argument
as a *different* one with a different — possibly intractable —
obligation. **The tell:** the counts line up but you keep needing
fresh hypotheses to bridge a gap the source doesn't have.
**Corollary:** a node that is *green with its hard half deferred as a
red sibling* must have that red sibling's feasibility **re-verified
before downstream nodes build on the green half** —
"green-with-a-red-sibling" ≠ "green". See `../DESIGN.md` *Match the
source's argument structure, not just its conclusion* for the
project-side rule.

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
browser. This is the unique value-add over plain LaTeX: for completed
phases every node should be **green-background** (proof formalized) —
ideally dark-green (proof + all ancestors formalized) — with edges
showing the `\uses{}` dependencies.

Read the node coloring at two levels (see `AUTHORING.md` *Dep-graph
node colors*): the **border** tracks the statement, the **background**
tracks the proof. So scan for two failure modes, not one:

- A **red** node = no `\leanok` anywhere (statement not formalized);
  the usual cause is a typo in `\lean{...}` or a broken `\uses{...}`.
- A **blue-background** node = statement `\leanok` present (green
  border) but the **proof** `\leanok` is missing inside
  `\begin{proof}`. The per-commit gates won't catch this — they check
  `\lean{}` resolution, not node color — so a completed-phase chapter
  full of blue-background nodes is a real divergence, not "done." Add
  the proof-level `\leanok` per the `AUTHORING.md` template.

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
├── AUTHORING.md         ← authoring conventions (read-on-demand)
├── DESIGN.md            ← workflow-mode rationale
├── SETUP-AND-PITFALLS.md ← one-time setup + symptom-indexed pitfalls
├── .gitignore           ← build artefacts + .venv/
├── requirements.txt     ← plastex / leanblueprint / invoke pins
├── tasks.py             ← invoke targets: web / bp / serve
├── verify.sh            ← bundled bp + web + checkdecls gate
├── lint.sh              ← fast static reference checks (labels,
│                           cites, supersession gate)
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
        └── intro.tex    ← reader's introduction: scope, phase plan,
                            reading guide, hyperlinks to live docs.
                            A fixed-size orientation, NOT a status
                            log — keep it jargon-free (../CLAUDE.md
                            *Sync the user-facing status surfaces*).
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

**Keep reshape/phase history out of the prose.** Per-layer scheduling
("was `some D'`", "Layer 4b") and Lean-internal plumbing (`Quot.out`,
agreement witnesses) are changelog — a restated node must read as if
its *current* shape were always the shape; state any
computable/`noncomputable` split in one sentence and click through
for the rest.

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
   criterion you ended up using as a one-line note in
   `blueprint/AUTHORING.md` under *What to include vs. skip*. The
   next agent shouldn't relitigate the same call.

No new entries this session is fine — but only after you've checked.
