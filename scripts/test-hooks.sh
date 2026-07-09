#!/usr/bin/env bash
#
# Test suite for the PreToolUse hooks in .claude/hooks/. Each hook is
# a pure stdin(JSON) → stdout(JSON-or-empty) filter, so the tests
# feed synthetic tool_input payloads and assert on the
# permissionDecision (never on message text, which carries the
# project name and so differs pre-/post-instantiation).
#
# Run from any cwd: scripts/test-hooks.sh
# Exit 0 + sentinel last line on success; non-zero with the failing
# case names otherwise. Needs jq, perl, git (same as the hooks).
#
# CI runs this twice (template form and post-instantiation form) via
# .github/workflows/template-ci.yml; run it locally on any commit
# that edits a hook.

set -u

HOOKS_DIR="$(cd "$(dirname "$0")/.." && pwd)/.claude/hooks"
fail=0

# run_hook <hook-script> <expected: deny|allow> <case-name> <command>
run_hook() {
    local hook="$1" expected="$2" name="$3" command="$4"
    local out decision
    out=$(jq -cn --arg c "$command" '{tool_input: {command: $c}}' \
        | "$HOOKS_DIR/$hook")
    if printf '%s' "$out" | grep -q '"permissionDecision":"deny"'; then
        decision=deny
    else
        decision=allow
    fi
    if [ "$decision" = "$expected" ]; then
        echo "PASS  $hook: $name"
    else
        echo "FAIL  $hook: $name (expected $expected, got $decision)"
        fail=1
    fi
}

# ---------------------------------------------------------------
# block-lake-update.sh — deny executable `lake update` / `--update`;
# quoted and heredoc mentions must not trigger.

run_hook block-lake-update.sh deny  "bare lake update" \
    'lake update'
run_hook block-lake-update.sh deny  "lake build --update" \
    'lake build --update'
run_hook block-lake-update.sh deny  "compound command" \
    'cd proj && lake update mathlib'
run_hook block-lake-update.sh allow "plain lake build" \
    'lake build MyProject.Basic'
run_hook block-lake-update.sh allow "lake exe cache get" \
    'lake exe cache get'
run_hook block-lake-update.sh allow "double-quoted mention" \
    'git commit -m "never run lake update mid-session"'
run_hook block-lake-update.sh allow "single-quoted mention" \
    "grep -r 'lake update' docs/"
run_hook block-lake-update.sh allow "heredoc-body mention" \
    'cat <<EOF > note.txt
the rule: lake update is banned
EOF'

# ---------------------------------------------------------------
# block-sorry-commit.sh — deny `git commit` while the .lean diff vs
# HEAD adds sorry/admit; prose mentions (comments, backticks,
# non-.lean files, commit messages) and non-commit commands must not.
# Needs a scratch repo: the hook cds to CLAUDE_PROJECT_DIR and diffs.

scratch="$(mktemp -d)"
trap 'rm -rf "$scratch"' EXIT
git -C "$scratch" init -q -b main
git -C "$scratch" config user.name t
git -C "$scratch" config user.email t@t
printf 'theorem ok : True := trivial\n' > "$scratch/Foo.lean"
git -C "$scratch" add -A
git -C "$scratch" commit -qm init
export CLAUDE_PROJECT_DIR="$scratch"

# sorry_case <expected> <name> <appended-lean-line> [command]
sorry_case() {
    local expected="$1" name="$2" line="$3" command="${4:-git add -A && git commit -m \"x\"}"
    git -C "$scratch" checkout -q -- . 2>/dev/null
    git -C "$scratch" clean -qfd
    [ -n "$line" ] && printf '%s\n' "$line" >> "$scratch/Foo.lean"
    run_hook block-sorry-commit.sh "$expected" "$name" "$command"
}

sorry_case deny  "added sorry"              'theorem bad : False := by sorry'
sorry_case deny  "added admit"              'theorem bad : False := by admit'
sorry_case allow "clean tree"               ''
sorry_case allow "sorry only in commit msg" '' 'git commit -m "close the last sorry"'
sorry_case allow "non-commit git command"   'theorem bad : False := by sorry' 'git status'
sorry_case allow "line-comment mention"     '-- TODO: the sorry below is historical'
sorry_case allow "backticked doc mention"   '/-- carries no `sorry` anymore -/'
git -C "$scratch" checkout -q -- .
printf 'a sorry-laden sentence\n' >> "$scratch/notes.md"
run_hook block-sorry-commit.sh allow "non-.lean file mention" \
    'git add -A && git commit -m "x"'

# ---------------------------------------------------------------
# block-nested-agent.sh — deny Agent-tool calls whose hook input
# carries an agent_id (subagent context); top-level calls (no
# agent_id) pass through. Payload shape differs from the Bash
# hooks, so build it directly instead of via run_hook.

# agent_case <expected> <name> <json-payload>
agent_case() {
    local expected="$1" name="$2" payload="$3"
    local out decision
    out=$(printf '%s' "$payload" | "$HOOKS_DIR/block-nested-agent.sh")
    if printf '%s' "$out" | grep -q '"permissionDecision": *"deny"'; then
        decision=deny
    else
        decision=allow
    fi
    if [ "$decision" = "$expected" ]; then
        echo "PASS  block-nested-agent.sh: $name"
    else
        echo "FAIL  block-nested-agent.sh: $name (expected $expected, got $decision)"
        fail=1
    fi
}

agent_case deny  "subagent context (agent_id present)" \
    '{"agent_id":"a1b2c3","tool_input":{"prompt":"do a thing"}}'
agent_case allow "top-level dispatch (no agent_id)" \
    '{"tool_input":{"prompt":"do a thing"}}'
agent_case allow "empty agent_id" \
    '{"agent_id":"","tool_input":{"prompt":"do a thing"}}'

# ---------------------------------------------------------------
if [ "$fail" -ne 0 ]; then
    echo "scripts/test-hooks.sh: FAILED."
    exit 1
fi
echo "scripts/test-hooks.sh: all hook tests passed."
