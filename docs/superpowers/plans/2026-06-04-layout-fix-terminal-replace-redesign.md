# layout-fix Terminal-Replace Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make Mod+G (`layout-fix`) reliable in kitty TUI agent apps — no hangs, no stale-clipboard corruption, and the wrong-layout text actually gets replaced in place.

**Architecture:** Three changes to the single-file script `scripts/.local/bin/layout-fix`: (1) a non-blocking `flock` single-instance guard, (2) timeouts on every external subprocess call, (3) replace the fragile kitty screen-scrape "safe-delete" with an unconditional "send N BackSpace, then paste" strategy. Plus revert the now-unused kitty remote-control config. The pure conversion logic and `layout-fix-selftest` are untouched and remain the automated regression gate.

**Tech Stack:** Python 3 stdlib (`subprocess`, `fcntl`), `wtype`, `wl-clipboard`, `niri msg`, kitty, GNU Stow.

---

## Starting state

The working tree currently has uncommitted `dbg()` logging in `scripts/.local/bin/layout-fix` (added during debugging). This plan **removes** that logging as part of Task 3, so do not separately commit it. Work directly on the current working-tree version.

## File Structure

- **Modify:** `scripts/.local/bin/layout-fix` — all three behavioral changes live here. The file stays a single self-contained executable (stowed as one symlink).
- **Modify:** `kitty/.config/kitty/kitty.conf` — revert remote-control enablement (lines `1776` and `1806`).
- **Unchanged:** `scripts/.local/bin/layout-fix-selftest` — runs as the verification gate; no new cases needed.

---

### Task 1: Single-instance lock

Prevents a second Mod+G press from spawning a racing process that captures the in-flight clipboard. The pure paths (`--convert`, `--detect-language`) stay lock-free.

**Files:**
- Modify: `scripts/.local/bin/layout-fix` (imports near top; `replace_selection()` ~line 337)

- [ ] **Step 1: Add the `fcntl` import**

At the top of the file, alongside the existing imports (after `import argparse`), add:

```python
import fcntl
```

- [ ] **Step 2: Add a lock-path constant**

In the constants block near the top (with `MOD_RELEASE_WAIT` etc.), add:

```python
LOCK_PATH = "/tmp/layout-fix.lock"
```

- [ ] **Step 3: Add the lock helper**

Add this function above `replace_selection`:

```python
def acquire_single_instance_lock():
    """Return an open fd holding an exclusive lock, or None if another run holds it.
    Keep the returned fd alive for the process lifetime; the lock releases on exit."""
    fd = open(LOCK_PATH, "w")
    try:
        fcntl.flock(fd, fcntl.LOCK_EX | fcntl.LOCK_NB)
    except BlockingIOError:
        fd.close()
        return None
    return fd
```

- [ ] **Step 4: Acquire the lock at the start of `replace_selection`**

Make the lock the first thing `replace_selection()` does, before the dependency checks:

```python
def replace_selection() -> int:
    lock_fd = acquire_single_instance_lock()
    if lock_fd is None:
        notify("layout-fix", "already running")
        return 0

    for command in ("wl-copy", "wl-paste", "wtype", "niri"):
        if not require(command):
            return 1
    ...
```

Leave `lock_fd` unused otherwise — keeping it referenced by the local variable holds the fd open until the function returns and the process exits.

- [ ] **Step 5: Verify the script still parses and pure paths work**

Run: `scripts/.local/bin/layout-fix --convert akuo`
Expected: prints `שלום`

- [ ] **Step 6: Verify the lock works**

Run:
```bash
python3 - <<'PY'
import fcntl
fd = open("/tmp/layout-fix.lock", "w")
fcntl.flock(fd, fcntl.LOCK_EX | fcntl.LOCK_NB)  # hold it
import subprocess, sys
# Second acquisition in a subprocess must fail fast:
r = subprocess.run([sys.executable, "-c",
    "import fcntl;fd=open('/tmp/layout-fix.lock','w');"
    "import sys;\n"
    "try:\n fcntl.flock(fd,fcntl.LOCK_EX|fcntl.LOCK_NB);print('ACQUIRED')\n"
    "except BlockingIOError:\n print('BLOCKED')"],
    capture_output=True, text=True)
print(r.stdout.strip())
PY
```
Expected: prints `BLOCKED`

