# 0002 — The cursor was the wrong thing to trust

**Date:** 2026-06-04
**Milestone:** layout-fix terminal-replace redesign — reliable Mod+G in TUI agent apps

I bound Mod+G to a script that fixes Hebrew/English wrong-layout text. Type `akuo` when
Hebrew is active, select it, Mod+G — it becomes `שלום`. The conversion logic is simple and
has worked from day one.

The *replacement* was the hard part.

When you're in a GUI app — a browser field, a chat input — paste replaces the selection.
Done. But I mostly use Mod+G inside TUI agent apps: Claude Code, Codex, Hermes. In a
terminal, paste doesn't replace the selection. You have to delete the original text first.

My first attempt at deletion was clever. I'd query the kitty terminal for its screen buffer,
find the cursor position, check if the selected text appeared right before it, and only then
send backspaces. If the check failed — which it always did, because TUI apps hide the cursor
behind their input box borders — I'd fall back to non-destructive paste. The correction would
appear, but the original wrong text would stay too.

So the script never actually worked for the case I built it for.

The debug log made the failure obvious: `kitty_selection_at_cursor` returned `False` on
every invocation because TUI apps park the hardware cursor at some arbitrary screen position
while drawing their own logical input. My screen-position arithmetic was comparing against a
cursor that had nothing to do with where the user's text was.

Then there were two more bugs I hadn't noticed until I ran two rapid Mod+G presses: a second
invocation would start mid-operation and capture the in-flight converted text as its "saved"
clipboard, then restore that wrong value. And every external call — `wtype`, `wl-copy`,
`wl-paste`, `niri msg` — had no timeout, so a blocked call would hang the script for however
long the compositor felt like waiting.

Three fixes:

**Single-instance lock.** A non-blocking `flock` at the start of `replace_selection()`. If
the lock is held, the second press exits immediately with "already running" and the clipboard
is never touched.

**Timeouts everywhere.** Every `subprocess.run` gets a `timeout=`. A central `run_quiet`
helper absorbs the `TimeoutExpired` silently for fire-and-forget calls; `run_text` returns a
synthetic `CompletedProcess(returncode=124)` so callers degrade gracefully. No more hangs.

**Always backspace.** This is the one I'm actually proud of. The insight: I don't need the
cursor position at all. Layout conversion is strictly 1:1 per character — `len(fixed) ==
len(selected)` always. The user just typed the text, so their logical input cursor is at the
end of the selection. One `wtype` call with N `-k BackSpace` args deletes exactly the right
characters, regardless of screen wrapping, borders, or where the hardware cursor is parked.
Then paste puts the correction in.

All the screen-scrape machinery — `kitten @`, the OSC/CSI stripping, the column arithmetic,
the `allow_remote_control` socket in kitty.conf — is gone. The script is 50 lines shorter.

Selftest: 17/17. Smoke test: confirmed working in Claude Code, Codex, and a browser field.

The cursor was the wrong thing to trust. The input buffer never lied.

---

🔗 **LinkedIn cut:**

I spent weeks debugging a keyboard shortcut that was supposed to fix Hebrew/English
wrong-layout text in terminal apps. The script had cursor detection, OSC escape parsing, a
kitty remote-control socket. It never worked.

The fix was 3 lines: send N BackSpaces, then paste.

Layout conversion is 1:1 per character. The user just typed the text, so the logical cursor
is at the end. The hardware cursor position — the thing I was detecting — was irrelevant.
TUI apps park it somewhere arbitrary while drawing their UI.

The clever version solved the wrong problem. The simple version understood the contract.
