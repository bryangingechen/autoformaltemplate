Coordinate Phase $ARGUMENTS. Dispatch subagents one at a time; each one
does the next concrete commit per the existing workflow, then sanity-
check and dispatch the next. Stop when the phase closes or something
looks off.

Setup: follow CLAUDE.md reading order (CLAUDE.md, ROADMAP.md,
notes/Phase$ARGUMENTS.md). Confirm `git status` is clean and the
leftmost active phase file builds green (per the *Starting a Lean-
touching session* checklist in {{PROJECT_NAME}}/CLAUDE.md). Run the
coordination loop in the foreground of this session only — never
backgrounded or forked: two instances sharing one working tree have
ended with one instance committing the other's half-validated
uncommitted work.

Before dispatching the first subagent, confirm with the user whether
this run modifies any of these instructions. In practice users almost
always customize at session start — typically lifting the 10-run cap
("keep going until the phase closes or something looks off") and
pre-authorizing the mechanical fixups in step 4 — so ask once up
front instead of interrupting at the first occurrence.

Loop:

1. Note the current HEAD sha and re-read notes/Phase$ARGUMENTS.md's
   "Hand-off / next phase" — that's what the next commit should
   accomplish. If that step is **research-shaped** — the hand-off
   flags "recon-before-build", names a node as research-shaped, or
   recent commits have been *peeling* a hard node's easy halves while
   deferring its core — the next commit is a **recon / design-pass**,
   not a blind build: dispatch a Plan-agent recon (read-only), or
   instruct the subagent to land a docs/blueprint design-pass commit
   that decomposes the core into buildable leaves. Recon is this
   workflow's highest-leverage move; "peeling" is circling at the
   node level — break it with a recon of the core. **Trigger it
   early:** 2+ consecutive leaf commits feeding a hard core that is
   itself not yet built is already the signal — recon the core
   *before* the next leaf, rather than waiting to see whether the
   next commit "is" the core. The same trigger covers **wrapper
   churn**: 3+ consecutive commits with small proofs that mostly
   alias existing facts means the trajectory needs a planning/recon
   commit, not another wrapper.
2. **Model-tier experiment (only while `notes/model-experiment.md`
   says Status: running):** rate the dispatch on the S/P/B axes and
   pick the model rung per `notes/model-experiment-protocol.md` (the
   portable protocol: axes, assignment map, probes / boundary pairs,
   quality rubric); pass the rung as the Agent tool's `model`
   parameter, holding the prompt fixed. After the commit verifies,
   append the dispatch row to the log in `notes/model-experiment.md`.
   The protocol file is the single source of truth — don't duplicate
   it here. If the log's Status says concluded, follow whatever
   standing guideline its *Findings* section promoted, and ignore
   this step.
3. Dispatch Agent (subagent_type: general-purpose) with exactly the
   prompt below (for a recon / design-pass step, adapt the first line
   to name that deliverable):

       Continue Phase $ARGUMENTS — do the next concrete commit per
       notes/Phase$ARGUMENTS.md "Hand-off / next phase", then stop.
       Commit directly on the current branch — do not create a new
       branch — and match the git author identity of the existing
       commits. Follow the project's reading order, friction review,
       and pre-commit checklist (CLAUDE.md and its subdirectory
       auto-loads carry the discipline). Run your build/lint gates
       to completion and commit before ending your turn — never end
       the turn with finished-but-uncommitted work while a
       background gate is still running. After committing, return
       a final message of exactly the form:
         LANDED <sha>: <one-line summary>
       or
         BLOCKED: <one-paragraph reason and what would unblock>.

