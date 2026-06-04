# Design: layout-fix terminal-replace redesign (reliability + always-backspace)

- **Date:** 2026-06-04
- **Component:** `scripts/.local/bin/layout-fix` (Mod+G), `kitty/.config/kitty/kitty.conf`
- **Status:** approved (brainstorming)
- **Supersedes (partially):** `2026-06-04-layout-fix-robustness-design.md` — keeps that
  doc's clipboard-preservation and auto-layout-switch work; replaces its terminal
  "screen-scrape cursor detection" safe-delete with the strategy below.

## Problem

After the robustness work landed, a live smoke test surfaced three failures. The debug
log (`/tmp/layout-fix.log`) captured two invocations interleaving:

1. **Freeze.** Run 1 logged `before do_replace` and did not log `after do_replace` for
   ~23s; clipboard restore came ~195s later. Every external call
   (`wtype` / `wl-copy` / `wl-paste` / `niri msg` / `kitten @`) is `subprocess.run(...,
   check=False)` with **no `timeout`**, so any blocking call hangs indefinitely.

2. **Stale clipboard restored.** Because Run 1 hung silently, the user pressed Mod+G
   again. Run 2 started while Run 1 was mid-operation and captured Run 1's *in-flight*
   converted text (`'i like to go to the beach'`) as its "saved" clipboard, then restored
   that wrong value. There is **no single-instance guard**.

3. **Original text not deleted.** The real workflow is fixing wrong-layout text typed
   into **TUI agent apps running inside kitty** (Codex, Claude Code, hermes, pi) — not
   shell command lines. Those apps run on the alt-screen and hide/park the hardware
   cursor while drawing their own input box (borders, prompt prefixes, wrapping). The
   safe-delete check (`get-text --extent=screen --add-cursor` → strip escapes →
   `before_cursor.endswith(selection)`) therefore never matches, so it always takes the
   non-destructive fallback. Result: the correction is pasted but the wrong text stays
   (`יקךךםhello`).

## Goals

- Bound every external call so an invocation can never hang.
- Prevent concurrent invocations from corrupting each other's clipboard state.
- Reliably replace wrong-layout text in kitty TUI apps (delete original, paste fix).
- Remove the fragile screen-scrape machinery and the now-unused kitty remote control.

## Non-goals

- Handling selections taken from terminal **scrollback** (a previous message rather than
  the live input). The accepted workflow is fixing text the user just typed, so the
  typing cursor sits at the end of the selection. Scrollback selections may over-delete
  the current input; this is recoverable (retype) and out of scope.
- Terminals other than kitty (kitty is the only terminal).
- Layouts other than `us` (English) and `il` (Hebrew).

## Insight that drives the design

Inside a TUI app, the OS does **not** replace a selection on paste, and the **hardware
cursor is unreliable** (hidden/parked). But a synthesized **BackSpace edits the app's
*logical* input buffer**, immune to visual wrapping, borders, and cursor position. Since
the user just typed the text, the logical input cursor is at its end. So
"send N BackSpace, then paste" is both simpler and more robust than any screen-position
detection. Layout conversion is 1:1 per character, so `len(fixed) == len(selected)` —
N backspaces is exact.

## Architecture

Stays a **single self-contained executable**. Three changes.

### 1. Single-instance lock

- At the start of `replace_selection()` (the side-effecting entry; `--convert` /
  `--detect-language` stay lock-free and pure), acquire a **non-blocking** `flock` on
  `/tmp/layout-fix.lock` via `fcntl.flock(fd, LOCK_EX | LOCK_NB)`.
- On `BlockingIOError` (already held): `notify("layout-fix", "already running")` and
  return `0` immediately.
- Hold the fd open for the process lifetime (store on a variable that outlives the
  function, or keep the `with`-scope around the whole operation). Lock releases on exit.

### 2. Timeouts on every external call

- Add a `timeout=` to every `subprocess.run` / `run_text`. Centralize: give `run_text`
  and a parallel `run_quiet` helper a default timeout argument.
