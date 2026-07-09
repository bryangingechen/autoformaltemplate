# notes/CLAUDE.md — agent operating manual for project notes

This file is the **agent-facing operating manual** for working in
`notes/`. It auto-loads when an agent reads any file under this
directory — typically `notes/PhaseN.md` at session start (per the
top-level `CLAUDE.md` Starting checklist).

Top-level `CLAUDE.md` covers project-wide process (reading order,
hand-off contract, citations, project history). This file carries
the discipline for the work logs themselves: phase notes,
`FRICTION.md`, and `PERFORMANCE.md`.

For the Lean-side companion (friction review, build/lint gates),
see `{{PROJECT_NAME}}/CLAUDE.md`. The friction
review writes to `FRICTION.md`, which lives here; the discipline for
*editing* friction entries is on the Lean side, but the discipline
for *organizing* this directory is here.

## Files in this directory

- **`PhaseN.md`** (one per phase, N = 0, 1, 2, …) — phase work logs.
- **`PhaseN-<subtheorem>.md`** — per-sub-theorem split of a phase's
  work log, opened when the parent log overshoots structurally (see
  *Notes-size signals* below). The parent `PhaseN.md` compresses to
  a thin overview pointing at the per-sub-theorem logs; each
  sibling carries its slice of *Current state* + *Lemma checklist*
  + *Decisions made* + *Hand-off*, optionally with a framing
  preamble noting which sub-theorem boundary it covers. Default for
  short / single-sub-theorem phases is *no split* — a flat
  `PhaseN.md` is fine.
- **`PhaseN-cleanup.md`** — between-phases or post-phase cleanup-
  round work log. Format and discipline in `CLEANUP.md`; opened
  lazily when a cleanup round starts.
- **`<topic>-design.md`** — design-recon doc: a decision-support
  log for an open design question that spans commits (which
  representation, which proof route, is this producer
  constructible). Append-only *during* the recon; once a recon's
  verdict lands in `PhaseN.md`, compress the closed arc to a
  ≤3-line verdict + pointer. Not a second copy of the phase note's
  *Decisions made*.
- **`<program>.md`** — program-map doc for a multi-phase program:
  phase table, reuse map, and a risk register; per-phase entries
  stay 1-paragraph-max and point at `PhaseN.md`.
- **`<topic>.md` deferred-plan docs** — a paused cross-phase plan
  keeps its own note with an explicit *Deferral* section naming the
  resume criteria; same editing discipline as phase notes.
- **`next-phases.md`** — proposed-phase queue, the between-phases
  stand-in for the active phase note (top-level `CLAUDE.md`
  *hand-off contract*). One section per proposed phase (scope, why
  now, entry criteria), ordered; ROADMAP's *Next phases (proposed)*
  subsection points here. Created lazily when the first phase
  proposal outlives the phase that spawned it; a section graduates
  into `notes/PhaseN.md` + a ROADMAP row when its phase opens.
- **`FRICTION.md`** — active friction log: open items, anti-patterns,
  mirrored upstream-eligible lemmas. File format and filing rule
  in the file's own header. Recognized entry tags include
  `[process]` and `[blueprint]` for process / blueprint dead-end
  post-mortems (the entries DESIGN.md cross-references), alongside
  the API/tactic tags. Created lazily once the first entry
  appears; do not pre-populate.
- **`FRICTION-archive.md`** — resolved project-internal entries
  (design history; search-target only, not read-on-load). Created
  lazily once entries migrate from `FRICTION.md`.
- **`PERFORMANCE.md`** — performance investigations and structural
  options (Lean module system, import boundaries). Its own header
  explains the format. Created lazily.
- **`model-experiment-protocol.md` / `model-experiment.md`** — the
  model-tier dispatch experiment (which subagent model rung per
  task). The protocol file is portable — keep it byte-identical
  across participating repos; the log file is repo-local (config +
  dispatch log + findings); see `model-experiment.md` Status
  line — it is the single home for arm-or-delete instructions
  and gates `.claude/commands/coordinate-phase.md`.

## One canonical home per content type

