# blueprint/SETUP-AND-PITFALLS.md — one-time setup and build pitfalls

This file is the **reference companion** to `blueprint/CLAUDE.md`. It
holds two kinds of material extracted from the operating manual to
keep the manual scannable:

- *One-time setup* — what to install once per machine to run the
  blueprint build locally. After the initial setup these instructions
  are not needed again.
- *Pitfalls* — symptom-indexed rescue reference for build-time
  problems (plastex warnings, citation breaks, `inv bp` /
  `inv web` quirks). Used only when something breaks.

Not on the per-session reading order. Skim the section that matches
your symptom; agents are not expected to load this file
unconditionally.

## One-time setup

System dependencies (macOS, Apple Silicon assumed):

```sh
brew install graphviz                    # for pygraphviz
brew install --cask basictex             # for xelatex (~80 MB)
export PATH="/Library/TeX/texbin:$PATH"  # add TeX to PATH this shell
sudo tlmgr update --self
sudo tlmgr install latexmk preview xkeyval \
  enumitem tikz-cd thmtools cleveref     # required by print.tex (inv bp)
```

Python venv (kept under `blueprint/.venv`, gitignored):

```sh
cd blueprint
python3 -m venv .venv
source .venv/bin/activate

# pygraphviz needs the brew-installed graphviz headers; pip won't
# find them on Apple Silicon without explicit flags:
CPPFLAGS="-I$(brew --prefix graphviz)/include" \
LDFLAGS="-L$(brew --prefix graphviz)/lib" \
  pip install pygraphviz

pip install -r requirements.txt          # plastex, leanblueprint, invoke
```

## Pitfalls

- **plastex emits warnings, not errors, on unknown commands.**
  `\github`, `\dochome`, etc. produce warnings when run outside a
  build that loads the blueprint plastex plugin. These are harmless
  in normal `inv web` runs but can mask real warnings — skim the
  console output, not just the exit code.
- **`inv web` exits 0 even when every citation is broken.** If
  `src/web.bbl` is missing (e.g. you ran `inv web` standalone), the
  output contains `WARNING: Could not find any file named: web.bbl`
  and one `WARNING: Bibliography item "..." has no entry` per
  `\cite{}` — but exit code is 0 and every `\cite{}` silently renders
  as a broken-reference fallback. `grep -i 'bibliography item' web
  output` to catch this; the fix is to run `inv bp` first.
- **`_` in `\texttt{...}`.** LaTeX still treats `_` as a subscript
  inside `\texttt{...}`. Escape as `\_` (e.g.
  `\texttt{my\_function}`) or use `\verb|...|`.
- **`\lean{Name1, Name2}` with multiple names** is fine for the
  HTML build (each links separately) but produces only one link
  target in the PDF. Reserve multi-name `\lean{}` for closely-
  related corner cases the reader genuinely thinks of as a unit.
- **Math in section / subsection titles breaks `inv bp` (xelatex).**
  hyperref errors with *"Improper alphabetic constant"* and
  Emergency-stops the run when a section title contains raw
  `$math$` (e.g. `\ell`, `\Leftarrow`). Wrap with
  `\texorpdfstring{$math$}{ASCII fallback}` — the existing
  convention. Sample: `\section{The \texorpdfstring{$(k, \ell)$}{(k,
  l)}-count matroid}`. Symptom: a failed `inv bp` cascades to
  unresolved cross-refs and missing bibliography entries on the
  *next* `inv web` (because `print.bbl` never got generated and
  copied to `src/web.bbl`); fix the section title and re-run `inv
  bp` then `inv web`.
- **No `.md` interference.** plastex parses only what `web.tex`
  `\input{}`s. xelatex parses only what `print.tex` `\input{}`s.
  Adding `.md` files anywhere under `blueprint/` is safe.
- **Python 3.9 quirks.** Recent `leanblueprint` releases sometimes
  require 3.10+. If you hit `SyntaxError` or `ImportError` after a
  `pip install -r requirements.txt`, the fix is usually
  `python3.12 -m venv .venv` and reinstall.
- **`RecursionError` from `plastexdepgraph.ancestors` during `inv web`.**
  Symptom: `inv web` errors mid-run with
  `RecursionError: maximum recursion depth exceeded` in
  `plastexdepgraph/Packages/depgraph.py` line 112's `ancestors()` call.
  Cause: `ancestors()` recurses through every predecessor without
  memoization, so DAG diamonds (multiple paths to a shared ancestor)
  trigger combinatorial blowup that hits Python's default 1000-deep
  limit, **even with no true cycle**. Fix: identify the recently-added
  `\uses{...}` edge(s) that created a new diamond and remove the
  redundant edge. The clean fix is generally to keep `\uses{...}`
  minimal (one path per ancestor) and let cross-cutting dependencies
  surface through downstream theorems' `\uses{}` instead.
