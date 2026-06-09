---
description: RDW context bridge. Lightweight snapshot before switching to a fresh chat mid-work — appends to next.md, no commit, no session file. Much cheaper than /rdw-end. Trigger when the user types /rdw-next.
---

# /rdw-next — Context Bridge Before Fresh Chat

Snapshot the current conversation before switching to a fresh chat, **without** the full
`/rdw-end` ceremony. Use when you need a new context window but are not at a real stopping
point: no significant decision landed, no phase milestone, no real pause — just the same
work thread continuing across short chats.

## Steps

1. Analyze the conversation for: the current work thread, completed work, unfinished
   threads, user decisions (with verbatim quotes), agent decisions/assumptions, and the
   single concrete next action.
2. Append a timestamped section to `journal/context/next.md`. Create the file with a
   `# Next — Context Bridge` header if it doesn't exist yet. Keep it compact and
   structured. Every entry should include, when available:

   ```md
   ---
   ## <YYYY-MM-DD HH:MM> — <short session name>

   ### Session pointer
   - Phase/plan pointer: <current phase.md phase/step or "unknown">

   ### Summary
   - <1-3 bullets max>

   ### Completed
   - <completed work>

   ### User decisions / quotes
   - Decision: <decision>
   - Quote: "<verbatim user quote>"

   ### Agent decisions / assumptions / rationale
   - <decision, assumption, or rationale>

   ### Files read or touched
   - Read: `<path>`
   - Touched: `<path>`

   ### Open threads / unresolved questions
   - <open thread or "none">

   ### Next action
   - <single concrete next step>

   ### Next session should read
   - `<path>`

   ### Risks / blockers
   - <risk/blocker or "none">
   ```

   Keep sections terse. `/rdw-next` is a bridge, not a blog entry or full handoff.
3. Append a `NEXT` line to `journal/log.md`.
4. Light tracker touch: tick completed checkboxes in `journal/ops/tasks.md` and refresh
   the resume pointer in `journal/context/active.md` (state line / Next). Minimal — not
   the full `/rdw-end` handoff.

## What /rdw-end does with it

When you eventually run `/rdw-end`, it reads all accumulated `/rdw-next` entries, folds
them into the full handoff, archives the consumed buffer to
`journal/ops/archive/next/YYYY-MM-DD-HHMM-<name>.md`, then resets
`journal/context/next.md` to an empty active buffer.

## Writes

- `journal/context/next.md` (append)
- `journal/log.md` (append one line)
- `journal/ops/tasks.md` (light touch — tick completed checkboxes)
- `journal/context/active.md` (light touch — refresh resume pointer)

## Does NOT write

- Session files (`journal/ops/sessions/`)
- `journal/ops/phase.md`
- Blog entries
- `.remember/remember.md`
- **No git commit**, no task archive (the full handoff is still `/rdw-end`'s job)