Every piece of content has **one** home; every other mention is a
pointer. This is the rule that stops the same paragraph being written
3–5 times across the doc set (and re-synced on every edit). It bites
hardest in multi-phase programs, where a single phase can otherwise
appear in five places at once.

| Content | Canonical home | Everywhere else |
|---|---|---|
| At-a-glance status | ROADMAP *Status* table cell | thin pointer only (status + ≤1 clause + `see notes/PhaseN.md`) |
| One-paragraph phase summary | ROADMAP *Phase plan* §N prose | — |
| Phase working detail (lemma map, decisions, hand-off) | `notes/PhaseN.md` | — |
| Program-level map (phase table, reuse map, risk register) | `notes/<program>.md` (for multi-phase programs) | per-phase entries 1-paragraph-max → point at §N / `PhaseN.md` |
| Live design recon (decision-support) | `notes/<topic>-design.md` | once a recon's verdict lands in `PhaseN.md`, compress the arc to a ≤3-line verdict + pointer |
| Cross-cutting lesson / idiom / rationale | `TACTICS-GOLF.md` / `TACTICS-QUIRKS.md` / `DESIGN.md` | one-line *Promoted to …* pointer in `PhaseN.md` |

## Phase notes

`notes/PhaseN.md` is a working log, not an essay. The hand-off
contract holds only if the file stays scannable.

- **One-screen-per-entry rule.** Each "Decisions made" entry runs at
  most ~8 lines. If you find yourself writing more, the
  implementation specifics are leaking in; lift them to FRICTION
  (project-internal idioms or mirror lemmas) or TACTICS-GOLF /
  TACTICS-QUIRKS (cross-cutting workflow rules) and replace the
  Phase entry with a one-line pointer. The decision + short
  rationale stay; the *how* lives elsewhere.
- **Don't duplicate FRICTION explanations.** When a decision has both
  a Phase entry and a FRICTION entry, the Phase entry is a pointer;
  the explanation lives in FRICTION. One source of truth.
- **Superseded reasoning leaves the live note.** When a recon's verdict
  is overturned, *delete* the dead section — don't keep a "verdict
  SUPERSEDED by …" or "retained for the audit trail" block in a
  read-on-load `PhaseN.md`. The commit that made the call is the audit
  trail (git history); the *Decisions made* entry records the final
  verdict in ≤8 lines. If the dead end carries a reusable lesson (why
  the route failed), lift that one-liner to FRICTION/DESIGN — the
  blow-by-blow does not stay. A `PhaseN.md` reads as the *current* state
  of the argument, not its changelog.
- **Sub-organize "Decisions made" for non-trivial phases.** If a phase
  has multiple cleanup passes or many small refactors, split the
  section into:
  - *Phase-local choices and proof techniques* — full entries (still
    ≤ 8 lines each).
  - *Promoted to TACTICS-GOLF / TACTICS-QUIRKS / FRICTION / DESIGN*
    — one-line pointers, no explanation. The cross-reference carries
    the content.
  - *Cleanup pass summaries* — list of changes by file with
    cross-references, not explanations.

  For small phases, a flat list under "Decisions made" is fine.
- **Forward-weighted note — a composition ratio, not a line budget.** A
  phase note is working memory for the *next* chunk, not an archive, so
  its **forward** part (the *Current state* next step, open `[ ]`
  checklist items, *Blockers*, *Hand-off*) must outweigh its **finished**
  part (*Decisions made*, done-item notes). There is **no absolute line
  budget** — a 25-commit phase may run long if its forward part is
  genuinely large; a winding-down phase must shrink as its forward part
  does. The gate is the ratio: **if *Decisions made* outgrows the forward
  sections, the finished log has gone stale** — *promote* its
  cross-cutting entries (*Promoted to …*) and *collapse* the rest to
  one-line verdicts (decision + Lean name; the reasoning is in git / the
  blueprint / the Lean source). A settled decision keeps full ≤8-line
  prose only while upcoming work might lean on or contradict it. Enforce
  **per-commit** (top-level `CLAUDE.md` *Before each commit → Compress
  in-commit*): if a commit tips finished past forward, rebalance in that
  commit — deferring just re-incurs the write-verbose / re-read /
  re-compress waste (observed in practice: routine ~50% end-of-phase
  compression passes before the per-commit gate existed). Two fixed
  backstops survive the move off line-budgets: each *Decisions made*
  entry stays ≤8 lines, and a note **past ~500 lines is a tripwire** —
  almost always a swallowed promotion; stop and investigate, don't just
  trim. *At phase close* the note becomes the compressed archive
  ROADMAP §N points at: forward shrinks to the next-phase hand-off,
  and *Decisions made* settles as a mostly one-line verdict record.

