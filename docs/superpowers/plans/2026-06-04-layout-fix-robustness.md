# layout-fix Robustness + Auto Layout-Switch Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the `Mod+G` layout-fix script preserve the clipboard, replace text without races, never destructively delete unselected text in a terminal, and auto-switch the keyboard layout to the converted-to language.

**Architecture:** Single self-contained Python executable (`scripts/.local/bin/layout-fix`), refactored into small testable functions. Pure conversion logic is unit-tested via `layout-fix-selftest`; side-effecting paths (clipboard, kitty remote control, niri layout switch) degrade gracefully and are covered by a manual smoke checklist. Terminal in-place replacement is gated behind kitty remote control over a socket so an externally-spawned process can read the cursor position.

**Tech Stack:** Python 3 stdlib, `wl-copy`/`wl-paste` (wl-clipboard), `wtype`, `niri msg`, `kitten @` (kitty remote control).

---

## File Structure

- **Modify** `scripts/.local/bin/layout-fix` — refactor conversion logic into `compute_states()`; add `target_language()` and `--detect-language`; add clipboard save/restore, deterministic clipboard polling, kitty cursor verification, and niri layout switching; rewrite `replace_selection()`.
- **Modify** `scripts/.local/bin/layout-fix-selftest` — add `--detect-language` cases and more `--convert` edge cases.
- **Modify** `kitty/.config/kitty/kitty.conf` — enable remote control over a socket.
- **Modify** `docs/agent-reference/niri-keybinds.md` — note Mod+G now switches layout after fixing.

The script stays one file: it is stowed as a single symlink, so splitting into modules would break the install.

---

## Task 1: Pure logic — extract `compute_states`, add `target_language` + `--detect-language`

**Files:**
- Modify: `scripts/.local/bin/layout-fix`
- Test: `scripts/.local/bin/layout-fix-selftest`

- [ ] **Step 1: Add failing `--detect-language` cases to the selftest**

In `scripts/.local/bin/layout-fix-selftest`, add a `DETECT_CASES` dict right after the existing `CASES` dict (after line 19):

```python
DETECT_CASES = {
    "akuo": "heb",
    "בםגק": "eng",
    "פךקשדק": "eng",
    "ert t, veuc. AGENTS.צג ub,j tu,u": "heb",
    "": "none",
}
```

Then, inside `main()`, after the existing `for source, expected in CASES.items():` loop and before the `if failures:` block, add:

```python
    for source, expected in DETECT_CASES.items():
        result = subprocess.run(
            [str(LAYOUT_FIX), "--detect-language", source],
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        )
        if result.returncode != 0:
            failures.append(
                f"detect {source!r}: command failed with {result.returncode}: {result.stderr.strip()}"
            )
            continue
        actual = result.stdout.rstrip("\n")
        if actual != expected:
            failures.append(f"detect {source!r}: expected {expected!r}, got {actual!r}")
```

Also update the success print at the end of `main()` from:

```python
    print(f"layout-fix selftest passed ({len(CASES)} cases)")
```

to:

```python
    print(f"layout-fix selftest passed ({len(CASES) + len(DETECT_CASES)} cases)")
```

- [ ] **Step 2: Run the selftest to verify it fails**

Run: `./scripts/.local/bin/layout-fix-selftest`
Expected: FAIL — every `detect ...` case fails with `unrecognized arguments: --detect-language` (the flag does not exist yet).

- [ ] **Step 3: Refactor `convert_layout` into `compute_states` + add `target_language`**

In `scripts/.local/bin/layout-fix`, replace the entire `convert_layout` function (currently lines 83–134, from `def convert_layout(text: str) -> str:` through `    return "".join(result)`) with:

