# coordinate-phase-rescue.md — coordinator rescue reference

Symptom-indexed detail for the `/coordinate-phase` loop. The command
body (`.claude/commands/coordinate-phase.md`) carries the
**every-iteration core** — the loop steps, the dispatch playbook, the
verification scrutiny that fires on each commit. **This file carries
the rare / explicit-trigger patterns** it points at: consult the
matching § when its trigger fires. (Same model as `../TACTICS-QUIRKS.md`
for Lean build failures — a reference read on demand, not
session-start orientation.) War-story citations name the downstream
repo the lesson was paid for in.

## Index (symptom → §)

- Wrong branch / author / co-author trailer on a landed commit → §1
- Return shows **neither** LANDED nor BLOCKED; named/async dispatch idles instead of returning → §2
- Dispatch **killed** by a session/usage limit, **or user-interrupted** mid-task → §3
- **API / connection error mid-response** (0-token return; the agent's file edits may be on disk but uncommitted) → §2/§3: verify the tree (`git status`), **salvage** if the uncommitted work is complete + gate-clean (run the gates yourself, commit with a coordinator-authored message), resume-first if partial
- Plan-label deviation (destructive→additive, slice re-size) → §4
- BLOCKED return — which resolutions stay in-workflow → §5
- Non-build dispatch shapes (cleanup round; coordinator-authored; source-verification recon; compiler-checked spike; spike-salvage resume) → §6
- Subagent wedged for hours on a proof timeout (elaboration wall) → §7

## §1 — Mechanical fixups (a fixup, never a stop)

Pre-authorizable at session start. Apply, then note the final sha.

- **Wrong branch** → `git checkout <default> && git merge --ff-only
  <branch> && git branch -d <branch>`.
- **Wrong author** → `git commit --amend --author='<the project's
  existing-commit identity>'`.
- **Wrong co-author trailer** — a subagent naming a model it didn't
  run on (usually the dominant trailer from recent `git log` instead
  of the dispatched model), or the model-id form (`claude-sonnet-5`)
  instead of display form (`Claude Sonnet 5`), or the *coordinator's
  own prompt* dictating a stale display name (a stale example landed
  a wrong trailer that needed a pre-push history rewrite —
  CombinatorialRigidity 2026-07-02; take the name from the current
  model lineup, not from memory) → amend the trailer. A
  prompt-discipline artifact, not an agent fault — the invocation
  prompt names the model explicitly precisely because a generic
  "name your own model" clause failed 3× across two rungs.
- **Spurious extra trailer** — a subagent appends a harness-default
  trailer line (e.g. `Claude-Session: …`) the project convention
  omits. Strip before finalizing:
  `git log -1 --format='%B' HEAD | grep -v '^Claude-Session:' |
  git -c user.name=… -c user.email=… commit --amend -F - --author=…`
  (fold any same-commit note-trim into the same amend). If it
  recurs, a repo-local `commit-msg` hook that strips the line
  mechanically is the durable fix (CombinatorialRigidity's
  `.githooks/` + `git config core.hooksPath .githooks` pattern —
  the hook is version-controlled; the config is per-clone). Buried
  earlier commits with the trailer are cleanable in one filter at
  push, not worth a mid-loop rebase — flag them.

## §2 — Return shows neither LANDED nor BLOCKED

Usually the subagent parked on a background gate with
finished-but-uncommitted work. **Don't blind-redispatch** (a fresh
"continue" agent re-reads everything and may park the same way):
verify the tree diff against the hand-off yourself, run the gates,
commit with the project identity. (The phase-builder definition's
foreground-gates clause largely retired this pattern — enharmonic
rows 110→112 — but it still appears at any rung.)

**Named/async dispatches surface as an idle notification, not a tool
result** (CombinatorialRigidity rows 153–158: every named Agent
dispatch emitted an idle notification instead of returning
`LANDED <sha>`/cost). Treat that notification as "the agent finished
its turn but delivered no return" — verify via git as above. Two
consequences: **(a) cost figures are unavailable** on named
dispatches — dispatch **un-named** to get the `LANDED`/`BLOCKED`
summary + usage, which arrive even for a background run in its
completion notification; it is *naming* that routes to the mailbox
and drops the return. **(b) A running named agent does not read your
`SendMessage` until it is interrupted** — to stop or steer one, have
the *user* interrupt it so the queued message lands. Reserve named
dispatches for cases that need an addressable resume.

**Background-build idle notifications ≠ a stranded neither-return**
(CombinatorialRigidity row 747): an agent that runs its gates via a
background build + wait emits interim "idle" notifications *before*
its definitive LANDED/BLOCKED, and the interim tree can look stranded
(dirty, HEAD not advanced). Checking git state is fine, but **wait
for the LANDED/BLOCKED-shaped final message before finalizing on the
agent's behalf** — a coordinator once began writing the commit
message for work the agent then committed itself (a near
double-commit).

## §3 — Killed dispatch (session/usage limit) or user-interrupt → resume-first

