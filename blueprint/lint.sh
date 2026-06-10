#!/usr/bin/env bash
#
# blueprint/lint.sh — the fast static reference checks as one command.
#
# Runs the three grep/awk-scriptable gates documented in
# blueprint/CLAUDE.md *Static checks before commit*:
#
#   1. Every \uses{...} and \cref/\Cref{...} target has a \label{...}.
#   2. Every \cite{...} key has a bibliography.bib entry, and every
#      bib entry is cited somewhere.
#   3. Supersession gate: no live (non-superseded) node's \uses{...}
#      reaches a node whose environment title carries `superseded`.
#
# Needs no venv / TeX / lake — pure text checks, runs in well under a
# second. It does NOT replace verify.sh (inv bp + inv web +
# checkdecls), nor the by-eye honesty gate on \leanok additions.
#
# Run from anywhere; exits non-zero with the offending names on the
# first failing check.

set -euo pipefail

SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
SRC="$SCRIPT_DIR/src"
cd "$SRC"

# Collect chapter TeX files (recursively under chapter/).
TEXFILES="$(find chapter -name '*.tex' | sort)"
if [ -z "$TEXFILES" ]; then
    echo "lint.sh: no chapter/*.tex files found under $SRC" >&2
    exit 1
fi

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
FAIL=0

# shellcheck disable=SC2086
{ grep -hoE '\\label\{[^}]+\}' $TEXFILES | sed 's/\\label{//;s/}$//' || true; } \
    | sort -u > "$TMP/labels.txt"

# --- 1. \uses and \cref/\Cref resolution -------------------------------
# shellcheck disable=SC2086
{ grep -hoE '\\uses\{[^}]+\}' $TEXFILES | sed 's/\\uses{//;s/}$//' || true; } \
    | tr ',' '\n' | sed 's/^ *//;s/ *$//' | sort -u > "$TMP/uses.txt"
# shellcheck disable=SC2086
{ grep -hoiE '\\cref\{[^}]+\}' $TEXFILES | sed -E 's/\\[cC]ref\{//;s/}$//' || true; } \
    | tr ',' '\n' | sed 's/^ *//;s/ *$//' | sort -u > "$TMP/crefs.txt"

UNDEF_USES="$(comm -23 "$TMP/uses.txt" "$TMP/labels.txt")"
UNDEF_CREFS="$(comm -23 "$TMP/crefs.txt" "$TMP/labels.txt")"
if [ -n "$UNDEF_USES$UNDEF_CREFS" ]; then
    echo "lint.sh: \\uses / \\cref targets with no \\label:" >&2
    printf '%s\n%s\n' "$UNDEF_USES" "$UNDEF_CREFS" | grep -v '^$' | sed 's/^/  /' >&2
    FAIL=1
fi

# --- 2. \cite keys vs bibliography.bib ---------------------------------
if [ -f bibliography.bib ]; then
    # shellcheck disable=SC2086
    { grep -hoE '\\cite(\[[^]]*\])?\{[^}]+\}' $TEXFILES || true; } \
        | sed -E 's/\\cite(\[[^]]*\])?\{//;s/}$//' | tr ',' '\n' | sed 's/^ *//;s/ *$//' \
        | sort -u > "$TMP/cite-keys.txt"
    { grep -hoE '^@[a-zA-Z]+\{[^,]+' bibliography.bib | sed 's/^@[a-zA-Z]*{//' || true; } \
        | sort -u > "$TMP/bib-keys.txt"
    MISSING="$(comm -23 "$TMP/cite-keys.txt" "$TMP/bib-keys.txt")"
    UNUSED="$(comm -13 "$TMP/cite-keys.txt" "$TMP/bib-keys.txt")"
    if [ -n "$MISSING" ]; then
        echo "lint.sh: \\cite keys with no bib entry:" >&2
        echo "$MISSING" | sed 's/^/  /' >&2
        FAIL=1
    fi
    if [ -n "$UNUSED" ]; then
        echo "lint.sh: bib entries never cited:" >&2
        echo "$UNUSED" | sed 's/^/  /' >&2
        FAIL=1
    fi
fi

# --- 3. Supersession gate ----------------------------------------------
# Stage 1 — superseded labels (the environment title carries the
# `superseded` marker; the project's invariant is that \label{} sits on
# the line after \begin{...}[...]).
# shellcheck disable=SC2086
awk 'BEGIN{IGNORECASE=1}
 /\\begin\{(lemma|theorem|proposition|corollary|definition)\}\[/{e=1;s=($0~/superseded/)}
 e&&/\\label\{/{if(s){match($0,/\\label\{[^}]+\}/);l=substr($0,RSTART,RLENGTH);
   gsub(/\\label\{|\}/,"",l);print l} e=0;s=0}' $TEXFILES \
 | sort -u > "$TMP/sup-labels.txt"
# Stage 2 — labels reached by a \uses of a NON-superseded env (statement
# or proof; \uses bodies may wrap, so accumulate to the closing }). A
# \begin[...] resets the live flag; a \begin{proof} (no [title])
# inherits the preceding env's flag.
# shellcheck disable=SC2086
awk 'BEGIN{IGNORECASE=1;live=1;u=0}
 /\\begin\{(lemma|theorem|proposition|corollary|definition)\}\[/{live=($0!~/superseded/);u=0;b=""}
 {ln=$0; if(u)b=b ln; else{i=index(ln,"\\uses{"); if(i>0){u=1;b=substr(ln,i+6)}}
  if(u){j=index(b,"}"); if(j>0){body=substr(b,1,j-1);u=0;b="";
   if(live){n=split(body,a,",");for(k=1;k<=n;k++){gsub(/[ \t\r\n]/,"",a[k]);
     if(a[k]!="")print a[k]}}}}}' $TEXFILES \
 | sort -u > "$TMP/live-uses.txt"

VIOLATIONS="$(comm -12 "$TMP/sup-labels.txt" "$TMP/live-uses.txt")"
if [ -n "$VIOLATIONS" ]; then
    echo "lint.sh: live nodes \\uses-depend on superseded nodes:" >&2
    echo "$VIOLATIONS" | sed 's/^/  /' >&2
    FAIL=1
fi

if [ "$FAIL" -ne 0 ]; then
    echo "blueprint/lint.sh: FAILED." >&2
    exit 1
fi
echo "blueprint/lint.sh: all static reference checks passed."