```python
def compute_states(text: str, caps_on: bool) -> list[int]:
    states: list[int] = []
    current_state = 0  # 1 = US->Heb, -1 = Heb->US, 2 = US->US

    # Forward pass to detect state for unambiguous characters
    for char in text:
        if not caps_on and char.isupper() and char in US_OUTPUT:
            current_state = 2
        elif is_us_only(char):
            current_state = 1
        elif is_heb_only(char):
            current_state = -1
        states.append(current_state)

    # Backward pass to fill initial ambiguous characters
    current_state = 0
    for i in range(len(text) - 1, -1, -1):
        if not caps_on and text[i].isupper() and text[i] in US_OUTPUT:
            current_state = 2
        elif is_us_only(text[i]):
            current_state = 1
        elif is_heb_only(text[i]):
            current_state = -1

        if states[i] == 0:
            states[i] = current_state

    # Default remaining fully ambiguous text (e.g. just commas) to US
    for i in range(len(states)):
        if states[i] == 0:
            states[i] = 1

    return states


def convert_layout(text: str) -> str:
    caps_on = check_caps_lock()
    states = compute_states(text, caps_on)

    result = []
    for i, char in enumerate(text):
        if states[i] == 2:
            # Typed in US, intended US (Shift was held)
            result.append(char)
        elif states[i] == 1:
            # Typed in US layout, intended Hebrew
            lower_char = char.lower()
            mapped = US_TO_HEBREW.get(lower_char, char)
            result.append(mapped)
        else:
            # Typed in Hebrew layout, intended US
            mapped = HEBREW_TO_US.get(char, char)
            # If they had caps lock on while typing Hebrew, uppercase the English output
            if caps_on and mapped.isalpha():
                mapped = mapped.upper()
            result.append(mapped)

    return "".join(result)


def target_language(text: str) -> str | None:
    """Dominant intended language of text: 'heb', 'eng', or None on tie/empty."""
    states = compute_states(text, check_caps_lock())
    heb = sum(1 for s in states if s == 1)
    eng = sum(1 for s in states if s in (-1, 2))
    if heb > eng:
        return "heb"
    if eng > heb:
        return "eng"
    return None
```

- [ ] **Step 4: Wire up the `--detect-language` flag in `main`**

In `scripts/.local/bin/layout-fix`, find this block in `main()` (currently lines 223–231):

```python
    parser.add_argument("--convert", help="Convert text and print the result without touching the clipboard.")
    args = parser.parse_args()

    if args.convert is not None:
        print(convert_layout(args.convert))
        return 0

    return replace_selection()
```

Replace it with:

```python
    parser.add_argument("--convert", help="Convert text and print the result without touching the clipboard.")
    parser.add_argument("--detect-language", help="Print target language (heb/eng/none) without side effects.")
    args = parser.parse_args()

    if args.convert is not None:
        print(convert_layout(args.convert))
        return 0

    if args.detect_language is not None:
        print(target_language(args.detect_language) or "none")
        return 0

    return replace_selection()
```

- [ ] **Step 5: Run the selftest to verify it passes**

Run: `./scripts/.local/bin/layout-fix-selftest`
Expected: PASS — `layout-fix selftest passed (12 cases)`.

- [ ] **Step 6: Commit**

```bash
git add scripts/.local/bin/layout-fix scripts/.local/bin/layout-fix-selftest
git commit -m "refactor(layout-fix): extract compute_states, add target_language + --detect-language

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 2: Expand `--convert` selftest coverage

**Files:**
- Test: `scripts/.local/bin/layout-fix-selftest`

- [ ] **Step 1: Add edge-case conversion cases**

In `scripts/.local/bin/layout-fix-selftest`, add these entries to the existing `CASES` dict (keep the existing 7):

```python
    "": "",
    "12345": "12345",
    "code": "בםגק",
    "ab.cd": "שנ>דג",
```

Rationale: empty string round-trips; digits are not in either map and pass through; lowercase US letters convert to Hebrew (the tool's purpose — input is wrong-layout text); `.` maps to Hebrew `>`? — verify the actual expected value in the next step rather than trusting this comment.

- [ ] **Step 2: Determine the real expected outputs, then fix the dict**

Run each new source through the binary to capture ground truth:

Run:
```bash
for s in "" "12345" "code" "ab.cd"; do printf '%s => ' "$s"; ./scripts/.local/bin/layout-fix --convert "$s"; echo; done
```

Update the four new `CASES` values to exactly match the printed outputs. (The conversion logic is unchanged from Task 1, so these are characterizing the existing behavior, not changing it.) Remove any case whose output is identical to its input EXCEPT the intentional `""` and `"12345"` passthrough checks.

- [ ] **Step 3: Run the selftest to verify it passes**

Run: `./scripts/.local/bin/layout-fix-selftest`
Expected: PASS with the new total count.

- [ ] **Step 4: Commit**

```bash
git add scripts/.local/bin/layout-fix-selftest
git commit -m "test(layout-fix): add edge-case conversion coverage

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 3: Enable kitty remote control over a socket