- On `subprocess.TimeoutExpired`: catch, treat as failure (empty result / non-fatal),
  `notify` where useful, never raise out of the side-effecting path.
- Suggested values (tunable constants at top of file):
  - clipboard / paste / niri calls: ~2s.
  - the BackSpace `wtype` call: ~3s.
- Existing named waits (`MOD_RELEASE_WAIT`, `PASTE_SETTLE_WAIT`,
  `CLIPBOARD_POLL_TIMEOUT`, `BACKSPACE_SETTLE`) stay.

### 3. Terminal replace — always backspace (Approach A)

In `do_replace`, the kitty (`is_terminal == True`) branch becomes:

1. `set_clipboard(fixed)` and `wait_for_clipboard(fixed, CLIPBOARD_POLL_TIMEOUT)`.
2. `time.sleep(MOD_RELEASE_WAIT)` (let Mod physically release).
3. Send `N = len(selected)` BackSpace in a **single `wtype` call** — build args
   `["wtype", "-k", "BackSpace"] * N`-style (one `-k BackSpace` pair per char) so it is
   one process, not N.
4. `time.sleep(BACKSPACE_SETTLE)`.
5. `paste_combo(shift=True)` (bracketed paste into the terminal).

Delete the screen-scrape path entirely:

- Remove `kitty_selection_at_cursor()`.
- Remove the OSC/CSI stripping and `get-text --add-cursor` parsing.
- Remove the `KITTY_SOCKET` constant.
- Remove the temporary `dbg()` logging and all its call sites.

GUI path (`is_terminal == False`) is unchanged: `paste_combo(shift=False)` —
the OS replaces the selection.

### 4. Revert kitty remote control

With the screen-scrape gone, nothing calls `kitten @`. Revert the `allow_remote_control`
+ `listen_on` socket addition (commit `e5539b7`) in `kitty/.config/kitty/kitty.conf`.
`focused_is_kitty()` uses `niri msg focused-window`, not kitty RC, so terminal detection
is unaffected.

## Unchanged

- Clipboard preservation (`save_clipboard` / `restore_clipboard` in `finally`).
- Auto layout-switch via `niri msg keyboard-layouts` + `switch-layout`
  (`target_language` → `switch_layout_for`).
- Pure conversion logic (`convert_layout`, `compute_states`, `target_language`) and the
  `--convert` / `--detect-language` flags.

## Error handling summary

- Single-instance lock prevents concurrent clipboard corruption; second press exits 0.
- Every external call bounded by `timeout`; timeouts caught, degrade gracefully, never
  hang or raise out of the side-effecting path.
- Clipboard still restored in `finally`.
- `--convert` / `--detect-language` remain pure and lock-free.

## How each observed symptom is fixed

| Symptom | Fix |
|---|---|
| 23s / 195s freeze | timeouts on every external call (change 2) |
| Restored stale (wrong) clipboard | single-instance lock (change 1) |
| Original text left in place in TUI apps | always-backspace in kitty (change 3) |

## Testing

### Pure-logic layer

`layout-fix-selftest` (`--convert` / `--detect-language`) is unaffected and must stay
green. No new pure cases required — this redesign changes only the side-effecting layer.

### Side-effecting layer — manual smoke checklist

1. Codex / Claude Code input box: type wrong-layout text, select it, Mod+G → original
   deleted, correction in place, clipboard preserved, layout switched.
2. Rapid double-press of Mod+G → second press is a no-op ("already running"), no stale
   clipboard left behind.
3. Simulate a slow/blocked external call (or trust the timeout values) → invocation
   exits within the timeout, no multi-second freeze.
4. GUI app (browser/chat field): select wrong-layout text → corrected in place
   (unchanged behavior).

### Verification gate

`layout-fix-selftest` passes before completion.

## Docs to reconcile on completion

- `docs/agent-reference/niri-keybinds.md` — Mod+G behavior note still accurate (it
  switches layout after fixing); confirm no mention of kitty remote control as a
  dependency.
- Note the kitty remote-control revert in the build-log/blog entry.
