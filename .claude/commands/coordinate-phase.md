Coordinate Phase $ARGUMENTS. Dispatch subagents one at a time; each one
does the next concrete commit per the existing workflow, then sanity-
check and dispatch the next. Stop when the phase closes or something
looks off.

Setup: follow CLAUDE.md reading order (CLAUDE.md, ROADMAP.md,
notes/Phase$ARGUMENTS.md). Confirm `git status` is clean and the
leftmost active phase file builds green (per *Starting a Lean-touching
session* in {{PROJECT_NAME}}/CLAUDE.md). Run the loop in the
foreground of this session only — never backgrounded or forked: two
instances sharing one working tree have ended with one committing the
other's half-validated uncommitted work.

Before the first dispatch, ask the user once whether this run modifies
these instructions — in practice users customize at session start,
typically lifting the 10-run cap and pre-authorizing the step-4
mechanical fixups.

Loop:

1. Note HEAD and re-read notes/Phase$ARGUMENTS.md "Hand-off / next
   phase" — that's what the next commit should accomplish. If that
   step is **research-shaped** — the hand-off flags recon-before-build,
   OR 2+ consecutive leaf commits have fed a hard core that is itself
   not yet built, OR 3+ consecutive commits are thin wrappers aliasing
   existing facts — the next commit is a **recon / design-pass**, not a
   build: dispatch a read-only Plan-agent recon, or a docs/blueprint
   design-pass commit that decomposes the core into buildable leaves
   with exact signatures. Recon is this workflow's highest-leverage
   move; trigger it **early**, before the next leaf (an ancestor
   project burned ~4 leaf commits on an undischargeable core; its next
   sub-phase fired the recon at exactly the 2-leaf trigger, which
   re-routed the whole discharge and surfaced a real gap before
   anything was built on the dead route).
