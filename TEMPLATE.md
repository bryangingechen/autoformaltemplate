# Template instantiation guide

This repo is a template scaffold for a Lean 4 / mathlib4 formalization
project with a leanblueprint setup. Use it as the starting point for a
new formalization experiment; run the rename script to instantiate it,
then start filling in real content.

## Quick start

```sh
# From a fresh clone of this template:
./scripts/rename.sh MyProjectName MyGitHubUser
```

The script:
1. Renames the `{{PROJECT_NAME}}/` directory and `{{PROJECT_NAME}}.lean`
   aggregator to your chosen name.
2. Sed-replaces `{{PROJECT_NAME}}`, `{{project-name}}`, `{{ProjectName}}`,
   `{{GITHUB_USER}}`, and the other placeholders across every tracked
   text file.
3. Strips template-only content: the "this is a template" banners at
   the top of `README.md` / `CLAUDE.md` and the workflow `if:` guards
   that make project CI skip on the un-instantiated template (see
   *Template-only content* below).
4. Deletes `.github/workflows/template-ci.yml`, the template repo's
   own smoke-test workflow.
5. Prints a next-step checklist.
6. Self-deletes.

## Placeholders the script replaces

| Placeholder | Form | Use sites |
|---|---|---|
| `{{PROJECT_NAME}}` | PascalCase, no spaces | Lakefile `name`, Lean lib name, Lean module names, directory name |
| `{{project-name}}` | kebab-case, lowercase | GitHub repo name, Pages URL, badge URLs |
| `{{ProjectName}}` | PascalCase | Currently same as `{{PROJECT_NAME}}` — included in case the project ever needs a distinct display-camel form |
| `{{PROJECT_TITLE}}` | Free-form title | README header, blueprint title, home_page title |
| `{{GITHUB_USER}}` | GitHub username or org | Repo / Pages URLs, badge URLs |
| `{{AUTHOR}}` | Author name | Blueprint `\author{}` |
| `{{ONE_LINE_BLURB}}` | One-sentence project description | README, home_page, ROADMAP |
| `{{THEOREM_NAME}}` | Headline theorem name | Blueprint intro |

The script derives the PascalCase / kebab-case forms from the first
argument; you only pass one project-name string.

## Template-only content and the meta-level CI

Some content should exist only while the repo is the un-instantiated
template: the banners at the top of `README.md` and `CLAUDE.md` that
tell visitors (and agents) they are looking at a template, and the
job-level `if:` guards in `push.yml` / `push_pr.yml` / `hopscotch.yml`
that make project CI skip here (the placeholder lakefile can't build,
so those workflows can only fail before instantiation). That content
is tagged with `template-only` markers — an HTML-comment begin/end
pair for blocks, a single-line marker token for the workflow guards —
and `rename.sh` strips all of it during instantiation. The exact
marker spellings are deliberately not written out in this file: the
strip pass also runs over TEMPLATE.md, and a stray literal marker here
would delete real prose. See the top of `README.md` and the sed
expressions in `scripts/rename.sh` for the spellings.

Because the project workflows skip on the template repo, the only CI
that runs here is `.github/workflows/template-ci.yml`. It smoke-tests
instantiation on every push / PR: runs `rename.sh TestProject
test-user` on the checkout, then fails if any script-owned placeholder
or `template-only` marker survives, the project directory was not
renamed, or any workflow file is left syntactically invalid YAML.
`rename.sh` deletes it at instantiation, so projects created from the
template never run it.

## Maintaining the template (sync sessions)

The template improves in both directions: process lessons land first
in the downstream project where they were paid for, then sync back
here; template-side improvements propagate out via re-sync prompts
run by agents *in* the downstream repos (give them read-only access
to this checkout, e.g. at `../autoformaltemplate`). A sync session
has three parts.

### 1. Sync in (downstream → template)

- **Find the boundary.** Sync commits here are titled `Sync … from
  <repo>` — `git log --oneline` locates the last one; the
  protocol-file sync state is also recorded on
  `notes/model-experiment.md`'s *Last protocol sync* line. Survey
  each downstream repo's commits since then, filtered to the
  template-relevant paths.