- [ ] **Step 7: Commit**

```bash
git add scripts/.local/bin/layout-fix
git commit -m "feat(layout-fix): single-instance lock to prevent racing invocations"
```

---

### Task 2: Timeouts on every external call

Bounds every subprocess so an invocation can never hang (the 23s/195s freeze). Centralize in helpers; catch `TimeoutExpired` and degrade gracefully.

**Files:**
- Modify: `scripts/.local/bin/layout-fix` (`run_text` ~line 165; bare `subprocess.run` call sites)

- [ ] **Step 1: Add timeout constants**

In the constants block near the top add:

```python
DEFAULT_TIMEOUT = 2.0     # bound for clipboard / niri / paste calls
BACKSPACE_TIMEOUT = 3.0   # bound for the bulk-backspace wtype call
```

- [ ] **Step 2: Give `run_text` a timeout and catch expiry**

Replace the existing `run_text` with:

```python
def run_text(command: list[str], input_text: str | None = None,
             timeout: float = DEFAULT_TIMEOUT) -> subprocess.CompletedProcess[str]:
    try:
        return subprocess.run(
            command,
            input=input_text,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            check=False,
            timeout=timeout,
        )
    except subprocess.TimeoutExpired:
        return subprocess.CompletedProcess(command, returncode=124, stdout="", stderr="timeout")
```

- [ ] **Step 3: Add a `run_quiet` helper for fire-and-forget commands**

Add near `run_text`:

```python
def run_quiet(command: list[str], timeout: float = DEFAULT_TIMEOUT) -> None:
    """Run a side-effecting command, ignoring failures and bounding by timeout."""
    try:
        subprocess.run(command, check=False, timeout=timeout)
    except subprocess.TimeoutExpired:
        pass
```

- [ ] **Step 4: Route bare `subprocess.run` calls through `run_quiet`**

Replace these call sites:

In `restore_clipboard`:
```python
        run_quiet(["wl-copy", "--clear"])
```

In `paste_combo`:
```python
def paste_combo(shift: bool) -> None:
    if shift:
        run_quiet(["wtype", "-M", "ctrl", "-M", "shift", "-k", "v", "-m", "shift", "-m", "ctrl"])
    else:
        run_quiet(["wtype", "-M", "ctrl", "-k", "v", "-m", "ctrl"])
```

In `copy_combo`:
```python
def copy_combo(is_terminal: bool) -> None:
    if is_terminal:
        run_quiet(["wtype", "-M", "ctrl", "-M", "shift", "-k", "c", "-m", "shift", "-m", "ctrl"])
    else:
        run_quiet(["wtype", "-M", "ctrl", "-k", "c", "-m", "ctrl"])
```

In `switch_layout_for`:
```python
            run_quiet(["niri", "msg", "action", "switch-layout", parts[0]])
```

In `focused_is_kitty`, add a timeout to the existing `subprocess.run`:
```python
def focused_is_kitty() -> bool:
    try:
        focused = subprocess.run(["niri", "msg", "focused-window"],
                                 stdout=subprocess.PIPE, text=True, check=False,
                                 timeout=DEFAULT_TIMEOUT)
    except subprocess.TimeoutExpired:
        return False
    return focused.returncode == 0 and 'App ID: "kitty"' in focused.stdout
```

- [ ] **Step 5: Verify pure path still works**

Run: `scripts/.local/bin/layout-fix --convert בםגק`
Expected: prints `code`

- [ ] **Step 6: Run the self-test**

Run: `scripts/.local/bin/layout-fix-selftest`
Expected: passes (exit 0)

- [ ] **Step 7: Commit**

```bash
git add scripts/.local/bin/layout-fix
git commit -m "fix(layout-fix): bound every external call with a timeout"
```

---

### Task 3: Always-backspace terminal replace + remove screen-scrape

