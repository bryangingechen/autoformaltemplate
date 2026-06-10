# {{PROJECT_TITLE}}

[![Build & deploy site](https://github.com/{{GITHUB_USER}}/{{project-name}}/actions/workflows/push.yml/badge.svg)](https://github.com/{{GITHUB_USER}}/{{project-name}}/actions/workflows/push.yml)

{{ONE_LINE_BLURB}}

<!-- Replace the line above with a one- or two-sentence project
description. Add follow-up paragraphs naming the headline theorem
and the proof route the project will follow. -->

## Links

* [Project website](https://{{GITHUB_USER}}.github.io/{{project-name}}/)
* [Blueprint (web)](https://{{GITHUB_USER}}.github.io/{{project-name}}/blueprint/)
* [Blueprint (PDF)](https://{{GITHUB_USER}}.github.io/{{project-name}}/blueprint.pdf)
* [Dependency graph](https://{{GITHUB_USER}}.github.io/{{project-name}}/blueprint/dep_graph_document.html)
* [API documentation](https://{{GITHUB_USER}}.github.io/{{project-name}}/docs/)

## Project status

<!-- One bullet per phase, with status and headline result. Example:
* **Phase 1 (complete)** — short description and the headline lemma
  name.
* **Phase 2 (in progress)** — what's mid-stream and what's next.
-->

TODO: project status bullets.

See `ROADMAP.md` for the canonical hand-off doc — directory layout, status,
mathematical plan, and engineering conventions. `DESIGN.md` carries
cross-cutting design rationale; `TACTICS-GOLF.md` carries idiom / golfing
guidance and `TACTICS-QUIRKS.md` covers build-failure rescue.
Per-phase work logs live under `notes/`.

`CLAUDE.md` is the operating manual for AI coding agents (Claude Code et al.)
— it covers reading order, the per-session workflow, the end-of-session
friction review, and the `notes/PhaseN.md` template. Human contributors can
skim it but the primary audience is automated tooling.

## Metadata

Sources, status, automation setup, and fidelity notes for this
formalization are recorded in [`formalization.yaml`](formalization.yaml),
following the
[formalization.yaml](https://github.com/mathlib-initiative/formalization.yaml)
self-reporting schema. It is kept current at phase boundaries (see
`CLAUDE.md`).

## Build

```
lake exe cache get   # fetch precompiled mathlib oleans (optional but fast)
lake build
```

Lean toolchain version is pinned in `lean-toolchain` and tracks mathlib.

## Blueprint

The mathematical blueprint lives under `blueprint/`. The web and PDF
versions are built and deployed automatically by GitHub Actions on every
push to `master` (see `.github/workflows/push.yml`); to build it locally:

```sh
cd blueprint
pip install -r requirements.txt
inv web     # plastex output in blueprint/web/
inv bp      # PDF in blueprint/print/print.pdf
inv serve   # preview the web build at http://localhost:8000
```

The landing page source is in `home_page/`. Its `_config.yml` and the CI
workflow assume the GitHub Pages site is published at
`https://{{GITHUB_USER}}.github.io/{{project-name}}/`; if the repo is
ever renamed or moved to a different owner, update both files together.

## Automation

- **`.github/workflows/hopscotch.yml`** — daily cron that tries to
  advance the mathlib pin in `lake-manifest.json` to mathlib's current
  `master`. Opens (or refreshes) a PR if the new commit builds; opens
  a tracking issue with the bisected breaking commit if not.
- **`.github/dependabot.yml`** — monthly grouped PR bumping any
  GitHub Actions used in `.github/workflows/`.