### Template for `notes/PhaseN.md`

When starting a phase, seed the file with sections like:

```markdown
# Phase N — <name> (work log)

**Status:** in progress.

## Current state
<one-paragraph: lead with the next concrete step; then what's done /
what's mid-stream. This + the sections below it are the *forward* part
the note is weighted toward.>

## Architectural choices made up front
<optional; phase-start design decisions. Cross-cutting ones go in DESIGN.md.>

## Lemma checklist
- [x] `lemma_a` — done
- [ ] `lemma_b` — in progress; blocked on …
- [ ] `lemma_c`

## Blockers / open questions
- …

## Hand-off / next phase
<the next concrete commit that moves work forward (the smallest one, not
the target theorem); at phase close, what unlocks the next phase>

## Decisions made during this phase

<The finished-work tail — keep it **shorter than the forward sections
above** (*Forward-weighted note*); promote cross-cutting entries and
one-line settled ones as they age. For small phases a flat list is fine;
for phases with cleanup passes or many refactors, sub-organize as below.>

### Phase-local choices and proof techniques
- <decision + rationale, ≤ 8 lines per entry>

### Promoted to TACTICS-GOLF / TACTICS-QUIRKS / FRICTION / DESIGN
- *<lesson>* → TACTICS-GOLF § N / TACTICS-QUIRKS § N / FRICTION [tag] *<entry title>* / DESIGN.md *<section>*

### Cleanup pass summaries
<optional; per-file effect of any cleanup pass, with cross-references>
```

## Notes-size signals (in-phase split triggers)

A `notes/PhaseN.md` approaching **~1000 lines** is far past the
~500-line tripwire from *Forward-weighted note* and is unlikely to
compress purely by lifting cross-cutting lessons through *Promoted
to …*. (Observed in practice: an ancestor project let a phase log
reach 3700+ lines before noticing it was past the point where
compression in place could work.)

**Trigger.** When the active phase log crosses ~1000 lines, **pause
before adding the next *Decisions made* entry or *Current state*
update** and diagnose:

- If the overshoot is *density* — *Decisions made* entries past the
  ≤ 8-line per-entry rule, cross-cutting lessons never lifted to
  TACTICS-GOLF / TACTICS-QUIRKS / FRICTION / DESIGN, *Current
  state* prose duplicating commit messages — the compression
  options under *Phase notes* still apply, and the right response
  is a single compression commit (lift, compress, retire commit-
  by-commit prose), not a split.
- If the overshoot is *structural* — the phase covers multiple
  blueprint sub-theorems with their own decision trails — open a
  per-sub-theorem split in the same commit as the decision that
  would have pushed the log past 1000. The parent `PhaseN.md`
  compresses to a thin overview pointing at the
  `PhaseN-<subtheorem>.md` siblings (file-type description under
  *Files in this directory* above).

The cost of a mid-phase split or compression is one careful commit;
the cost of a post-phase notes restructure is a cleanup-round task
that can run across sessions. The asymmetry is the whole reason for
the trigger.

**Lean-side companion.** `../{{PROJECT_NAME}}/CLAUDE.md` *File-size
signals (in-phase structural triggers)* carries the parallel rule
for the Lean phase file (the ~2000-line / ~40-decl trigger that
opens a sibling exposition file or a mirror module); the rules fire
together when a phase is genuinely large enough that both the work
log and the Lean file warrant a mid-phase split.
