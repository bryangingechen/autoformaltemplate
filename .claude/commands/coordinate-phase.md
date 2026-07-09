Coordinate Phase $ARGUMENTS. Dispatch subagents one at a time; each one
does the next concrete commit per the existing workflow, then sanity-
check and dispatch the next. Stop when the phase closes or something
looks off.

**Rare / explicit-trigger detail lives in
`notes/coordinate-phase-rescue.md`, symptom-indexed** (mechanical
fixups, neither-return / async-mailbox dispatch mechanics,
killed-dispatch resume, plan-label deviations, BLOCKED resolution,
non-build dispatch shapes, elaboration-wall wedge). Consult it when a
trigger below points there (`→ rescue §N`); this body carries the
every-iteration core.

Setup: follow CLAUDE.md reading order, but read **only ROADMAP.md's
*Status* table** (to confirm the active phase) — NOT the full file:
its closed-phase §N prose is archival detail the coordinator never
needs pre-dispatch (the active phase's working detail is in
notes/Phase$ARGUMENTS.md + the blueprint dep-graph). Then read
notes/Phase$ARGUMENTS.md. Confirm `git status` is clean and the
leftmost active phase file builds green (per *Starting a Lean-touching
session* in {{PROJECT_NAME}}/CLAUDE.md). Run the loop in the
foreground of this session only — never backgrounded or forked: two
instances sharing one working tree have ended with one committing the
other's half-validated uncommitted work.

Before the first dispatch, ask the user once whether this run modifies
these instructions — in practice users customize at session start,
typically lifting the 10-run cap and pre-authorizing the mechanical
fixups (rescue §1). Fold the **rung-availability confirmation** into
this same check-in: ask which model rungs (haiku / sonnet / opus /
fable) are dispatchable this session (default: all reachable) and fix
each unavailable rung's substitute up front per the playbook — do NOT
spend dispatches probing rungs. **This check BLOCKS the loop:** wait
for an actual user response before the first dispatch — a timed-out
question is not an answer; re-ask (or idle) rather than proceeding on
assumed defaults (a 60s timeout once had the coordinator carry over a
prior session's config, which the user's late answer then partially
reversed — CombinatorialRigidity 2026-07-02).

## Dispatch playbook

Standing guideline, distilled 2026-07 from the concluded two-repo
model-tier dispatch experiment (~890 rated dispatches across
CombinatorialRigidity + enharmonic; the full findings live in those
repos' `notes/model-experiment*` logs/archives). The headline: cheap-
rung failures concentrate in the **discipline / attestation layer,
essentially never in the mathematics**; the real risk locus is
**recons that settle new mirror math**, not builds; and the
coordinator's cheapest quality lever is **spec precision, not model
tier**.

### Rate the task: S/P/B, scored from the written hand-off

- **S — spec precision.** 1 = exact target signatures / file edits
  already written down; 2 = shape known, proof route or template
  named; 3 = requires design decisions ("decide X", novel API shape).
- **P — proof novelty.** 1 = mechanical (doc edits, restates,
  bridges, `rfl`-adjacent); 2 = real proof assembly along a known
  route with named grounding; 3 = novel proof route, search, or no
  informal proof written.
- **B — blast radius.** 1 = one file, additive; 2 = few files,
  bounded caller repair through known bridges; 3 = cross-cutting
  cascade, open-ended repair.

Rate from the *written* hand-off, not from optimism; a hand-off too
thin to rate is itself S=3 (or a hand-off-contract violation to fix
first). Three calibrations that repeatedly bit:

- *Docs-only is not automatically P=1*: prose describing an **unbuilt
  argument** (red-node proofs, deferred-route accounts) takes its P
  from the math content, P ≥ 2.
- *A "needs the X-variant of landed lemma Y" flag is P ≥ 2, usually
  P = 3* — it names a genuinely-new sibling, unless a grep confirms
  the variant already exists.
- *"Pure instantiation / bookkeeping — wire landed brick B into
  consumer C's slot" is P = 1 only when B's **conclusion** sits at
  the same object / framework level as C's actual slot binding* (not
  merely the same Lean type, and not merely that B exists) — read
  both before rating; a wrong-level brick hides a P=3 leaf.

### Pick the rung

