#!/usr/bin/env bash
#
# scripts/rename.sh — instantiate the template for a new project.
#
# Usage:
#   ./scripts/rename.sh ProjectName [github-user]
#
# - ProjectName is PascalCase (e.g. MyAwesomeProject). The script
#   derives the kebab-case form (my-awesome-project) for GitHub repo /
#   Pages URLs.
# - github-user is optional; if provided, replaces {{GITHUB_USER}}
#   placeholders too. Otherwise those stay as placeholders and you'll
#   need to edit them by hand.
#
# After success the script self-deletes (since the template doesn't
# need it after instantiation) and prints a next-step checklist.

set -euo pipefail

if [ "$#" -lt 1 ] || [ "$#" -gt 2 ]; then
    echo "usage: $0 ProjectName [github-user]" >&2
    exit 64
fi

PASCAL="$1"
GH_USER="${2:-}"

# Validate PascalCase shape: starts with an uppercase letter,
# alphanumeric only.
if ! [[ "$PASCAL" =~ ^[A-Z][A-Za-z0-9]+$ ]]; then
    echo "rename.sh: project name '$PASCAL' must be PascalCase ([A-Z][A-Za-z0-9]+)." >&2
    exit 64
fi

# Derive kebab-case from PascalCase: insert a hyphen before each
# uppercase letter that follows a lowercase letter or digit, then
# lowercase the whole string.
KEBAB="$(echo "$PASCAL" | sed -E 's/([a-z0-9])([A-Z])/\1-\2/g' | tr '[:upper:]' '[:lower:]')"

SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
REPO_ROOT="$( cd -- "$SCRIPT_DIR/.." && pwd )"

cd "$REPO_ROOT"

# 1. Rename the project directory and aggregator file.
if [ -d "{{PROJECT_NAME}}" ]; then
    mv "{{PROJECT_NAME}}" "$PASCAL"
fi
if [ -f "{{PROJECT_NAME}}.lean" ]; then
    mv "{{PROJECT_NAME}}.lean" "$PASCAL.lean"
fi

# 2. Find all tracked text files (or all text files if not a git repo)
#    and sed-replace the placeholders. Excludes binary files and the
#    rename script itself.
if [ -d .git ] && command -v git >/dev/null 2>&1; then
    FILES="$(git ls-files | grep -v '^scripts/rename\.sh$' || true)"
else
    FILES="$(find . -type f \
        ! -path './.git/*' \
        ! -path './.lake/*' \
        ! -path './blueprint/.venv/*' \
        ! -path './blueprint/print/*' \
        ! -path './blueprint/web/*' \
        ! -path './home_page/_site/*' \
        ! -path './scripts/rename.sh' \
        | sed 's|^\./||')"
fi

# Use a portable sed-in-place: write to a tmp file and move it back.
# Avoids GNU vs BSD `sed -i` divergence.
replace_in_file() {
    local f="$1"
    local tmp
    tmp="$(mktemp)"
    sed \
        -e "s|{{PROJECT_NAME}}|$PASCAL|g" \
        -e "s|{{ProjectName}}|$PASCAL|g" \
        -e "s|{{project-name}}|$KEBAB|g" \
        ${GH_USER:+-e "s|{{GITHUB_USER}}|$GH_USER|g"} \
        "$f" > "$tmp"
    # Only move if content actually changed (avoid touching mtimes
    # for files with no placeholders).
    if ! cmp -s "$f" "$tmp"; then
        mv "$tmp" "$f"
    else
        rm -f "$tmp"
    fi
}

echo "$FILES" | while IFS= read -r f; do
    [ -z "$f" ] && continue
    [ -f "$f" ] || continue
    # All files we ship are text; the find expression above already
    # excludes the directories where binaries would live (.lake/,
    # blueprint/.venv/, blueprint/print/, blueprint/web/,
    # home_page/_site/). Add an exclusion there if a future template
    # contributor introduces binary assets.
    replace_in_file "$f"
done

# 3. Print next-step checklist.
cat <<EOF

Template instantiated as: $PASCAL ($KEBAB)
${GH_USER:+GitHub user: $GH_USER}

Next steps:
  1. Review the placeholder replacements:
       grep -rE '{{[A-Z_-]+}}' . 2>/dev/null \\
         --exclude-dir=.git --exclude-dir=.lake \\
         --exclude-dir=blueprint/.venv --exclude=rename.sh

     The remaining placeholders ({{PROJECT_TITLE}}, {{AUTHOR}},
     {{ONE_LINE_BLURB}}, {{THEOREM_NAME}}, and possibly
     {{GITHUB_USER}} if you didn't pass it) are free-form prose the
     script can't auto-fill. Edit them by hand.

  2. Fill in narrative content per TEMPLATE.md "After running the
     rename script": README.md, ROADMAP.md, DESIGN.md, CLAUDE.md
     project-history note, blueprint/src/chapter/intro.tex,
     home_page/index.md.

  3. Initialize git (if not already):
       git init && git add -A && git commit -m "Initial scaffold from template"

  4. First Lean build:
       lake exe cache get && lake build

  5. (Optional) First blueprint build — see blueprint/SETUP-AND-PITFALLS.md
     for one-time setup.

You can delete TEMPLATE.md once the project is on its feet.
EOF

# 4. Self-delete.
rm -- "$0"
EOF_MARKER=1
# (The EOF_MARKER line above is a no-op safeguard against accidental
#  truncation: if the file is ever cut short, the `rm "$0"` line is
#  what tells us this script ran to completion.)