Replaces the fragile cursor-detection safe-delete (which always fell back to non-destructive in TUI apps) with an unconditional "send N BackSpace, then paste". Also removes the temporary `dbg()` logging and the now-dead kitty screen-scrape code.

**Files:**
- Modify: `scripts/.local/bin/layout-fix` (`KITTY_SOCKET` ~line 15; `get_selection` ~line 236; `kitty_selection_at_cursor` ~line 249; `do_replace` ~line 288; `dbg` ~line 324; `replace_selection` ~line 337)

- [ ] **Step 1: Remove the `KITTY_SOCKET` constant**

Delete this line from the constants block:
```python
KITTY_SOCKET = "unix:@layout-fix-kitty"
```

- [ ] **Step 2: Delete `kitty_selection_at_cursor`**

Remove the entire `kitty_selection_at_cursor` function (the `get-text --add-cursor` parse, OSC/CSI stripping, and column arithmetic). The `import re` at the top is still used by nothing else after this — check with `grep -n "re\." scripts/.local/bin/layout-fix`; if `re` is now unused, remove `import re` too.

- [ ] **Step 3: Add a bulk-backspace helper**

Add near `paste_combo`:

```python
def backspace(count: int) -> None:
    """Send `count` BackSpace presses in a single wtype invocation."""
    if count <= 0:
        return
    args = ["wtype"]
    for _ in range(count):
        args += ["-k", "BackSpace"]
    run_quiet(args, timeout=BACKSPACE_TIMEOUT)
```

- [ ] **Step 4: Rewrite `do_replace` to always-backspace in terminals**

Replace the whole `do_replace` function with:

```python
def do_replace(fixed: str, selected: str, is_terminal: bool) -> None:
    set_clipboard(fixed)
    if not wait_for_clipboard(fixed, CLIPBOARD_POLL_TIMEOUT):
        notify("layout-fix", "Clipboard sync slow")

    # Wait for the user to physically release Mod+G; a held Mod key can
    # corrupt terminal bracketed-paste sequences.
    time.sleep(MOD_RELEASE_WAIT)

    if not is_terminal:
        # GUI apps: paste replaces the selection natively.
        paste_combo(shift=False)
        return

    # Terminals (kitty TUI apps): the OS does not replace the selection, so
    # delete the original by sending one BackSpace per selected character
    # (layout conversion is 1:1, so len(fixed) == len(selected)), then paste.
    backspace(len(selected))
    time.sleep(BACKSPACE_SETTLE)
    paste_combo(shift=True)
```

- [ ] **Step 5: Remove the `dbg()` function and all its call sites**

Delete the `dbg` function definition. Then remove every `dbg(...)` call:
- the three in `get_selection` (around lines 238/242/245), and
- the seven in `replace_selection` (the `=== run start ===`, `is_terminal`, `saved clipboard`, `restorable`, `selected (final)`, `fixed`, `before do_replace`, `after do_replace`, `=== run end ===` lines).

After this, `get_selection` reads:

```python
def get_selection(is_terminal: bool) -> str:
    selected = primary_text()
    if not selected:
        # No primary selection: fall back to simulating Ctrl+C.
        copy_combo(is_terminal)
        time.sleep(0.2)
        selected = clipboard_text()
    return selected
```

And `replace_selection` reads (with the Task 1 lock at the top):

```python
def replace_selection() -> int:
    lock_fd = acquire_single_instance_lock()
    if lock_fd is None:
        notify("layout-fix", "already running")
        return 0

    for command in ("wl-copy", "wl-paste", "wtype", "niri"):
        if not require(command):
            return 1

    is_terminal = focused_is_kitty()
    saved, restorable = save_clipboard()

    try:
        selected = get_selection(is_terminal)
        if not selected:
            notify("layout-fix", "No selected text found")
            return 1

        fixed = convert_layout(selected)
        if fixed == selected:
            notify("layout-fix", "Selection did not need layout conversion")
            return 0

        do_replace(fixed, selected, is_terminal)
        time.sleep(PASTE_SETTLE_WAIT)
    finally:
        restore_clipboard(saved, restorable)

    switch_layout_for(target_language(selected))
    return 0
```

