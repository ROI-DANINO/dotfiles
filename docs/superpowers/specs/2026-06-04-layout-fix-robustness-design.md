# Design: layout-fix robustness + auto layout-switch

- **Date:** 2026-06-04
- **Component:** `scripts/.local/bin/layout-fix` (Mod+G), `scripts/.local/bin/layout-fix-selftest`, `kitty/.config/kitty/kitty.conf`
- **Status:** approved (brainstorming)

## Problem

`Mod+G` runs `layout-fix`, which converts wrong-keyboard-layout text (Hebrew↔English)
from the selection and pastes the corrected text back. In real use it has four problems:

1. **Clipboard clobbering** — `wl-copy` overwrites the user's clipboard and never
   restores it.
2. **Flaky timing** — fixed `sleep()` calls race against copy/paste completion and the
   still-held Mod key.
3. **Partial-selection over-deletion** — the terminal path backspaces `len(selection)`
   characters from the cursor. If the selection is not the trailing text at the cursor,
   it deletes unselected text too.
4. **No layout follow-through** — after fixing text the user must manually switch the
   keyboard layout to keep typing in the intended language.

## Goals

- Preserve the user's clipboard across an invocation.
- Make copy→paste deterministic; eliminate the copy/paste race.
- Never destructively delete unselected text in a terminal.
- After a successful conversion, switch the active keyboard layout to the converted-to
  language.
- Keep the pure conversion logic unit-testable and green in `layout-fix-selftest`.

## Non-goals

- Generalizing terminal detection beyond kitty (kitty is the only terminal; `Mod+T`).
- Supporting layouts other than `us` (English) and `il` (Hebrew).
- Auto-testing the side-effecting layer (clipboard / kitty / niri) — covered by a manual
  smoke checklist.

## Architecture

Stays a **single self-contained executable** (stowed as one symlink; splitting into
modules would break the simple install). Refactored internally into clear,
independently-testable functions. Four isolated changes:

### 1. Clipboard preservation

Wrap the replace operation: capture existing clipboard text up front, do the work,
restore in a `finally` so a mid-operation failure never strands converted text on the
clipboard.

- Capture: `wl-paste --no-newline --type text`.
- Empty clipboard → restore via `wl-copy --clear`.
- Non-text/image clipboard (capture returns non-zero with content) → unrestorable: skip
  restore and `notify` once ("clipboard was not text — not restored").

### 2. Deterministic timing

- After `wl-copy`-ing the converted text, **poll** `wl-paste` until it returns the exact
  converted value (bounded by `CLIPBOARD_POLL_TIMEOUT`), then paste. Kills the
  "paste fired before copy landed" race. On timeout: proceed anyway + `notify`
  ("clipboard sync slow") — never hang.
- Remaining waits become named, tunable constants at the top of the file:
  - `MOD_RELEASE_WAIT` — let the user physically release Mod+G (Wayland gives no clean
    key-state read, so this stays a sleep).
  - `PASTE_SETTLE_WAIT` — after paste, before clipboard restore.

### 3. Terminal safe-delete (kitty)

Before deleting in kitty, verify the selection is the trailing text at the cursor using
kitty remote control:

- `kitten @ get-text --extent=screen --add-cursor --self` → screen text + cursor position
  encoded as ANSI. Parse cursor row/col, extract the line, take the `len(selection)`
  characters immediately before the cursor column, compare to the selection.
- **Verified at cursor end** → backspace-replace as today (safe).
- **Not at cursor end, remote control unavailable, kitty too old, or cursor parse fails**
  → non-destructive: paste correction at cursor + `notify` ("original left in place —
  delete it manually").

All `kitten @` calls are wrapped to never raise; any failure falls back to
non-destructive. GUI path (`is_terminal == False`) is untouched.

**Config change:** enable remote control in `kitty/.config/kitty/kitty.conf`
(`allow_remote_control yes` + a `listen_on` socket). Acceptable on a personal single-user
machine (consistent with AGENTS.md). Script degrades gracefully if it is ever off.

### 4. Auto-switch keyboard layout

After a successful conversion (`fixed != selected`):

- Factor a pure `target_language(text) -> "heb" | "eng" | None` from the existing `states`
  pass: tally Hebrew-output (state `1`) vs English-output (states `-1` and `2`)
  characters, majority wins; a tie → `None`.
- Resolve the layout index by **name** from `niri msg keyboard-layouts` (match
  "Hebrew" / "English"), not hardcoded 0/1 — robust if layout order changes.
- `niri msg action switch-layout <index>`.
- All niri calls non-fatal: failures caught (optional `notify`); conversion result stands.
  Missing name match or `None` target → skip silently.

## Error handling summary

- Clipboard restore in `finally`; non-text clipboard never corrupted.
- Clipboard poll bounded; never hangs.
- All `kitten @` and `niri msg` calls caught; degrade gracefully, never raise.
- `--convert TEXT` remains a pure path that touches nothing external.
- "Selection did not need conversion" and "no selection found" paths unchanged.

## Testing

### Pure-logic layer (`--convert`, `--detect-language`)

Extend `layout-fix-selftest` (no display/clipboard needed):

- Keep existing 7 cases.
- Add: caps-lock-on Hebrew→English uppercasing; mixed-script sentence; leading/trailing
  ambiguous punctuation; digits passthrough; empty string.
- Add target-language assertions via a hidden `--detect-language TEXT` flag that prints
  `heb` / `eng` / `none`, driven by `target_language()`.

### Side-effecting layer — manual smoke checklist

1. GUI app: select wrong-layout text → corrected in place, clipboard preserved, layout
   switched to converted-to language.
2. Terminal, selection at cursor end → in-place replace, no over-delete.
3. Terminal, partial mid-line selection → non-destructive paste + notify, no over-delete.
4. Remote control disabled → terminal falls back to non-destructive.

### Verification gate

`layout-fix-selftest` passes before completion.

## Docs to reconcile on completion

- `docs/agent-reference/niri-keybinds.md` — note Mod+G now switches layout after fixing.
- `kitty.conf` change is self-documenting; mention remote-control enablement in the
  blog/build-log entry.