| Profile | Rung |
|---|---|
| max(S,P,B) ≤ 2 (incl. all-1s) | sonnet |
| P=3 with S=1 and B≤2 (exact pinned signatures + named route) | sonnet |
| P=3 (with S≥2) or B=3 | opus |
| **Fragility-zone producer build** (repo-local list of defeq-fragile / heavy-elaboration files) | opus minimum, regardless of profile |
| S=3; phase-open / phase-close / design-settle; any recon settling **new mirror definitions with no upstream precedent** | top rung (fable); substitute opus when unavailable |

- **Haiku is not a mapped rung.** Its failure boundary is harness
  mechanics + gate honesty, not proof capability (fabricated gates, a
  hallucinated `lake build --update` OOM incident), and the
  verification tax it forces cancels its savings. Use it only as a
  deliberate probe on a tightly-pinned single-edit task, with every
  gate re-run by the coordinator.
- **Read-only recon / research dispatches fall outside the axes**
  (they measure question stakes, not commit risk): default opus;
  top rung when the verdict re-routes a phase, adjudicates a carried-
  hypothesis / motive change, or settles new mirror math.
- **Post-recon downgrade.** Once a top-rung recon has settled exact
  signatures, the transcription leaves rate as written (usually
  sonnet) — the faithfulness risk lives in the recon, not the
  transcription.
- **When torn between two scores, score lower** — the per-commit
  verification gate bounds the damage — but honor the fragility-zone
  floor.
- **Unavailable rung → nearest available rung at or above the mapped
  one**; never substitute a weaker rung for a stronger mapped target.
  Fix substitutions once, at the session-start check-in.

### Raising S is the coordinator's cost lever

To move a task down-rung, sharpen the *committed* hand-off — paste
the exact target signatures, file pointers, and route into the phase
note / design doc — so S genuinely drops to 1. A ~30-minute
coordinator **slot-trace** (read the consumer's actual slot bindings
+ each brick's landed conclusion, write the exact wiring into the
hand-off) has repeatedly turned a would-be-BLOCKED P2 build into a
clean S=1 sonnet dispatch. Prefer this over per-dispatch prompt
padding: a hand-off edit raises S for every future rung and is
visible in git.

The coordinator MAY append short, named shaping blocks to the
invocation prompt when they carry **coordinator-verified information
only**: `route` (a verified proof route / named lemmas — P2 at
sonnet and all escalation retries), `scope-pin` (exact file list +
target signatures), `shape-anchor` (the primary-source page/wording
to anchor a recon against, plus a required compiler witness in the
deliverable), `hygiene` (tree-wide deleted-name checklist for
deletion/retirement slices). Shaping never changes the
LANDED/BLOCKED contract and never delegates the coordinator's own
verification to the subagent.

### Verification tiers (what the coordinator re-runs itself)

The step-4/5 checks below always run. On top of them, by rung:

- **top rung (fable/opus recons):** reasoning scrutiny per step 4 —
  the failure mode at these rungs is upstream plan/pin error, which
  gates can't catch.
- **below top rung (sonnet builds):** read the **full diff** (not
  `--stat`) before the next dispatch; re-run `lake lint`; sorry-grep
  the touched `.lean` files.
- **probe (haiku):** re-run every gate the return names; treat all
  attestations as unverified.
- **Escalation:** BLOCKED return or failed verification →
  re-dispatch the same task one rung up with the failed route named
  in the prompt; keep any landed commit, close the gap in the
  follow-up.

### Exception log

`notes/dispatch-log.md` records **exceptions only** — escalations,
probes, BLOCKED/killed/salvaged dispatches, gate-invisible defects
caught in verification, playbook deviations and their outcomes.
Routine clean dispatches are NOT logged (git history is the record;
per-dispatch logging cost more than it returned in the experiment —
its Notes column re-bloated three times despite prose rules). The
log's own header carries the row discipline (~600-char Notes cap;
tail-only append matching). Distill recurring lessons into the log's
*Findings* section and promote stable ones into this playbook /
CLAUDE.md at phase close.

## Loop

