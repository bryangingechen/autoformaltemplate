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
- **Non-ASCII subscript characters (`₀`, `₁`, …) outside math
  mode.** xelatex Emergency-stops with *"`\check@icr` ... `l.N
  <token>`"* when a Lean identifier carrying a unicode subscript
  (e.g. `v₀`) appears in plain prose, even inside `\texttt{...}`.
  Rewrite the prose to drop the subscripted token (e.g. "the
  distinguished vertex $v_0$") or wrap the whole identifier in
  math mode if the subscript-as-subscript is the point. The same
  class of pasted-from-Lean glyphs — math-symbol-class
  superscripts (`⁰`), subscript operators (`₊`, `₋`), combining
  marks (macron `h̄`, tilde) — trips the same failure. The
  Lean-side analogue (these are not valid identifier characters
  either) lives in `../TACTICS-QUIRKS.md`.
- **`\lean{Name1, Name2}` with multiple names** is fine for the
  HTML build (each links separately) but produces only one link
  target in the PDF. Reserve multi-name `\lean{}` for closely-
  related corner cases the reader genuinely thinks of as a unit.
- **A literal `\lean{}` in prose poisons `lean_decls` and fails
  `checkdecls`.** plastex executes the `\lean` macro wherever it
  appears, including inside descriptive prose — e.g. a
  forward-mode chapter preamble saying "each node gains a `\lean{}`
  pointer". The empty argument is parsed as a one-element decl list
  `['']`, and leanblueprint writes it as a blank line into
  `lean_decls`; `checkdecls` then resolves `"".toName =
  Name.anonymous`, prints ` is missing.` (note the leading space —
  empty name), and exits 1. It stays *silent* while the chapter has
  no real `\lean{}` entries (the lone blank is a trailing line
  `IO.FS.lines` drops), then surfaces the moment the first real
  entry lands after it. Fix: never write a bare `\lean{}` in prose —
  use `\texttt{\textbackslash lean}` to typeset the macro name.
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
- **Unicode letters in math mode break `inv bp` (xelatex).** A raw
  Unicode glyph in a math expression — e.g. pasting a Lean identifier
  like `ιMulti` into `$\mathrm{ι Multi}$` — Emergency-stops the run with
  *"Missing character: There is no ι (U+03B9) in font
  [lmroman10-regular]"*. The `lmroman` math font has no Greek-letter
  glyphs at those codepoints. `inv web` (plastex) tolerates the same
  glyph, so this only surfaces on the PDF pass. Fix: don't typeset Lean
  identifiers in prose at all (the `\lean{}` pin already links them);
  if you genuinely need the symbol, use its TeX command (`\iota`, not
  `ι`). Same failure mode and cascade as the math-in-titles entry above
  (a failed `inv bp` leaves the next `inv web` with no `print.bbl`).
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