2. **Model-tier experiment (only while `notes/model-experiment.md`
   says Status: running):** rate S/P/B and pick the rung per
   `notes/model-experiment-protocol.md` (the single source of truth —
   don't duplicate it here); pass it as the Agent tool's `model`
   parameter, prompt held fixed. Honor any **standing rung override**
   in the log's repo-local config. Append the log row only after the
   verification pass completes in full — and match the previous row's
   tail only, never an edit span that includes the following section
   header (the `## Findings` header got clobbered 3× this way in one
   coordinator session). If Status says concluded, follow the promoted
   guideline instead.
3. Dispatch Agent (subagent_type: general-purpose) with exactly the
   prompt below (for a recon / design-pass step, adapt the first line
   to name that deliverable):

       Continue Phase $ARGUMENTS — do the next concrete commit per
       notes/Phase$ARGUMENTS.md "Hand-off / next phase", then stop.
       Commit directly on the current branch — do not create a new
       branch — and match the git author identity of the existing
       commits. Follow the project's reading order, friction review,
       and pre-commit checklist (CLAUDE.md and its subdirectory
       auto-loads carry the discipline). Scope to fit one sitting:
       land the smallest complete deliverable that moves the
       hand-off forward — if the named deliverable won't fit, shrink
       the deliverable (a smaller complete lemma / sub-step), never
       the completeness (no sorry/admit placeholders, no
       warning-carrying commits, no deferred-work stubs). If your
       context gets compacted/summarized mid-task, or you notice
       earlier session context has been lost, do not push on
       degraded: bring the tree to a clean state (commit only what
       is complete and gate-verified, revert the rest) and return
       BLOCKED with a progress summary. Run your build/lint gates to
       completion and commit before ending your turn — never end the
       turn with finished-but-uncommitted work while a background
       gate is still running. Do not edit notes/model-experiment.md
       — the dispatch log is coordinator-owned. After committing,
       return a final message of exactly the form:
         LANDED <sha>: <one-line summary>
       or
         BLOCKED: <one-paragraph reason and what would unblock>.

4. Verify the return:
   - **Mechanics:** `git log --oneline -3`, `git show --stat HEAD`,
     `git branch --show-current`. HEAD advanced past the noted sha;
     still on the default branch; the commit author matches the
     project's existing commits; diff matches what the hand-off
     pointed at. A docs/blueprint-only commit (recon, design pass,
     decomposition, re-scope) is normal in a research-shaped phase —
     judge against the hand-off, not against "must touch Lean".
   - **"Gates green" is an attestation, not evidence.** The step-5
     gate always runs; for below-top-rung dispatches also re-run
     `lake lint` and read the **full diff** (protocol rule); for
     haiku, re-run every gate the return names (a haiku once
     fabricated all three gates green — enharmonic 2026-06-10,
     model-experiment row 12).
   - **Sorry-grep the touched `.lean` files after every
     below-top-rung dispatch**, regardless of what the return says —
     a LANDED return can omit a `sorry` that the commit message
     discloses (enharmonic row 13: the commit message was honest,
     the return was not). Read the commit message body, not just the
     summary line. A landed sorry is a failed verification →
     escalation per the protocol: re-dispatch one rung up with the
     route named in the prompt, keep the landed commit, close the
     sorry in the follow-up (rows 7–8 and 13–14 precedent).
   - **Shape check:** when the hand-off pins the deliverable to a
     design verdict (a design-doc § pointer or named verdict), diff
     the landed statement against that section — motive strength,
     transport direction, consumed-vs-carried hypotheses.
     Mechanically clean commits landed design-excluded shapes twice
     in one session (CombinatorialRigidity rows 11, 14); only the
     section re-read caught them. A shape deviation = corrective
     dispatch one rung up with a tailored prompt naming the verdict,
     never a discharge-on-top.
   - **Mechanical fixups, not stops:** wrong branch → `git checkout
     <default> && git merge --ff-only <branch> && git branch -d
     <branch>`; wrong author → `git commit --amend --author=…`;
     `Co-Authored-By:` trailer in model-id form (`claude-sonnet-4-6`)
     → amend to display form (`Claude Sonnet 4.6`) — sonnet does this
     persistently even with the rule in CLAUDE.md. A return with
     **neither LANDED nor BLOCKED** usually means the subagent parked
     on a background gate with finished-but-uncommitted work — don't
     blind-redispatch (a fresh "continue" agent re-reads everything
     and may park the same way); verify the tree diff against the
     hand-off yourself, run the gates, commit with the project
     identity.
   - **Recon verdicts get reasoning scrutiny, not just commit
     mechanics** — a mechanically clean recon can still be wrong, and
     building on it re-incurs the churn it was meant to end.
     Scrutinize hardest a recon that **dissolves or re-routes** a
     gap: confirm every *other* carried obligation still closes under
     the new route (a re-route can orphan a hypothesis the discarded
     route silently supplied). A recon that surfaces a **new gap** is
     usually cheaply verifiable — check it against the primary source
     (`.refs/` PDFs, REFS.md) and/or a one-line Lean witness
     (`lean_run_code`) *before* re-planning on it; verified gaps have
     settled in minutes, and an unverified one just relocates the
     churn. Build-dispatched agents sometimes self-redirect to a
     recon — often rightly; same scrutiny, especially when one
     overturns a prior finding.
   - **Plan-label deviations (destructive→additive, slice re-size)
     are a normal, usually-correct self-redirect in migration
     phases** — in one ancestor run four consecutive "destructive"
     slices rightly landed additively (enharmonic Phase 17). Verify
     the stated reason against the source once (the first occurrence
     sets the pattern), confirm the deferred obligation (legacy
     retirement, follow-up sub-slice) is recorded in the phase notes
     with a slice pointer, and fix the drift at the authoritative
     plan doc when pausing — a plan doc that says "destructive" while
     reality went additive is a trap for the next coordinator.
   - Re-read the updated "Hand-off / next phase".
5. If the commit changed any `.lean` file: `touch` the changed file
   (cached modules don't re-emit warnings), then `lake build
   <leftmost active module> 2>&1 | grep -E 'warning:|error:'` —
   **warning-clean, not merely green** (a sorry'd skeleton once rode
   a green-but-warning build onto master — CombinatorialRigidity,
   row 17). Red or warning-bearing → stop and surface. Skip for
   docs-only commits.
6. One sentence to the user: clean handoff, or the specific concern.
   Surface **phase-boundary decisions** — early close, sub-phase
   split, a change to what "phase close" means — with a concrete
   commit-count estimate rather than deciding unilaterally.
7. Stop and surface on any of:
   - ROADMAP Status shows Phase $ARGUMENTS ✓ (the subagent ran the
     phase-close checklist). After a user-approved mid-session
     close-and-split, confirm with the user before resuming the loop
     on the successor phase.
   - BLOCKED return; or HEAD didn't advance.
   - A recon flags a decision for **user adjudication** (e.g. a
     carried hypothesis or motive change) — present the options with
     estimates; don't pick unilaterally.
   - Suspicious diff: unexpectedly large, unrelated files, or the
     step-5 gate red.
   - The agreed run cap (default 10) reached since the user last
     checked in.

Don't pad the **routine build** prompt or pre-load files — the
CLAUDE.md auto-loads carry the discipline, and duplication invites
drift. (The scope-to-fit / compaction-bailout clause *is* part of the
fixed prompt: prompt-level discipline doesn't survive compaction — a
2.7 h, multiply-compacted dispatch committed a sorry'd skeleton, row
17 — so the clause shapes scope while context is intact and the
`block-sorry-commit.sh` hook backstops after it degrades. Evidence the
clause works: the next dispatches self-shrank to complete sub-lemmas.)
A **recon / design-pass** dispatch is the exception: give it a
tailored prompt naming what to recon, the coordinator's verified
findings motivating it, and the deliverable (a design-doc entry +
re-pointed hand-off).

For **cleanup rounds** (per CLEANUP.md) a third dispatch shape works
well: a scoped no-git editor — "Edit ONLY <file>. Touch no other
file. Do NOT run git / commit / `inv` / `verify.sh` / `lake`" — with
the coordinator reviewing and committing the result itself.
