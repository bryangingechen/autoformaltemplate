#!/usr/bin/env bash
#
# PreToolUse hook (Bash matcher): deny any `git commit` while the
# would-be-committed .lean changes (working tree + index vs HEAD)
# add a `sorry`/`admit`. Mechanical backstop for the project's
# no-sorry discipline ({{PROJECT_NAME}}/CLAUDE.md *build and
# lint gates*: a warning-clean build is the no-sorry gate; the
# explicit-`h…` idiom is the sanctioned way to carry a crux).
# Added after a long context-compacted session committed a sorry'd
# skeleton with a false "gates clean" attestation
# (CombinatorialRigidity 2026-06-10, model-experiment row 17):
# prompt-level discipline does not survive context compaction;
# hooks do.
#
# Detection notes:
# - The command is heredoc/quote-stripped first, so `sorry` in a
#   commit message or grep pattern never triggers; only an actual
#   unquoted `git … commit` invocation is inspected.
# - Diff is taken against HEAD (not --cached) because commits here
#   usually arrive as `git add … && git commit …` compounds — at
#   PreToolUse time nothing is staged yet.
# - Only ADDED diff lines count (legacy prose mentions in HEAD are
#   ignored), with `--`-comments and backtick-quoted spans stripped
#   (doc-comment prose almost always backticks `sorry`).

input=$(cat)
cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // ""')

stripped=$(printf '%s\n' "$cmd" | perl -0777 -pe '
  s/<<-?\s*(["\x27]?)(\w+)\1.*?\n\2(?=\s|$)//gs;  # heredoc bodies
  s/"(?:\\.|[^"\\])*"//gs;                          # double-quoted strings
  s/\x27[^\x27]*\x27//gs;                           # single-quoted strings
')

printf '%s' "$stripped" | grep -qE '\bgit\b[^|;&]*\bcommit\b' || exit 0

cd "${CLAUDE_PROJECT_DIR:-.}" || exit 0

offending=$(git diff HEAD -- '*.lean' | grep -E '^\+[^+]' | perl -pe '
  s/--.*$//;          # line comments
  s/`[^`]*`//g;       # backtick-quoted prose mentions
' | grep -nE '\b(sorry|admit)\b' | head -3)

if [ -n "$offending" ]; then
  reason="Blocked: the .lean changes this commit would include add a \`sorry\`/\`admit\` (diff vs HEAD): ${offending}. The project never commits sorries — carry the crux as an explicit hypothesis instead (the h… idiom; see {{PROJECT_NAME}}/CLAUDE.md, build and lint gates). If this is a false positive (prose mention outside backticks), reword the comment."
  jq -cn --arg r "$reason" '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":$r}}'
fi
exit 0