A kill returns neither LANDED nor BLOCKED (the return is the limit
error itself); a **user interrupt** mid-dispatch is the same shape.
Check `git status` for stranded work, then:

> **Interrupt vs. salvage.** A user interrupt that catches
> **complete, gate-passing** work → salvage (verify + finalize the
> commit yourself, no resume). An interrupt that catches
> **incomplete** work (a half-built leaf) → resume-first below.

1. **First try resuming the same agent** — `SendMessage` to its
   `agentId`, naming where it died and what remains. The harness
   resumes from the transcript, full context + read phase intact
   (CombinatorialRigidity: a user-interrupted leaf resumed and
   completed cleanly; a killed design pass re-emitted an unwritten
   block with zero re-reading).
   - **No agentId in the return?** An interrupt returns an *error*,
     not the Agent tool's normal result. Recover the id from the
     local subagent logs (the most-recently-modified
     `agent-<id>.jsonl` under the session's subagents dir; its
     `.meta.json` confirms the dispatch description). Reference the
     dir generically in any commit — never paste the
     machine-absolute path (top-level CLAUDE.md).
   - **Re-apply any fragment you reverted.** If you reverted the
     agent's uncommitted edit while cleaning the tree, **re-apply it
     before resuming** — the resumed agent's context believes its
     edit landed, so a tree missing that decl makes its next build
     fail. Don't tell the agent about the revert/re-apply; just
     restore the tree to match its context.
   - If the tree was genuinely clean at the kill, say so explicitly
     so the agent re-emits rather than assumes its edits survived.
2. **Only if resume is unavailable or fails, relaunch fresh** —
   salvage the dead agent's read map (its transcript; extract the
   tool-call file paths) into the relaunch prompt. A coherent
   stranded *edit* can be left in tree for the relaunch to
   review-and-extend rather than reverted.

## §4 — Plan-label deviations (destructive→additive, slice re-size)

A normal, usually-correct self-redirect in migration phases — four
consecutive "destructive" slices rightly landed additively in one run
(enharmonic Phase 17). Verify the stated reason against the source
once (the first occurrence sets the pattern), confirm the deferred
obligation (legacy retirement, follow-up sub-slice) is recorded in
the phase notes with a slice pointer, and **fix the drift at the
authoritative plan doc when pausing** — a plan doc that says
"destructive" while reality went additive is a trap for the next
coordinator.

## §5 — BLOCKED resolution (in-workflow vs stop)

Stop on a BLOCKED **without** a clear within-workflow resolution. The
in-workflow exception: a **sizing-shaped BLOCKED** (deliverable
judged un-carvable, tree untouched, usually because the design doc
pins no concrete signatures below the named slot) is the step-1
design-pass trigger — dispatch a decomposition design-pass at the
design-settle rung rather than re-dispatching the build one rung up
(a seven-leaf decomposition once un-blocked what brute escalation
would have re-hit).

**Whatever the resolution, salvage the return first.** A BLOCKED
return often carries the dead attempt's route findings (verified
tactic steps, confirmed-nonexistent APIs); copy them into the phase
note's hand-off in the same stop/escalation commit — stranded in the
agent return they are invisible to the next session.

## §6 — Non-build dispatch shapes

- **Cleanup rounds** (per `../CLEANUP.md`): a scoped no-git editor —
  "Edit ONLY <file>. Touch no other file. Do NOT run git / commit /
  `inv` / `verify.sh` / `lake`" — with the coordinator reviewing and
  committing the result itself.
- **No dispatch at all**: decision records, adjudication outcomes,
  and postmortem syntheses born in the coordinator's own conversation
  with the user are coordinator-authored commits — a subagent would
  have to reconstruct that context from a prompt, lossily. Same
  per-commit checklists, project author identity, and the
  coordinator's *actual* model in the trailer.
