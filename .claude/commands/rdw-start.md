---
description: RDW orient & resume. Read-only session start — loads state, detects doc-map drift, arms superpowers, reports phase and next action. Trigger when the user types /rdw-start.
---

# /rdw-start — Orient & Resume

Every-session, read-only. **Writes nothing.**

## Step 0 — Is the project initialized?

Check for `<root>/docs-map.md` (default root `journal`). If **absent**, tell the user the
project isn't set up and to run `/rdw-init`. Stop.

## Steps (initialized project)

1. Read the manifest `journal/docs-map.md` and the surfaces it names:
   `AGENTS.md`, `journal/ops/phase.md`, `journal/ops/tasks.md`,
   `journal/context/active.md`, and the last ~20 lines of `journal/log.md`.
2. **Drift detection (read-only).** Compare the manifest to reality:
   - Each desk in `desks:` should have `journal/work/<desk>/context.md`.
   - Each file named in the source-of-truth table should exist.
   Report any mismatch. If the drift is **structural** (missing desk dirs, renamed/removed
   surfaces), say: "Structural drift detected — consider `/rdw-init` to re-tune."
3. Report, concisely:
   - **Last phase** and what `phase.md` `note` shows was done.
   - **Current state / next** (`phase.md` `next`, and the active `plan`/`step` if set).
   - **Files needed** to execute that next step.
   - If `phase.md` `detour` is non-empty: report the open detour.
4. **Arm the session:** invoke `superpowers:using-superpowers` — do not name a specific
   skill; let Claude select what this session needs.
5. Ask the user to confirm before doing any work: "Ready to continue here, or start elsewhere?"

## Mid-plan brainstorm (guidance, not a command)

If the user wants to brainstorm while a plan is active (`phase: build`/`iterate`): push the
current `{phase, step}` onto `phase.md` `detour`, set `phase: research`, invoke
`superpowers:using-superpowers`, and pop the detour on resolve.