4. When the subagent returns, run `git log --oneline -3`, `git show
   --stat HEAD`, and `git branch --show-current`. Verify: HEAD
   advanced past the noted sha; **we are still on the default
   branch**; the commit author matches the project's existing
   commits; the diff touches what the previous "Hand-off" pointed at
   (often a Lean file + a blueprint `\lean{...}` / `\leanok` flip +
   notes/Phase$ARGUMENTS.md, but a **docs/blueprint-only** commit —
   an opening recon, design pass, node decomposition, route-correction
   finding, or scope re-scope — is normal in a research-shaped phase;
   do not treat the absence of a Lean change as suspicious).
   **Mechanical fixups, not stops:** if the subagent committed on a
   new branch, `git checkout <default> && git merge --ff-only <branch>
   && git branch -d <branch>`; if the author is wrong, `git commit
   --amend --author=...`; then continue. **A return with neither
   LANDED nor BLOCKED** usually means the subagent parked on a
   background build gate and ended its turn with
   finished-but-uncommitted work in the tree. Don't blind-redispatch
   a fresh "continue" agent — it re-reads everything and may park
   the same way; instead verify the working-tree diff against the
   hand-off yourself, run the build/lint gates, and commit with the
   project author identity. Re-read the updated
   "Hand-off / next phase". **For a recon / design-pass commit, also
   sanity-check the *verdict's reasoning*, not just the commit
   mechanics.** A recon can be mechanically clean (committed, right
   branch, docs-only) yet reach a flawed conclusion; building on a
   wrong verdict re-incurs the churn the recon was meant to end. If
   the verdict's logic looks wrong at a crux — especially a
   producer/existence node where a hypothesis or count is the hard
   part — surface the specific doubt to the user before dispatching a
   build on it. **Scrutinize hardest a recon that *dissolves* or
   *re-routes* a gap:** when it changes which hypothesis / IH
   conjunct / lemma the producer consumes, confirm every *other*
   carried obligation still closes under the new route — a re-route
   can orphan a hypothesis the discarded route silently supplied.
   **A recon that surfaces a NEW gap or a definition-level defect is
   usually cheaply verifiable — verify it before re-planning on it:**
   check the claim against the primary source (`.refs/` PDFs; see
   `REFS.md`) and/or a one-line Lean witness (`lean_run_code`). A
   verified gap is a safe re-plan foundation; an unverified one just
   relocates the churn.
   And **build-dispatched subagents sometimes self-redirect to a
   recon** (they read the "build" and find it needs design first —
   often the right call); apply this same verdict-reasoning scrutiny
   to those unsolicited recons too, *especially* when one overturns
   or dissolves a prior finding.
5. If the commit changed any `.lean` file, run `lake build` of the
   leftmost active phase file as a cheap post-commit gate. If red,
   stop and surface. Skip this gate for docs/blueprint-only commits
   (no `.lean` changed — nothing to rebuild).
6. Write one sentence to the user: clean handoff to the next
   iteration, or the specific concern if anything looked off. If the
   remaining work suggests a **phase-boundary decision** — closing
   the phase early, or splitting a self-contained chunk into a new
   sub-phase — surface it to the user with a concrete commit-count
   estimate rather than deciding it unilaterally.
7. Stop and surface on any of:
   - ROADMAP Status table shows Phase $ARGUMENTS ✓ (phase closed; the
     subagent will have already run the phase-close checklist). This
     includes a user-approved mid-session close-and-split: after the
     requested action lands, report it and **confirm with the user
     before restarting the loop** on the successor phase — completing
     a requested action is not approval to resume autonomous
     dispatch.
   - Subagent returned BLOCKED.
   - HEAD didn't advance (subagent didn't actually commit).
   - Diff looks suspicious — unexpectedly large, or touches files
     unrelated to the next-commit pointer, or post-commit `lake build`
     is now red. (A docs/blueprint-only design/recon commit is not
     itself suspicious — judge against what the hand-off pointed at.)
   - 10 subagent runs have completed since the user last checked in
     (default cap — confirmed or lifted in the pre-dispatch check-in
     above; ask before continuing past whatever was agreed).

Don't pad the **routine build** subagent prompt or pre-load files for
it. The project's CLAUDE.md auto-loads are designed to carry
everything; duplicating that in the prompt would invite drift between
the two sources of truth. (A recon / design-pass commit is the
exception: it is a different deliverable, so it gets a tailored prompt
naming what to recon or decompose — see step 1.)

For **cleanup rounds** (per CLEANUP.md) a third dispatch shape works
well: a scoped no-git editor — "Edit ONLY <file>. Touch no other
file. Do NOT run git / commit / `inv` / `verify.sh` / `lake`" — with
the coordinator reviewing and committing the result itself. Use it
for per-file readability or audit passes where the value is the edit,
not the workflow.