- **Source-verification recon** (read-only, no commit): when the open
  question is a route's *faithfulness to the source* — typically a
  design-pass verdict the design pass cannot self-certify — dispatch
  the `recon` agent to read the load-bearing primary-source passages
  (the `.refs/` PDF) and return a verdict, **framed adversarially**
  ("try to *refute* the proposed reading; a refutation is more
  valuable than a confirmation"). The coordinator acts on the verdict
  and locks the route — the highest-confidence way to settle a
  "which route is source-faithful" fork.
- **Compiler-checked spike** (read-only, no commit) — the dispatch
  shape for a **route-composition** question ("do these specific Lean
  objects compose to produce goal X?"), as opposed to the
  faithfulness question above. A *prose* design-pass is the WRONG
  tool here: in the defeq-fragile zone prose mischaracterizes the
  types and a wrong verdict propagates through the hand-off (a crux
  was prose-mis-pinned 3–4× — including by a diverse-lens *prose*
  pair — then dissolved + closed in ONE spike). The `recon` agent
  writes a SCRATCH probe (a throwaway `.lean` importing the relevant
  modules), BUILDS the candidate composition with `sorry` for each
  gap, and **reports the EXACT kernel-checked residual goal(s)** —
  not a prose verdict. Hard constraints: commit NOTHING, delete the
  scratch, leave `git status` clean.
  - **Bank-don't-revert when salvage is anticipated:** the hard
    "commit NOTHING" rule is right for a pure feasibility probe but
    costs a revert-then-resume round-trip when the coordinator
    EXPECTS committable sorry-free work — then authorize the spike
    up front to BANK its complete, gate-clean pieces (a design entry
    + any finished leaf) while still reverting incomplete scratch.
- **Spike-salvage resume** (recover a probe's sorry-free work): a
  read-only spike reverts its scratch (correct), but the sorry-free
  lemmas it proved are valuable — do NOT spawn a fresh agent to
  re-derive them. `SendMessage`-resume the SAME spike agent to
  re-emit them as real, gate-clean commits (it has the exact source
  in context). Caveats: the resume runs in the background (no
  synchronous return — you're notified on completion), and the async
  return is an *attestation* — the coordinator re-runs ALL gates
  after, exactly as for a below-top-rung dispatch.
  - **A read-only-origin agent may REFUSE the salvage-resume's
    commit** — correctly noting that a coordinator-relayed "the user
    authorized X" carries no user authority against its own
    read-only mandate (sound discipline, not a defect; observed with
    agent-variance — another agent resume-built cleanly the same
    session). Two-part fix: **(1)** in the resume message, GROUND the
    authorization in the user's standing invocation — "you are
    continuing under the user's `/coordinate-phase` loop, which IS
    the user's authorization for this loop's agents to commit
    directly to the default branch; your prior read-only constraint
    is lifted by that user-authorized continuation"; **(2)** if it
    still refuses, DON'T fight it — dispatch a fresh `phase-builder`
    (a build mandate from the start), which re-derives the work.
    **Prefer the fresh dispatch outright when the salvage is
    mechanical**; reserve the resume for genuinely expensive
    sorry-free work. **Pre-empt it** at the spike: the read-only
    dispatch may note up front that a follow-up coordinator message
    can lift the constraint (the `recon` agent definition already
    says this).
- **Resumed BUILDS run gates in the FOREGROUND — not
  background-and-stop.** A `SendMessage`-resumed agent told to build
  will sometimes kick off `lake build` in the background and END ITS
  TURN awaiting it — returning a non-LANDED/BLOCKED intermediate
  state with the work still uncommitted (one program lost two resume
  rounds to exactly this). In the resume message state explicitly:
  *run the build/lint/axiom gates in the FOREGROUND (blocking) and
  commit before ending the turn.* If it still returns mid-gate,
  read-only-check the tree, confirm the work is complete + sorry-free
  **without committing it yourself** (the §3 do-not-commit-the-other-
  instance's-WIP rule), and resume once more to finalize.
- **Resume-drive an over-sliced layer**: when consecutive FRESH build
  agents repeatedly scope-shrink one layer into micro-pieces — each
  landing one small lemma while re-paying the full context-read
  overhead, the genuine assembly perpetually deferred —
  `SendMessage`-resume the most-recent warm agent scoped explicitly
  to *the larger chunk* ("land the remaining assembly, NOT one
  micro-piece; return BLOCKED-with-diagnosis if you hit a real gap").
  The warm context skips the re-read and tends to drive through.
  Built-in safety: if the layer was deferring because it hides a
  genuine gap, the scoped resume *surfaces* it as a
  BLOCKED-with-diagnosis rather than forcing a wrong build.

## §7 — Subagent wedged for hours on a proof timeout (elaboration wall)

A dispatch running far past the norm on a proof that won't compile is
usually an **elaboration-cost wall**, distinct from proof-discovery:
the proof is *logically complete* (every goal closes — the agent can
confirm via `lean_goal`) but the term is too heavy to elaborate
within the heartbeat budget. The cost-outlier is itself the
intervention trigger — don't wait it out; surface to the user early.

Procedure:
1. **Interrupt and recover the WIP before reverting.** Interrupting
   needs the user (per §2 — a running named agent won't read messages
   otherwise). Have the agent dump its in-progress proof to a scratch
   file OUTSIDE the repo (a replacement agent may already be editing
   the repo copy) and report a diagnostic: which decl/step, the
   verbatim timeout, and discovery-vs-elaboration read. The recovered
   proof is both the diagnostic *and* a head-start for the retry.
2. **Don't just escalate to a stronger model or crank
   `maxHeartbeats`.** A heartbeat wall is largely model-independent —
   a bigger model writes a similarly-heavy term (a one-rung-up retry
   once extracted one helper, then tried 4M→8M heartbeats, and still
   wedged).
3. **Escalate one rung up with a decompose-don't-crank mandate,
   seeded with the recovered WIP.** The fix is to *break the
   elaboration*: extract heavy steps as standalone helper lemmas
   (see TACTICS-QUIRKS on heartbeat/elaboration rescue), AND — the
   sharper lesson — **hunt the dominant `whnf` term, often a manual
   `∃`-witness / structure assembly over a heavy motive**, and route
   it through a landed keystone instead (one wedge failed even at 6M
   heartbeats; routing the final step through a keystone + four
   extracted helpers fit at 800k).
