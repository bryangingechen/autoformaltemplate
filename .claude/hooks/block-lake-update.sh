#!/usr/bin/env bash
#
# PreToolUse hook (Bash matcher): deny any command that would run
# `lake update` or a lake invocation with `--update` — these rewrite
# lake-manifest.json + lean-toolchain and force a from-source mathlib
# rebuild (see {{PROJECT_NAME}}/CLAUDE.md *Build discipline*; added
# after the 2026-06-10 OOM crash).
#
# Heredoc bodies and quoted strings are stripped before matching so
# prose mentions (commit messages, grep patterns, log greps) don't
# false-positive; only an unquoted — i.e. executable — occurrence
# triggers the deny.

cmd=$(jq -r '.tool_input.command // ""')

stripped=$(printf '%s\n' "$cmd" | perl -0777 -pe '
  s/<<-?\s*(["\x27]?)(\w+)\1.*?\n\2(?=\s|$)//gs;  # heredoc bodies
  s/"(?:\\.|[^"\\])*"//gs;                          # double-quoted strings
  s/\x27[^\x27]*\x27//gs;                           # single-quoted strings
')

if printf '%s' "$stripped" | grep -qE 'lake[^|;&]*--update|lake +update'; then
  echo '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"Blocked: lake update / lake --update rewrites lake-manifest.json and lean-toolchain and forces a from-source mathlib rebuild. Toolchain and dependency bumps are a human decision; see {{PROJECT_NAME}}/CLAUDE.md (build/lint gates)."}}'
fi
exit 0
