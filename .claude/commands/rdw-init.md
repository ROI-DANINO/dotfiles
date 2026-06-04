---
description: RDW setup & re-tune. First-time bootstrap (existing project / fresh project / just an idea) or a deliberate structural pivot (desks, profile, manifest). Trigger when the user types /rdw-init or asks to set up / re-shape the RDW workflow.
---

# /rdw-init — Setup & Re-tune

The rare, structural command: set up RDW on a project, or deliberately re-shape it.
Templates live in `/home/roking/Desktop/Projects/workspace/templates/`.

## Step 0 — Detect the situation

Check whether a manifest exists at `<root>/docs-map.md` (default root `journal`).

- **Manifest absent** → first-time. Continue to "First-time".
- **Manifest present** → re-tune. Skip to "Re-tune".

## First-time — classify the project

1. **Existing project** — there is source code and/or git history but no `journal/`.
2. **Fresh project** — the directory is empty or near-empty (no source, maybe a README).
3. **Just an idea** — the user is describing something to build, not pointing at a repo.

Ask the user to confirm which, suggesting the one you detected.

### Existing project
1. Short interview: project goal/mission, and any logical "desks" (work areas).
2. Scaffold by copying `/home/roking/Desktop/Projects/workspace/templates/` into the repo: create
   `journal/{ops,context,raw/_inbox,ops/sessions,ops/archive}/`, `journal/docs-map.md`,
   `journal/ops/phase.md`, `journal/ops/tasks.md`, `journal/context/active.md`,
   `journal/log.md`, `blog/README.md`, and root `AGENTS.md` / `ROADMAP.md` / `PROGRESS.md`.
3. Infer an initial phase from the repo (e.g. mature code → `phase: iterate`; early → `build`).
   Write it into `journal/ops/phase.md`.
4. Fill `AGENTS.md` mission/constraints and `docs-map.md` desks/profile from the interview.
5. Commit `rdw-init: scaffold RDW onto existing project`; push if a remote exists.

### Fresh project
1. Interview: goal, desks.
2. `git init` if not already a repo.
3. Scaffold from `templates/` exactly as above.
4. Set `phase: research`, `step: "initialize project"`.
5. Add a `.gitignore` covering runtime noise (`node_modules`, `.DS_Store`, `.env`).
   Note: keep `docs/superpowers/` git-ignored; tracked specs/plans go in `docs/specs/`
   and `docs/plans/`.
6. Commit `rdw-init: initialize RDW workspace`; push if a remote exists.

### Just an idea
1. Do NOT scaffold yet.
2. Invoke `superpowers:using-superpowers` and let it run — for a fresh idea this leads into
   brainstorming. Produce a spec (`docs/specs/`) and, when ready, a plan (`docs/plans/`).
3. Once a spec/plan exists, return here and run the **Fresh project** scaffold, recording the
   spec/plan paths in `journal/ops/phase.md` (`spec:` / `plan:`).

## Re-tune (manifest present)

The deliberate "re-learn the project's shape" moment. Possible pivots:
- Add or remove a desk → update `docs-map.md` `desks:` and create/remove `journal/work/<desk>/context.md`.
- Change the profile or `root`.
- Restructure the source-of-truth table or change what's authoritative.

Rules:
1. **Archive before mutate:** copy any ops file you will edit to `journal/ops/archive/<name>-<timestamp>.md`.
2. Make the targeted edits.
3. Commit `rdw-init: re-tune — <one-line summary>`; push if a remote exists.

## Output
Report what was created/changed and the next action, then suggest `/rdw-start`.
