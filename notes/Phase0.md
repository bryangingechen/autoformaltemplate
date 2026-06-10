# Phase 0 — Detailed informal blueprint (work log)

**Status:** planning.

Phase 0 writes the project's **entire informal blueprint** before
any Lean lands: every chapter under `blueprint/src/chapter/`, with
full statements, prose proofs, and `\uses{...}` dep edges — but no
`\lean{...}` pointers and no `\leanok` ticks. The dep-graph renders
all-red on first build because the red nodes *are* the to-do list
for the Lean phases. Once Phase 0 closes, each per-phase ROADMAP
section lists **blueprint node labels** (`def:foo`, `lem:foo`,
`thm:foo`), not speculative Lean lemma names; the default
granularity is **one Lean source file per phase**; and the
phase-completion bar for every later phase is *the listed nodes
acquire `\lean{...}` + `\leanok`, the corresponding Lean
declarations land, and `blueprint/verify.sh` stays green*.

## Current state

<one-paragraph: lead with the next concrete chapter/section to
write; then which chapters have landed and which are mid-stream.>

## Architectural choices made up front

<Tentative representation choices (types, parameterizations,
encodings) the blueprint will be written against. Record each in
`DESIGN.md` § *Choices to revisit* with an explicit revisit
trigger — the first Lean phases can re-litigate if implementation
surfaces friction.>

## Lemma checklist

Phase 0's checklist items are chapters, not lemmas: one chapter per
planned Lean phase set (multiple phases may share a chapter). Each
chapter is "done" once it has statements + prose proofs +
`\uses{...}` dep edges connecting into the upstream chapters; no
`\lean{...}` or `\leanok` at this stage.

- [ ] `chapter/intro.tex` — headline theorem statement, phase plan,
  forward-mode reading note.
- [ ] `chapter/<name>.tex` — <scope: which definitions / lemmas /
  theorems, and which planned Lean phases it covers>
- [ ] `chapter/<name>.tex` — …

## Blockers / open questions

- …

## Hand-off / next phase

<At phase close: confirm the dep-graph is a single connected
component sinking on the headline theorem(s); record the
phase ↔ blueprint-target inventory (one row per planned Lean file,
listing its blueprint node labels and chapter); sharpen the ROADMAP
§§1–N phase sections from the blueprint pointers; then name
Phase 1's first concrete commit.>

## Decisions made during this phase

<Keep shorter than the forward sections above; ≤ 8 lines per entry.
Typical Phase 0 entries: chapter/phase boundary choices, theorem
naming, parameterization decisions, dep-edge reroutes that avoid
forward references, mirror candidates surfaced for later phases.>
