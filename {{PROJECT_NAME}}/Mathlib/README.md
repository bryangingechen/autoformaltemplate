# `{{PROJECT_NAME}}/Mathlib/` — upstreaming holding pen

Files under this directory mirror mathlib's path structure exactly and
hold lemmas that the project found mathlib should have. Each mirrored
lemma is upstream-eligible (a fact about `SimpleGraph`, `Set.ncard`,
`Finset`, etc., not specific to this project's mathematical content)
and is staged here so it can be ported to mathlib as a copy-paste PR.

## Conventions

- **Lean namespace stays the upstream one** (`Set`, `SimpleGraph`,
  `Finset`, etc.). The mirror file imports the upstream module and
  adds alongside it.
- **File path mirrors the upstream path exactly.** A future
  upstream PR is then a literal copy of the lemma's file path.
  Example: a lemma about `Set.ncard_diff_singleton_of_mem` goes in
  `{{PROJECT_NAME}}/Mathlib/Data/Set/Card.lean`.
- **Each mirrored lemma also gets a `[mirrored]` entry in
  `notes/FRICTION.md`** so the upstreaming queue stays surveyable.

See `TACTICS-GOLF.md` *Mirror-first rule* for the full discipline.

This directory starts empty and is created lazily — add files only
when a real upstream-eligible lemma surfaces.
