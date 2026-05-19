# notes/CLAUDE.md — agent operating manual for project notes

This file is the **agent-facing operating manual** for working in
`notes/`. It auto-loads when an agent reads any file under this
directory — typically `notes/PhaseN.md` at session start (per the
top-level `CLAUDE.md` Starting checklist).

Top-level `CLAUDE.md` covers project-wide process (reading order,
hand-off contract, citations, project history). This file carries
the discipline for the work logs themselves: phase notes,
`FRICTION.md`, and `PERFORMANCE.md`.

For the Lean-side companion (friction review, build/lint gates,
quirks index), see `{{PROJECT_NAME}}/CLAUDE.md`. The friction
review writes to `FRICTION.md`, which lives here; the discipline for
*editing* friction entries is on the Lean side, but the discipline
for *organizing* this directory is here.

## Files in this directory

- **`PhaseN.md`** (one per phase, N = 1, 2, …) — phase work logs.
- **`FRICTION.md`** — active friction log: open items, anti-patterns,
  mirrored upstream-eligible lemmas. File format and filing rule
  in the file's own header. Created lazily once the first entry
  appears; do not pre-populate.
- **`FRICTION-archive.md`** — resolved project-internal entries
  (design history; search-target only, not read-on-load). Created
  lazily once entries migrate from `FRICTION.md`.
- **`PERFORMANCE.md`** — performance investigations and structural
  options (Lean module system, import boundaries). Its own header
  explains the format. Created lazily.

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
- **Soft length budget, adaptive to phase size.** A short phase
  (5–10 forward-work commits) should sit near 100–200 lines; a long
  phase (20+ forward-work commits, multiple substantive subsystems)
  may legitimately need 350–450. The right test is **density**, not
  absolute LoC: each *Decisions made* entry still respects the ≤8-line
  per-entry rule above, cross-cutting lessons are still lifted via
  *Promoted to ...*, and the *Current state* + *Hand-off* sections
  still pass the hand-off contract from the top-level `CLAUDE.md`.
  If those hold and you're at 400 lines, the phase was genuinely big.
  If they don't and you're at 200 lines, the file is already drifting.
  If a phase looks like it's going to overshoot 500, that's the cue
  to investigate whether *Decisions* has accumulated content that
  should have been promoted.

### Template for `notes/PhaseN.md`

When starting a phase, seed the file with sections like:

```markdown
# Phase N — <name> (work log)

**Status:** in progress.

## Current state
<one-paragraph: what's done, what's mid-stream, what's the next concrete step>

## Architectural choices made up front
<optional; phase-start design decisions. Cross-cutting ones go in DESIGN.md.>

## Lemma checklist
- [x] `lemma_a` — done
- [ ] `lemma_b` — in progress; blocked on …
- [ ] `lemma_c`

## Decisions made during this phase

<For small phases, a flat list of bullets is fine. For phases with
cleanup passes or many small refactors, sub-organize as below.>

### Phase-local choices and proof techniques
- <decision + rationale, ≤ 8 lines per entry>

### Promoted to TACTICS-GOLF / TACTICS-QUIRKS / FRICTION / DESIGN
- *<lesson>* → TACTICS-GOLF § N / TACTICS-QUIRKS § N / FRICTION [tag] *<entry title>* / DESIGN.md *<section>*

### Cleanup pass summaries
<optional; per-file effect of any cleanup pass, with cross-references>

## Blockers / open questions
- …

## Hand-off / next phase
<written when the phase finishes; what unlocks the next phase>
```