1. Note HEAD and re-read notes/Phase$ARGUMENTS.md "Hand-off / next
   phase" — that's what the next commit should accomplish. **If the
   phase log carries a "next concrete commit" pointer in *both*
   *Current state* and *Hand-off / next phase*, treat *Current state*
   as authoritative** — that is the one per-slice subagents reliably
   update; the Hand-off copy drifts stale (it lagged by up to two
   slices in one enharmonic sub-phase). When they disagree, reconcile
   (and collapse the duplicate to a thin pointer so it can't drift
   again). If the next step is **research-shaped** — any of:
   - the hand-off flags recon-before-build;
   - 2+ consecutive leaf commits have fed a hard core not yet built;
   - 3+ consecutive commits are thin wrappers aliasing existing facts;
   - the next step is a **retirement/cleanup slice that 3+ prior
     slices deferred obligations into** (enharmonic: 8 additive
     self-redirects piled a legacy surface into one slice; the recon
     decomposed it into 12 ordered sub-slices and surfaced pin debt
     that builds would have tripped over one at a time);
   - the hand-off says a step "needs the [X]-variant of [landed
     lemma Y]" and you cannot confirm that variant exists in tree
     (grep it — a missing variant is a hidden P≈3 prerequisite, not a
     "mechanical restate"); **conversely**, a claim that a fact is
     "only landed at the special case, needs generalizing" can be
     STALE — read the decl's ACTUAL signature before scoping a
     generalization build (a load-bearing "X is only at the special
     case" claim is a recon trigger until the signature confirms it);
   - the hand-off says "re-express / re-prove existing decl X
     *through* landed lemma Y" and you have not confirmed Y's
     **conclusion shape** can produce X's (read X's landed conclusion
     first — a bound-shaped brick cannot yield an ∃-witness decl; a
     route between mismatched conclusion shapes is a design error to
     settle by recon, not a build);
   - the hand-off calls an assembly **"pure instantiation"** and you
     have not confirmed brick-conclusion vs consumer-slot **levels**
     (see the P-rating calibration above);
   - a **build agent's own hand-off flags the next piece as
     genuinely-new** ("the real new lemma", "the genuine open design
     call") — that flag IS the recon trigger: recon the **route**
     before building the chain's prerequisites, which may serve a
     route the recon then dissolves (two leaves once lifted
     dead-route machinery a recon retired a dispatch later);
   - a decomposition rates an **index-family match** between two
     differently-sized index sets as "latitude" / "`Fin` arithmetic"
     — that is a **structural contract requirement**: confirm the
     cardinalities coincide *by a stated contract fact* before
     accepting the rating (a contract recording two known-linked
     quantities without the linking hypothesis is a latent gap that
     surfaces at the first consumer);
   - **recurring walls:** the same obstruction defeats 2+
     *structurally-different* fix attempts → suspect the wall is
     intrinsic to a shared DOWNSTREAM object (a frozen contract, a
     slot-override, a motive), not the varied upstream choice; recon
     THAT object before authorizing a third re-targeting (the tell:
     each fix changes the *upstream* construction yet hits the *same*
     named obstruction)

   — then the next commit is a **recon / design-pass**, not a build:
   dispatch the `recon` agent (read-only verdict or a docs/blueprint
   design-pass commit that decomposes the core into buildable leaves
   with exact signatures). **Match the recon shape to the question:**
   a *prose* design-pass is right for a faithfulness / decomposition
   question, and WRONG for a **route-composition** question ("do
   these specific Lean objects compose to produce goal X?") in the
   defeq-fragile zone — there, dispatch a **compiler-checked spike**
   (rescue §6) that builds the candidate composition, `sorry`s the
   gaps, and reports the exact kernel-checked residual goals (a crux
   once prose-mis-pinned 3–4×, including by a diverse-lens prose
   pair, dissolved in ONE spike). Recon is this workflow's
   highest-leverage move; trigger it **early**, before the next leaf
   (one phase burned ~4 leaf commits on an undischargeable core; the
   2-leaf trigger is the floor).
2. **Rate S/P/B and pick the rung per the Dispatch playbook** (above);
   pass the rung as the Agent tool's `model` parameter. Honor any
   standing rung override from the session-start check-in.
   **Pre-dispatch derivation guard:** when the next leaf builds on a
   prior phase's mirror definition with no upstream precedent, spend
   the few minutes deriving the leaf's statement against the
   definition **body** — docstrings are not evidence — and witness
   any surprise with `lake env lean` before dispatching (this caught
   a faithfulness gap *before* any Lean was built on it, where three
   prior defects were each caught only after a landed commit). The
   guard extends to **transcribed proofs**: when a carrier / encoding
   decision is pinned, re-validate the transcribed proofs of the
   downstream nodes against the carrier (a recon is the cheap way) —
   a faithful *statement* can carry a proof that is false against the
   project's carrier. The rating step is the natural moment: you are
   already reading the hand-off's route.
3. Dispatch the Agent tool with `subagent_type: phase-builder`
   (routine build) or `recon` (step-1 recon / design-pass),
   **un-named** (do not pass `name` — an un-named dispatch delivers
   its LANDED/BLOCKED summary + cost figures, synchronously or in its
   completion notification; a *named* dispatch routes to the async
   mailbox and surfaces only an idle notification. Reserve names for
   an addressable resume, rescue §2). The agent definitions carry the
   fixed discipline; the invocation prompt carries only:
   - the task pointer: "Continue Phase $ARGUMENTS — do the next
     concrete commit per notes/Phase$ARGUMENTS.md 'Hand-off / next
     phase', then stop" (for a recon: the question, your verified
     findings motivating it, and the deliverable);
   - the dispatched model's display name for the trailer ("you are a
     <Model> agent, so the trailer is `Co-Authored-By: Claude <Model>
     <noreply@anthropic.com>`");
   - a **phase-open / phase-close** step gets a short prologue
     stating what is sanctioned (e.g. a user-adjudicated close shape
     — "closing now is sanctioned; do not re-litigate it") and what
     is out of scope ("the successor phase is NOT opened by this
     commit") — without it the agent must re-derive both, and either
     re-asking or over-reaching is bad;
   - optional playbook shaping blocks (coordinator-verified info
     only).

   Don't pad the routine prompt or pre-load files beyond that — the
   agent definition + CLAUDE.md auto-loads carry the discipline, and
   duplication invites drift.
4. Verify the return:
   - **Mechanics:** `git log --oneline -3`, `git show --stat HEAD`,
     `git branch --show-current`. HEAD advanced past the noted sha;
     still on the default branch; author matches the project's
     existing commits; diff matches what the hand-off pointed at. A
     docs/blueprint-only commit (recon, design pass, decomposition,
     re-scope) is normal in a research-shaped phase — judge against
     the hand-off, not against "must touch Lean". (Wrong branch /
     author / trailer → rescue §1: a fixup, not a stop.)
   - **"Gates green" is an attestation, not evidence.** The step-5
     gate always runs; apply the playbook's verification tier for the
     dispatched rung (full-diff read + `lake lint` + sorry-grep below
     top rung; everything re-run for a probe — a haiku once
     fabricated all three gates green).
   - **Sorry-grep the touched `.lean` files after every below-top-
     rung dispatch** regardless of what the return says — a LANDED
     return can omit a `sorry` the commit message discloses. Read the
     commit message body, not just the summary line. The converse
     also happens — **judge completeness from the diff, not the
     prose**: a post-compaction commit message can mis-describe
     *finished* work as partial, and the false belief propagates into
     the notes/blueprint; when message and diff disagree, trust the
     diff and repair the prose. A landed sorry is a failed
     verification → escalate per the playbook.
   - **Shape check:** when the hand-off pins the deliverable to a
     design verdict (a design-doc § pointer or named verdict), diff
     the landed statement against that section — motive strength,
     transport direction, consumed-vs-carried hypotheses.
     Mechanically clean commits have landed design-excluded shapes;
     only the section re-read caught them. A shape deviation = a
     corrective dispatch one rung up naming the verdict, never a
     discharge-on-top. Diff against the **pre-commit** design text
     (`git show <noted-sha>:notes/…`) — the builder edits the notes
     too, and a partially-delivered item can be rewritten to match
     what landed, silently dropping pinned sub-clauses. Same for
     **prose routes**: a red-node / deferred-route commit gets its
     route diffed against the canonical design § exactly like a Lean
     statement.
   - **Additive-successor check:** a slice that lands a unified
     successor for a node's existing declarations fails no gate when
     it skips the blueprint repin — confirm the superseded node's
     `\lean{...}` list gained the new name (or the repin debt is
     recorded), else the node silently pins only names scheduled for
     deletion (a recon caught one five slices later).
   - **Supersession-deletion check (the shape check's blind spot):**
     when the pinned verdict mandates **deleting or superseding** a
     decl, the shape check is incomplete until you confirm the decl
     is actually **gone — grep it**, and run the tree-wide
     deleted-name dual check (no *live* cross-reference survives in a
     surviving decl's docstring or a live mirror lemma; see the
     structural-edit gate in CLAUDE.md). A build that adds the
     replacement but leaves the superseded decl orphaned passes gates
     *and* the statement-shape check; the deviation is an *absence*.
     Subagents under-apply this reliably — the coordinator's dual
     check is the load-bearing backstop. Fix with a follow-up cleanup
     (delete + re-pin + reword stale prose), not a discharge-on-top.
   - **Recon verdicts get reasoning scrutiny, not just mechanics** —
     a mechanically clean recon can be wrong, and building on it
     re-incurs the churn it was meant to end. Scrutinize hardest a
     recon that **dissolves or re-routes** a gap: confirm every
     *other* carried obligation still closes under the new route (a
     re-route can orphan a hypothesis the old route silently
     supplied). A **new gap** is usually cheaply verifiable — check
     it against the primary source (`.refs/`, REFS.md) and/or a
     one-line Lean witness *before* re-planning. **A verdict resting
     on "the residual follows from / generalizes landed lemma X" is
     the COORDINATOR's to verify on acceptance:** open X's *actual*
     statement and confirm the residual's object matches before
     building on it (an accepted "generalizes X" claim was once false
     because X was landed for a narrower construction — caught only
     by the next build, after a dead leaf). **Scrutinize a pin's
     named OBJECTS, not just its cited API names** — a design pass
     can name the right vertex set but the wrong *construction*;
     open the landed `def`/`theorem` of every construction the pin
     references and confirm the pinned object **is** that
     construction. A **route claim a build agent records in its
     hand-off** ("the next step must …") is a recon verdict in
     disguise — verify it against what the design doc *actually*
     proposed before dispatching a build on it (one such hand-off
     re-proposed a design-rejected route a fresh coordinator would
     have re-walked). When the design doc itself defers a shape
     ("pin at the X moment"), that moment IS the next dispatch — a
     design-settle pass, not a build; and if a deferred route's
     correctness depends on a *not-yet-built consumer's* obligations,
     settle the route against the consumer (read the consumer's
     hypotheses), not the leaf — a leaf plus a same-task pair once
     both validated a route *as a lemma* that the producer then
     BLOCKED on. **Same for a leaf's carried PRECONDITIONS:** before
     building a pinned leaf+consumer split, confirm the leaf's
     carried hypotheses actually hold for the consumer's objects (a
     brick once demanded a subgraph hypothesis incompatible with the
     producer's construction, forcing an inline + a dead leaf).
   - **An abstraction that defers the crux as a hypothesis is not
     progress on the crux.** When a build takes a genuinely-new fact
     as a hypothesis rather than proving it, the hard step is
     **relocated to the caller, not done** — often a legitimate
     slice, but re-flag the relocated obligation in the hand-off and
     **rate the next dispatch by the deferred math, not the
     plumbing** (the tell: a fact the design doc called
     "genuinely-new" appearing as an `h…` argument of a landed lemma
     — grep it, confirm where it is discharged). Four sharpenings
     from one downstream program, each a distinct failure surface:
     - a deferred-hypothesis leaf can land clean, correct, and
       axiom-clean yet be **unsatisfiable for the actual consumer's
       object** — signature-match + gates + decl-existence all pass;
       only a **satisfiability trace against the consumer's actual
       object** catches it. Run the trace before landing the leaf,
       not at the consumer's build.
     - the trace must also hit a **kernel/architecture lemma's
       SHAPE**: a sound-but-too-strong-shaped kernel (e.g. a total
       partition / full-row-rank cert where the source states a
       subspace fact) costs the whole tower built on it — check the
       shape against the real object's *dimensions* at acceptance.
     - after a kernel is **reshaped to a weaker shape** (injection /
       `≤` / subset), check the feeder leaves don't re-impose the
       stronger one **through their proof APIs** (the tell: a leaf
       taking an `Equiv`/bijection where the consumer's signature
       takes a plain function/injection — instantiate the real index
       types and compare cardinalities).
     - a deferred GATE carried through a **cascade of GO spikes** is
       a red flag, not progress: each spike type-checks the gate-fed
       composition *vacuously* (the gate a free input). When a
       deferred gate survives >1 GO verdict, TRACE it to its producer
       and confirm the producer emits that exact object — the
       final source-the-gate build is otherwise the first real check
       (one cascade of five GO spikes hid a gate that turned out to
       be the exact negation of a landed perpendicularity fact).
   - **A large cost/size outlier is an early degradation signal.** A
     dispatch whose wall-time / tool-uses / diff-size runs far past
     the norm has usually *forced* a too-big task through — bloat,
     mid-proof `maxHeartbeats` resets, inlining instead of
     decomposing — rather than bailing per scope-to-fit. Scrutinize
     hardest (full warning scan, bloat/inline check) even when the
     agent attests green. For a correct-but-degraded artifact
     (compiles, axiom-clean, matches the pin): repair the warnings +
     flag a refactor — keep the correct math, don't accept the
     warnings, don't revert correct work. (Mid-dispatch, an
     hours-long wedge on one proof is the elaboration wall →
     rescue §7.)
   - **Attestation-before-evidence** — notes that pre-claim a gate
     result written before the run finished — is the same offense
     class as a fabricated gate claim even when the gate later
     passes: repair the prose and record it in the exception log.
   - Re-read the updated "Hand-off / next phase". (Returns with
     neither LANDED nor BLOCKED, killed dispatches, plan-label
     deviations → rescue §§2–4.)
5. If the commit changed any `.lean` file: `touch` the changed file(s)
   (cached modules don't re-emit warnings), then `lake build
   <the changed module(s)> 2>&1 | grep -E 'warning:|error:'` — build
   the module(s) the commit *touched* (the leftmost active phase
   file, **or a new file the commit added** — a new downstream file
   is rightmost, not "leftmost"), so warnings re-emit.
   **Warning-clean, not merely green** (a sorry'd skeleton once rode
   a green-but-warning build onto master). Red or warning-bearing →
   stop and surface. Skip for docs-only commits. (Run the gate in the
   foreground, or — if backgrounded to read the diff in parallel —
   **wait for its completion notification**; re-reading an unchanged
   background-output file is a wasted call.)
6. One sentence to the user: clean handoff, or the specific concern.
   Surface **phase-boundary decisions** — early close, sub-phase
   split, a change to what "phase close" means — with a concrete
   commit-count estimate rather than deciding unilaterally.
7. Stop and surface on any of:
   - ROADMAP Status shows Phase $ARGUMENTS closed (the subagent ran
     the phase-close checklist). For a **sub-lettered** phase,
     "closed" is the umbrella cell showing this sub-phase done + the
     next sub-phase named — the umbrella row STAYS in-progress; see
     `PHASE-BOUNDARIES.md`'s sub-phase-close carve-out. After a
     user-approved mid-session close-and-split, confirm with the user
     before resuming the loop on the successor phase.
   - BLOCKED return; or HEAD didn't advance — **but salvage the
     return's route findings into the hand-off first** (a reverted
     attempt's verified route map survives only if the coordinator
     moves it), and check for a within-workflow resolution before
     stopping (a sizing-shaped BLOCKED is the step-1 design-pass
     trigger, not a stop — rescue §5). **When the BLOCKED is an
     obstruction verdict that would force a contract / architecture /
     foundational-def re-shape STOP, run a compiler-checked DECISIVE
     recon — "does ANY non-X alternative route exist?" — BEFORE
     surfacing the STOP.** The coordinator's own prose obstruction-
     reasoning is as unreliable as a build agent's in the
     defeq-fragile zone (one coordinator leaned in prose toward a
     re-shape STOP that a decisive recon overturned — the dead end
     was on one path only). Confirmed-blocked AFTER the decisive
     recon → then surface, with estimates.
   - A recon flags a decision for **user adjudication** (e.g. a
     carried hypothesis or motive change) — present the options with
     estimates; don't pick unilaterally.
   - Suspicious diff: unexpectedly large, unrelated files, or the
     step-5 gate red.
   - The agreed run cap (default 10) reached since the user last
     checked in.

Other dispatch shapes — the **cleanup-round** scoped no-git editor,
the **no-dispatch** coordinator-authored commit (decision records,
adjudications, postmortems), the **source-verification recon**, the
**compiler-checked spike** and its salvage-resume — are in rescue §6.
