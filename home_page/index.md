---
layout: home
title: {{PROJECT_TITLE}}
---

{{ONE_LINE_BLURB}}

> Replace this block-quoted paragraph with a statement of the headline
> theorem the project is working toward.

## Resources

- [Blueprint (web)]({{ '/blueprint/' | relative_url }})
- [Blueprint (PDF)]({{ '/blueprint.pdf' | relative_url }})
- [Dependency graph]({{ '/blueprint/dep_graph_document.html' | relative_url }})
- [API documentation]({{ '/docs/' | relative_url }})
- [Upstreaming dashboard]({{ '/upstreaming/' | relative_url }})
- [GitHub repository](https://github.com/{{GITHUB_USER}}/{{project-name}})

## Project status

Replace this section with a short paragraph on what's done, what's in
progress, and what's next. The canonical hand-off lives in
[`ROADMAP.md`](https://github.com/{{GITHUB_USER}}/{{project-name}}/blob/master/ROADMAP.md);
this page is the public-facing summary.

Provenance, process, and faithfulness metadata are recorded in
[`formalization.yaml`](https://github.com/{{GITHUB_USER}}/{{project-name}}/blob/master/formalization.yaml).

## Phases

The Lean code is divided into phases tracked in `ROADMAP.md`. List
each phase here as it's planned, with status (planning / in progress /
complete) and the headline result.

- **Phase 1 — name** *(status)*. One-line description and headline
  lemma. Files: `{{PROJECT_NAME}}/File1.lean`.
