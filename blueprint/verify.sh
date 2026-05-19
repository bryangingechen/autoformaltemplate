#!/usr/bin/env bash
#
# blueprint/verify.sh — full blueprint + checkdecls gate as one command.
#
# Runs `inv bp` (latexmk → PDF + print.bbl → src/web.bbl), `inv web`
# (plastex → blueprint/web/ + regenerated blueprint/lean_decls), and
# `lake exe checkdecls blueprint/lean_decls` (verifies every
# `\lean{...}` pointer resolves to a real Lean declaration). All three
# are the per-commit gates documented in blueprint/CLAUDE.md *Static
# checks before commit* — bundled here so the agent doesn't reassemble
# the cd/PATH/venv invocation by hand each time.
#
# Run from anywhere; the script computes the repo root from its own
# location. Falls back to /Library/TeX/texbin if `xelatex` isn't
# already on PATH (BasicTeX default on macOS); on other platforms the
# fallback is a no-op and the script assumes xelatex is reachable.
#
# Exit codes: 0 on full success, non-zero on the first failing step.
# `checkdecls` prints nothing on success — silence on the final step
# is what "passed" looks like.

set -euo pipefail

SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
REPO_ROOT="$( cd -- "$SCRIPT_DIR/.." && pwd )"

if ! command -v xelatex >/dev/null 2>&1; then
    if [ -x /Library/TeX/texbin/xelatex ]; then
        export PATH="/Library/TeX/texbin:$PATH"
    else
        echo "verify.sh: xelatex not found on PATH and /Library/TeX/texbin/xelatex does not exist." >&2
        echo "  See blueprint/CLAUDE.md *One-time setup* for installing BasicTeX (macOS) or your distro's xelatex package." >&2
        exit 1
    fi
fi

if [ ! -f "$SCRIPT_DIR/.venv/bin/activate" ]; then
    echo "verify.sh: blueprint/.venv not found." >&2
    echo "  See blueprint/CLAUDE.md *One-time setup* for venv creation." >&2
    exit 1
fi

# shellcheck source=/dev/null
source "$SCRIPT_DIR/.venv/bin/activate"

cd "$SCRIPT_DIR"
echo "==> inv bp"
inv bp

echo
echo "==> inv web"
inv web

cd "$REPO_ROOT"
echo
echo "==> lake exe checkdecls blueprint/lean_decls"
lake exe checkdecls blueprint/lean_decls
echo "    (no output = all \\lean{...} names resolve)"

echo
echo "blueprint/verify.sh: all gates passed."
