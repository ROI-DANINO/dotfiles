---
description: RDW checkpoint & close. Always writes a session handoff (session file, active.md, phase.md, log, .remember baton, commit); at a phase boundary also runs verification + reconcile-docs + blog. Trigger when the user types /rdw-end or signals the session is wrapping up.
---

# /rdw-end — Checkpoint & (conditionally) Reconcile

Every-session. Absorbs the old `/push` (sweeps the conversation for new tasks/ideas).

## Always

1. **Consume the bridge:** if `journal/context/next.md` exists with pending `/rdw-next`
   entries, read all accumulated entries and fold them into the analysis below as
   prior-chat context. Ignore header-only or already-reset buffers.
2. Sweep the conversation for: completed work, decisions, new tasks/ideas, and 3–5 verbatim
   voice quotes (no analysis). Include anything folded in from `next.md`.
3. Generate a short session nickname.
4. Write `journal/ops/sessions/<nickname>-<timestamp>.md` (summary + quotes + next action).
5. Update `journal/context/active.md` — resume context (state line, Next, Done).
6. Update `journal/ops/phase.md` — set `phase`/`sub_phase`/`step`, append the session to
   `sessions:`, refresh `next` and `note`. Infer phase from the conversation
   (executing a plan step → `build`; reviewing → `iterate`; exploring/no plan → `research`).
7. **Archive before mutate:** copy `journal/ops/tasks.md` → `journal/ops/archive/tasks-<timestamp>.md`,
   then update `tasks.md` (current-phase tasks; route swept ideas to Ideas, blockers to Questions).
   Delete archive files older than 14 days.
8. Append one line to `journal/log.md`.
9. Write `.remember/remember.md` (the next-session baton) — defer to the remember plugin's
   mechanism / format. Include: session nickname, what completed, the single next action,
   files to load.
10. If `next.md` had pending entries, archive the consumed buffer to
    `journal/ops/archive/next/YYYY-MM-DD-HHMM-<nickname>.md`, then reset
    `journal/context/next.md` to an empty buffer (header only). Leave no stale pending
    content behind.
11. Commit `rdw-end: <nickname>`; push if a remote exists.

## On phase completion — leave the docs true

Trigger when `journal/ops/phase.md` indicates a phase just completed, or the user says so.

12. Invoke `superpowers:verification-before-completion` before claiming the phase done.
13. **Reconcile** every doc surface named in `journal/docs-map.md` to reality: fix any doc that
    disagrees with the code/state ("the one named in docs-map wins; fix the other").
14. Write or update a `blog/NNNN-slug.md` entry (first-person, anchored to the milestone, ends
    with a 🔗 LinkedIn cut) and update `blog/README.md`. Follow the style guardrails in
    `blog/README.md`.
15. Re-commit if reconciliation/blog changed files: `rdw-end: phase complete — <phase>`.

## Output
One short confirmation: nickname, what was checkpointed, whether the phase-exit ritual ran,
and the next action.