- **Template-relevant paths**: the root and subdirectory
  `CLAUDE.md`s, `.claude/commands/`, `.claude/hooks/` +
  `.claude/settings.json`, `notes/model-experiment-protocol.md`
  (byte-identical across repos by contract; the sibling log file's
  rows are project content but its *structure* is template-relevant),
  `TACTICS-GOLF.md`, `TACTICS-QUIRKS.md`, `CLEANUP.md`,
  `MODULE-SYSTEM.md`, `REFS.md`, `blueprint/CLAUDE.md` /
  `AUTHORING.md` / `lint.sh` / `verify.sh`, the *Cross-project
  engineering principles* section of `DESIGN.md`, `scripts/`, and
  workflows. Project math, phase notes, and repo-local experiment
  config stay behind.
- **Diff both directions, don't trust commit logs alone.** Diff each
  file pair directly (placeholder noise aside): commit-message
  surveys miss quiet edits, and the children-behind delta is exactly
  what the part-3 prompts must carry.

### 2. De-specialize what you port

- Project names → `{{PROJECT_NAME}}` (and confirm any *new* file is
  reached by `rename.sh`'s replace pass); `master` → "the default
  branch" where a project may differ; concrete author identities →
  "the project's existing commits".
- **Keep war stories, trim repo-opaque tokens.** Attribute as
  `(<repo> YYYY-MM-DD, model-experiment row N)` or `(<repo>
  Phase N)`; drop tokens meaningless outside the source repo
  (internal lemma names, design-§ numbers) while keeping the lesson
  concrete enough to bite.
- **Process rules are wording-sensitive** — port them near-verbatim.
  When compressing, keep the target file's house style (DESIGN.md
  principles are statement + the tell; coordinate-phase step 4 is
  labeled bullets).
- When both children amended the same file independently, take the
  better-structured copy as the base and fold the other's deltas in;
  don't union-merge prose.

### 3. Sync out (template → downstream)

Write one prompt per downstream repo, for an agent running *in that
repo*. Each prompt should: name the template HEAD it syncs to; state
which of that repo's own contributions are already incorporated (so
the agent doesn't re-port them); list the missing items per file and
where each lands; give the re-specialization map (project name,
branch, restoring war-story specifics the template genericized);
require a `diff` against the template copy for the byte-identical
protocol file; and pin commit conventions (project author identity,
actual-model `Co-Authored-By:` trailer in display form).

### Per-commit gates for template work

- `bash -n` any edited shell script; `scripts/test-hooks.sh` on any
  commit touching a hook (CI runs it pre- and post-instantiation).
- For `rename.sh` / workflow / placeholder changes, run the local
  equivalent of the CI smoke test: copy the worktree, `git add -A`
  in the copy (so `git ls-files` sees new files), run
  `./scripts/rename.sh TestProject test-user`, then check leftover
  placeholders / `template-only` markers, hook exec bits, and
  workflow YAML validity.