**Files:**
- Modify: `kitty/.config/kitty/kitty.conf`

- [ ] **Step 1: Enable `allow_remote_control`**

In `kitty/.config/kitty/kitty.conf`, find the line (currently line 1775):

```
# allow_remote_control no
```

Replace it with:

```
# allow_remote_control no
allow_remote_control yes
```

- [ ] **Step 2: Set `listen_on` to a socket**

In the same file, find the line (currently line 1804):

```
# listen_on none
```

Replace it with:

```
# listen_on none
listen_on unix:@layout-fix-kitty
```

- [ ] **Step 3: Verify config validity**

Run: `kitty +runpy 'from kitty.config import load_config; load_config(["'"$PWD"'/kitty/.config/kitty/kitty.conf"]); print("ok")'`
Expected: prints `ok` with no parse errors. (If `+runpy` is unavailable in this kitty build, instead run `kitty --config kitty/.config/kitty/kitty.conf --version` and confirm no config-error lines are printed.)

> NOTE: remote control only takes effect in kitty windows started AFTER this change. Existing kitty windows (including any running this session) must be closed/reopened. Do NOT restart the kitty window running the implementation session mid-task — defer the live terminal smoke test to Task 5, run by the user in a fresh kitty window.

- [ ] **Step 4: Commit**

```bash
git add kitty/.config/kitty/kitty.conf
git commit -m "feat(kitty): enable remote control over socket for layout-fix

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 4: Side-effecting rewrite — clipboard preservation, deterministic timing, kitty safe-delete, auto layout-switch

**Files:**
- Modify: `scripts/.local/bin/layout-fix`

This rewrites the side-effecting section as one coherent change. The pure logic (`compute_states`, `convert_layout`, `target_language`) and the `clipboard_text`/`primary_text`/`require`/`run_text`/`notify` helpers are untouched.

- [ ] **Step 1: Add `import re` and tunable constants**

In `scripts/.local/bin/layout-fix`, find the import block (currently lines 2–7):

```python
import argparse
import shutil
import subprocess
import sys
import time
import glob
```

Replace it with:

```python
import argparse
import re
import shutil
import subprocess
import sys
import time
import glob


