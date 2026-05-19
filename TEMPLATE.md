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
3. Prints a next-step checklist.
4. Self-deletes.

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

## What's in the template

- **Infrastructure**: lakefile, lean-toolchain, .gitignore, .mcp.json,
  GitHub Actions workflows (build/lint, mathlib hopscotch, dependabot),
  blueprint build rig, home_page Jekyll skeleton.
- **Process docs**: `CLAUDE.md` (root + per-subdirectory), `ROADMAP.md`,
  `DESIGN.md`, `CLEANUP.md`, `TACTICS-GOLF.md`, `TACTICS-QUIRKS.md`,
  `notes/Phase1.md` scaffold.
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
     phase plan.
   - `home_page/index.md` — replace placeholders with real status
     prose.
3. **First Lean session**: `lake exe cache get && lake build` to warm
   the mathlib cache and verify the placeholder builds.
4. **First blueprint build** (optional, requires the one-time setup in
   `blueprint/SETUP-AND-PITFALLS.md`):
   ```sh
   cd blueprint
   python3 -m venv .venv && source .venv/bin/activate
   pip install -r requirements.txt
   inv bp && inv web
   ```
5. **Push to GitHub** to verify CI green and Pages deploy succeeds.

## Components you may want to remove

The template includes everything CombinatorialRigidity used. Some of
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

## What the template does *not* include

- A `lake-manifest.json`. Generated on first `lake build`; let lake
  produce it against the toolchain version pinned in `lean-toolchain`.
- A `.refs/` directory for reference PDFs (gitignored convention only).
- `notes/FRICTION.md` or `notes/PERFORMANCE.md` — created lazily once
  there's content for them.
- Real Lean content beyond a `def hello := "world"` placeholder.