- After a sync lands content touching more than one auto-loaded
  `CLAUDE.md`, re-check the suite for duplication (one canonical
  home; cut only verbatim duplication — extract content to
  read-on-demand files, don't delete it).

## What's in the template

- **Infrastructure**: lakefile, lean-toolchain, .gitignore, .mcp.json,
  GitHub Actions workflows (build/lint, mathlib hopscotch, dependabot,
  plus the template-only `template-ci.yml` smoke test — see
  *Template-only content* above), blueprint build rig, home_page
  Jekyll skeleton, Apache-2.0 `LICENSE`.
- **Process docs**: `CLAUDE.md` (root + per-subdirectory), `ROADMAP.md`,
  `DESIGN.md`, `CLEANUP.md`, `TACTICS-GOLF.md`, `TACTICS-QUIRKS.md`,
  `MODULE-SYSTEM.md` / `blueprint/AUTHORING.md` / `REFS.md`
  (read-on-demand), `notes/Phase0.md` scaffold (Phase 0 = write the
  informal blueprint end-to-end before any Lean), and the
  model-tier dispatch experiment
  (`notes/model-experiment-protocol.md` + `notes/model-experiment.md`,
  armed by the log's Status line — see below).
- **Project metadata**: `formalization.yaml` skeleton (the
  [mathlib-initiative self-reporting
  schema](https://github.com/mathlib-initiative/formalization.yaml));
  filled in incrementally from day one and synced at phase
  boundaries per CLAUDE.md.
- **A working `lake build` target**: a placeholder `Basic.lean` module
  so `lake build` succeeds out of the box. Delete and replace once
  the project has real content.

## After running the rename script

1. **Initialize git** (if you haven't already): `git init && git add -A
   && git commit -m "Initial scaffold from template"`.
2. **Edit the narrative docs**:
   - `README.md` — fill in the *Project status* section.
   - `ROADMAP.md` — fill in the *Status*, *Phase plan*, and
     *References* sections.
   - `DESIGN.md` — populate *Choices to revisit* as design questions
     come up.
   - `CLAUDE.md` — fill in the *Project-history note* at the bottom,
     or delete the placeholder.
   - `blueprint/src/chapter/intro.tex` — replace `{{THEOREM_NAME}}`
     placeholder content with a real introduction; flesh out the
     phase plan. Delete the "Replace this paragraph ..." placeholder
     comments — they have survived instantiation before.
   - `home_page/index.md` — replace placeholders with real status
     prose.
   - `formalization.yaml` — fill the `project` and `sources` sections
     now; the rest accretes at phase boundaries (the file documents
     its own upkeep cadence).
3. **First Lean session**: `lake exe cache get && lake build` to warm
   the mathlib cache and verify the placeholder builds. Then commit
   the generated `lake-manifest.json` — it pins the resolved
   mathlib/checkdecls revisions for CI and the next clone.
4. **First blueprint build** (optional, requires the one-time setup in
   `blueprint/SETUP-AND-PITFALLS.md`):
   ```sh
   cd blueprint
   python3 -m venv .venv && source .venv/bin/activate
   pip install -r requirements.txt
   inv bp && inv web
   ```
5. **Push to GitHub** to verify CI green and Pages deploy succeeds.
   For `hopscotch.yml` (mathlib bump PRs), create a repo secret named
   `ci` containing a PAT with `repo` scope — PRs opened with the
   default `GITHUB_TOKEN` don't trigger CI, so bump PRs would sit
   "pending" forever.
6. **Open Phase 0** per `notes/Phase0.md`: write the entire informal
   blueprint (statements, prose proofs, `\uses{}` edges — no
   `\lean{}` / `\leanok`) before any Lean. The dep-graph then doubles
   as the project's to-do list, and later ROADMAP phase sections cite
   blueprint labels instead of speculative lemma names.

## Components you may want to remove

The template includes everything its ancestor projects
(CombinatorialRigidity, enharmonic) used. Some of
these may be over-engineering for a smaller experiment:

- **`hopscotch.yml`** — daily mathlib bump cron. Useful for
  long-lived projects tracking mathlib master; noisy for short
  experiments. Delete or change the cron to weekly.
- **`home_page/`** — GitHub Pages homepage. Only useful if the
  project will be public. Delete if not.
- **`{{PROJECT_NAME}}/Mathlib/`** — upstreaming holding pen. Useful
  only if you expect to mirror lemmas for upstream PR. The directory
  is created lazily; delete the `README.md` if you don't anticipate
  needing it.
- **`.claude/commands/coordinate-phase.md`** — slash command for
  agent-driven phase coordination. Delete if you're not using Claude
  Code's slash command system.
- **`.claude/settings.json` + `.claude/hooks/`** — two PreToolUse
  hooks. `block-lake-update.sh` mechanically blocks `lake update` /
  `lake … --update` (a hallucinated `--update` once rewrote a
  project's toolchain + manifest mid-session and OOM-crashed the
  machine under concurrent from-source mathlib rebuilds; see *Build
  discipline* in `{{PROJECT_NAME}}/CLAUDE.md`). `block-sorry-commit.sh`
  denies any `git commit` whose `.lean` diff adds a `sorry`/`admit`
  (a long context-compacted session once committed a sorry'd skeleton
  with a false "gates clean" attestation; prompt-level discipline
  does not survive compaction, hooks do). Quoted/heredoc mentions
  don't trigger either. Keep them even without Claude Code — they're
  inert then; personal settings belong in
  `.claude/settings.local.json` (gitignored), not here.
  `scripts/test-hooks.sh` exercises both hooks (run it on any commit
  that edits one); it travels with them, so delete it only if you
  delete the hooks.
- **`notes/model-experiment-protocol.md` + `notes/model-experiment.md`**
  — the model-tier dispatch experiment (rate each coordinator
  dispatch on S/P/B axes, pick a model rung, log outcomes; pooled
  across participating repos). Ships disarmed (the log's Status is
  `not started`); flip the Status to `running` to join, or delete
  both files if the project won't participate.

## What the template does *not* include

- A `lake-manifest.json`. Generated on first `lake build`; let lake
  produce it against the toolchain version pinned in `lean-toolchain`,
  then commit it (see step 3 above).
- A `.refs/` directory for reference PDFs (gitignored convention only).
- `notes/FRICTION.md` or `notes/PERFORMANCE.md` — created lazily once
  there's content for them.
- Real Lean content beyond a `def hello := "world"` placeholder.