- [ ] **Step 6: Confirm no dead references remain**

Run: `grep -nE "dbg|kitty_selection_at_cursor|KITTY_SOCKET|kitten" scripts/.local/bin/layout-fix`
Expected: no output (all removed)

- [ ] **Step 7: Verify the script parses and pure paths work**

Run: `scripts/.local/bin/layout-fix --convert "ert t, veuc. AGENTS.צג ub,j tu,u"`
Expected: prints `קרא את הקובץ AGENTS.md ונתח אותו`

- [ ] **Step 8: Run the self-test**

Run: `scripts/.local/bin/layout-fix-selftest`
Expected: passes (exit 0)

- [ ] **Step 9: Commit**

```bash
git add scripts/.local/bin/layout-fix
git commit -m "feat(layout-fix): always-backspace terminal replace, drop screen-scrape"
```

---

### Task 4: Revert kitty remote control

Nothing calls `kitten @` anymore, so remove the remote-control enablement added for the old screen-scrape.

**Files:**
- Modify: `kitty/.config/kitty/kitty.conf:1776,1806`

- [ ] **Step 1: Restore `allow_remote_control` to its default (commented)**

Change line 1776 from:
```
allow_remote_control yes
```
to (remove the active line, leaving only the default comment on 1775):
```
# allow_remote_control no
```

- [ ] **Step 2: Remove the `listen_on` socket line**

Delete line 1806:
```
listen_on unix:@layout-fix-kitty
```
Leave the surrounding commented documentation lines intact.

- [ ] **Step 3: Confirm the active settings are gone**

Run: `grep -nE "^allow_remote_control|^listen_on" kitty/.config/kitty/kitty.conf`
Expected: no output

- [ ] **Step 4: Commit**

```bash
git add kitty/.config/kitty/kitty.conf
git commit -m "revert(kitty): drop remote control, no longer used by layout-fix"
```

---

### Task 5: Verification gate + docs reconcile

**Files:**
- Read/Modify: `docs/agent-reference/niri-keybinds.md`

- [ ] **Step 1: Final self-test run**

Run: `scripts/.local/bin/layout-fix-selftest`
Expected: passes (exit 0)

- [ ] **Step 2: Reconcile the keybind doc**

Open `docs/agent-reference/niri-keybinds.md`. Confirm the Mod+G entry still accurately says it fixes layout and switches the keyboard layout afterward, and that it does **not** claim kitty remote control as a dependency. Adjust wording only if inaccurate.

- [ ] **Step 3: Manual smoke checklist (run live, record results)**

Perform in a real session:
1. In Claude Code / Codex input: type wrong-layout text, select it, press Mod+G → original deleted, correction in place, clipboard preserved, layout switched.
2. Press Mod+G twice rapidly → second press is a no-op notification ("already running"), no stale clipboard.
3. GUI app (browser/chat field): select wrong-layout text → corrected in place.

- [ ] **Step 4: Commit any doc changes**

```bash
git add docs/agent-reference/niri-keybinds.md
git commit -m "docs(keybinds): reconcile Mod+G after terminal-replace redesign"
```

(Skip this commit if Step 2 required no changes.)

---

## Self-Review

- **Spec coverage:** Lock (Task 1) ↔ spec §1; timeouts (Task 2) ↔ spec §2; always-backspace + remove screen-scrape + remove dbg + remove KITTY_SOCKET (Task 3) ↔ spec §3; kitty RC revert (Task 4) ↔ spec §4; selftest gate + docs (Task 5) ↔ spec "Testing" and "Docs to reconcile". All sections covered.
- **Placeholders:** none — every code step shows complete code; every command shows expected output.
- **Type/name consistency:** `acquire_single_instance_lock` → `lock_fd`; `run_quiet`/`run_text` timeouts; `backspace(count)` called with `len(selected)`; `do_replace(fixed, selected, is_terminal)` signature unchanged from existing callers. Consistent across tasks.