MOD_RELEASE_WAIT = 0.4        # let the user physically release Mod+G
PASTE_SETTLE_WAIT = 0.15      # after paste, before restoring the clipboard
CLIPBOARD_POLL_TIMEOUT = 0.5  # max wait for wl-copy to propagate
BACKSPACE_SETTLE = 0.05       # after terminal backspaces, before paste
KITTY_SOCKET = "unix:@layout-fix-kitty"
```

- [ ] **Step 2: Replace `paste_text` with the new helper functions**

Find the entire `paste_text` function (currently lines 156–175, from `def paste_text(` through the final `subprocess.run(["wtype", "-M", "ctrl", "-k", "v", "-m", "ctrl"], check=False)` and its surrounding `else:`). Replace the whole `paste_text` function with this block of helpers:

```python
def set_clipboard(text: str) -> None:
    run_text(["wl-copy", "--type", "text/plain"], text)


def wait_for_clipboard(expected: str, timeout: float) -> bool:
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        if clipboard_text() == expected:
            return True
        time.sleep(0.02)
    return False


def save_clipboard() -> tuple[str, bool]:
    """Return (text, restorable). restorable=False => clipboard held non-text data."""
    result = run_text(["wl-paste", "--no-newline", "--type", "text"])
    if result.returncode == 0:
        return result.stdout, True
    if "nothing is copied" in result.stderr.lower():
        return "", True  # empty clipboard; restore by clearing
    return "", False     # non-text content (e.g. an image)


def restore_clipboard(saved: str, restorable: bool) -> None:
    if not restorable:
        notify("layout-fix", "Clipboard held non-text data; not restored")
        return
    if saved == "":
        subprocess.run(["wl-copy", "--clear"], check=False)
    else:
        set_clipboard(saved)


def paste_combo(shift: bool) -> None:
    if shift:
        subprocess.run(["wtype", "-M", "ctrl", "-M", "shift", "-k", "v", "-m", "shift", "-m", "ctrl"], check=False)
    else:
        subprocess.run(["wtype", "-M", "ctrl", "-k", "v", "-m", "ctrl"], check=False)


def copy_combo(is_terminal: bool) -> None:
    if is_terminal:
        subprocess.run(["wtype", "-M", "ctrl", "-M", "shift", "-k", "c", "-m", "shift", "-m", "ctrl"], check=False)
    else:
        subprocess.run(["wtype", "-M", "ctrl", "-k", "c", "-m", "ctrl"], check=False)


def focused_is_kitty() -> bool:
    focused = subprocess.run(["niri", "msg", "focused-window"], stdout=subprocess.PIPE, text=True, check=False)
    return focused.returncode == 0 and 'App ID: "kitty"' in focused.stdout


def get_selection(is_terminal: bool) -> str:
    selected = primary_text()
    if not selected:
        # No primary selection: fall back to simulating Ctrl+C.
        copy_combo(is_terminal)
        time.sleep(0.2)
        selected = clipboard_text()
    return selected


def kitty_selection_at_cursor(selection: str) -> bool | None:
    """True if the selection is the text immediately before the kitty cursor,
    False if it is not, None if it cannot be determined."""
    result = run_text(["kitten", "@", "--to", KITTY_SOCKET, "get-text", "--extent=screen", "--add-cursor"])
    if result.returncode != 0 or not result.stdout:
        return None
    cursor = None
    for cursor in re.finditer(r"\x1b\[(\d+);(\d+)H", result.stdout):
        pass
    if cursor is None:
        return None
    row, col = int(cursor.group(1)), int(cursor.group(2))
    plain = re.sub(r"\x1b\[[0-9;?]*[A-Za-z]", "", result.stdout)
    lines = plain.split("\n")
    if row - 1 >= len(lines):
        return None
    before_cursor = lines[row - 1][: col - 1]
    return before_cursor.endswith(selection)


def switch_layout_for(lang: str | None) -> None:
    name_needle = {"heb": "hebrew", "eng": "english"}.get(lang or "")
    if not name_needle:
        return
    result = run_text(["niri", "msg", "keyboard-layouts"])
    if result.returncode != 0:
        return
    for line in result.stdout.splitlines():
        parts = line.lstrip(" *").split(None, 1)
        if len(parts) == 2 and parts[0].isdigit() and name_needle in parts[1].lower():
            subprocess.run(["niri", "msg", "action", "switch-layout", parts[0]], check=False)
            return


def do_replace(fixed: str, selected: str, is_terminal: bool) -> None:
    set_clipboard(fixed)
    if not wait_for_clipboard(fixed, CLIPBOARD_POLL_TIMEOUT):
        notify("layout-fix", "Clipboard sync slow")

    # Wait for the user to physically release Mod+G; a held Mod key can
    # corrupt terminal bracketed-paste sequences.
    time.sleep(MOD_RELEASE_WAIT)

    if not is_terminal:
        paste_combo(shift=False)
        return

    # Terminals: pasting does not replace the mouse selection, so the original
    # must be deleted by hand. Only delete when we can confirm the selection is
    # the text right before the cursor — otherwise we would eat unselected text.
    if kitty_selection_at_cursor(selected) is True:
        for _ in range(len(selected)):
            subprocess.run(["wtype", "-k", "BackSpace"], check=False)
        time.sleep(BACKSPACE_SETTLE)
        paste_combo(shift=True)
    else:
        paste_combo(shift=True)
        notify("layout-fix", "Original left in place — delete it manually")
```

> The `clipboard_text` and `primary_text` functions stay exactly where they are (immediately after this block in the file) — do not remove them; the new helpers call them.

- [ ] **Step 3: Rewrite `replace_selection`**

Find the entire `replace_selection` function (currently lines 188–219, from `def replace_selection() -> int:` through `    return 0`). Replace it with:

```python
def replace_selection() -> int:
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

- [ ] **Step 4: Syntax + regression check**

Run: `python3 -c "import ast; ast.parse(open('scripts/.local/bin/layout-fix').read()); print('syntax ok')"`
Expected: `syntax ok`.

Run: `./scripts/.local/bin/layout-fix-selftest`
Expected: PASS (the pure-logic paths are unchanged, so all cases still pass).

- [ ] **Step 5: Commit**

```bash
git add scripts/.local/bin/layout-fix
git commit -m "feat(layout-fix): preserve clipboard, deterministic paste, kitty safe-delete, auto layout-switch

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 5: Verification, manual smoke test, and docs reconcile

**Files:**
- Modify: `docs/agent-reference/niri-keybinds.md`

- [ ] **Step 1: Run the automated selftest gate**

Run: `./scripts/.local/bin/layout-fix-selftest`
Expected: PASS with the full case count. This is the completion gate for the pure logic.

- [ ] **Step 2: User manual smoke test (side-effecting paths)**

These require a live niri/kitty session and must be run by the user. The kitty cases require a kitty window opened AFTER Task 3 (remote control is per-window at launch). Ask the user to confirm each:

1. **GUI app (e.g. browser/Zed):** type a word in the wrong layout, select it, press `Mod+G`.
   Expect: text replaced in place; the clipboard you had before is unchanged; the keyboard layout switched to the converted-to language.
2. **kitty, selection at end of line:** type a wrong-layout word at the prompt, mouse-select it (cursor stays at line end), press `Mod+G`.
   Expect: word replaced in place, nothing extra deleted.
3. **kitty, partial mid-line selection:** type `hello world foo`, mouse-select only `world`, press `Mod+G`.
   Expect: correction pasted at the cursor + a notification "Original left in place — delete it manually"; NO over-deletion of `foo`.
4. **Remote control off (regression safety):** confirm that if kitty remote control is unavailable, case 2/3 still fall back to the non-destructive paste rather than over-deleting. (Optional — verify by testing in an old kitty window opened before Task 3.)

If any case fails, debug before proceeding (use superpowers:systematic-debugging). Likely tuning points: `MOD_RELEASE_WAIT` / `CLIPBOARD_POLL_TIMEOUT` constants, or the `KITTY_SOCKET` value if `kitten @ --to unix:@layout-fix-kitty ls` does not reach the focused window.

- [ ] **Step 3: Reconcile the keybind reference doc**

In `docs/agent-reference/niri-keybinds.md`, find the Mod+G row in the keybind table:

```
| `Mod+G` | fix selected Hebrew/English wrong-layout text | ✓ |
```

Replace it with:

```
| `Mod+G` | fix selected Hebrew/English wrong-layout text, then switch keyboard layout to the corrected language | ✓ |
```

- [ ] **Step 4: Commit**

```bash
git add docs/agent-reference/niri-keybinds.md
git commit -m "docs(keybinds): note Mod+G now switches layout after fixing

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Self-Review Notes

- **Spec coverage:** clipboard preservation → Task 4 (`save_clipboard`/`restore_clipboard`, `finally`); deterministic timing → Task 4 (`wait_for_clipboard`, named constants); terminal safe-delete → Task 3 (kitty.conf) + Task 4 (`kitty_selection_at_cursor`, `do_replace`); auto layout-switch → Task 4 (`switch_layout_for`, `target_language`); testing → Task 1/2 (selftest) + Task 5 (smoke checklist); docs reconcile → Task 5.
- **Caps-lock test deviation:** the spec listed an automated caps-lock case. `convert_layout` reads the live caps-lock LED, which a subprocess selftest cannot force, so caps-lock behavior is covered by the manual smoke test instead of an automated case. Documented here intentionally.
- **Type consistency:** `target_language` returns `"heb" | "eng" | None`; `switch_layout_for` consumes exactly those; `kitty_selection_at_cursor` returns `True | False | None` and `do_replace` checks `is True`. Helper names referenced in `replace_selection`/`do_replace` are all defined in Task 4.
