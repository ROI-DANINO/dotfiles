# Brand-Anchored Desktop Theme Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Apply Roi Danino's brand palette to active Niri desktop color configs, with warm Navy/Sky Blue/Cream styling and transparent surfaces where readability remains strong.

**Architecture:** Add one tracked palette reference as the source of truth, then hand-apply the token mapping to each active config. Keep changes visual-only: no keybind edits, no service/startup changes, no `system/` changes, and no Alacritty changes.

**Tech Stack:** Niri KDL, Kitty config, Waybar CSS/JSONC, SwayNC JSON/CSS, Zellij KDL, Powerlevel10k zsh config, GTK/Pango Python overlay scripts.

---

## File Map

- Create `docs/theme/brand-desktop-palette.md`: durable palette/token reference for future edits.
- Modify `niri/.config/niri/config.kdl`: focus ring colors only.
- Modify `kitty/.config/kitty/kitty.conf`: tab colors, terminal palette, selection, cursor, opacity.
- Modify `waybar/.config/waybar/style.css`: bar/module colors and state colors.
- Create `swaync/.config/swaync/style.css`: brand styling for notifications/control center.
- Modify `zellij/.config/zellij/config.kdl`: replace current `cosmic` theme RGB values.
- Modify `shell/.p10k.zsh`: conservative 256-color remap for visible prompt segments.
- Modify `niri/.config/niri/sysbar`: hardcoded Pango colors and Cairo overlay background.
- Modify `scripts/.local/bin/wsbar`: hardcoded Pango color and Cairo overlay background.

## Constraints

- Do not edit `alacritty/`.
- Do not change Niri keybinds.
- Do not run `sudo`.
- Do not reload live services until after diffs are reviewed.
- Do not touch `system/`.
- Keep `.superpowers/` ignored and uncommitted.

---

### Task 1: Add Palette Reference

**Files:**
- Create: `docs/theme/brand-desktop-palette.md`

- [ ] **Step 1: Create the theme docs directory**

Run:

```bash
mkdir -p docs/theme
```

Expected: command exits with code 0.

- [ ] **Step 2: Add the palette reference**

Create `docs/theme/brand-desktop-palette.md` with this content:

```markdown
# Brand Desktop Palette

Source spec: `docs/superpowers/specs/2026-05-31-brand-anchored-desktop-theme-design.md`

## Official Brand Colors

| Token | Hex | Use |
|---|---:|---|
| `brand-sky` | `#C8D9E6` | Focus, selected states, soft highlights |
| `brand-navy` | `#2F4156` | Main dark brand base |
| `brand-teal` | `#567C8D` | Borders, icons, secondary accents |
| `brand-cream` | `#F0E7D5` | Warm text/cards/soft surfaces |
| `brand-white` | `#FFFFFF` | Highest contrast on dark surfaces |

## Desktop Derived Colors

| Token | Hex | Use |
|---|---:|---|
| `navy-deep` | `#1E3045` | Terminal background and deeper panels |
| `navy-ink` | `#081A2F` | Deepest terminal black/shadow |
| `sky-muted` | `#9FB4C1` | Muted text on dark surfaces |
| `cream-muted` | `#D8CBB7` | Muted warm text |
| `success` | `#A8C9B0` | Healthy/charging/good |
| `warning` | `#E0B66C` | Warning only |
| `danger` | `#C9856F` | Critical/error/urgent |
| `selection` | `#C8D9E6` | Selection background on dark surfaces |

## Transparency Defaults

- Kitty: start with `background_opacity 0.86`.
- Waybar: use translucent Navy/deep Navy surfaces.
- SwayNC: prefer translucent control-center shell; keep cards readable.
- GTK overlay bars: use translucent Navy.

## Rules

- Brand colors stay exact when used as brand tokens.
- No gold as an accent.
- No neon/electric blue.
- No Alacritty changes in this pass.
- Preserve readability over transparency when they conflict.
```

- [ ] **Step 3: Verify the new file is tracked in diff**

Run:

```bash
git diff -- docs/theme/brand-desktop-palette.md
```

Expected: diff shows only the new palette reference.

- [ ] **Step 4: Commit**

Run:

```bash
git add docs/theme/brand-desktop-palette.md
git commit -m "Add brand desktop palette reference"
```

Expected: commit succeeds.

---

### Task 2: Update Niri Focus Ring

**Files:**
- Modify: `niri/.config/niri/config.kdl`

- [ ] **Step 1: Inspect the existing focus-ring block**

Run:

```bash
sed -n '84,94p' niri/.config/niri/config.kdl
```

Expected current block:

```kdl
    focus-ring {
        width 3
        active-color "#cabab4"
        inactive-color "#4a3e38"
    }
```

- [ ] **Step 2: Change only the two color values**

Edit the block to:

```kdl
    focus-ring {
        width 3
        active-color "#C8D9E6"
        inactive-color "#567C8D"
    }
```

- [ ] **Step 3: Verify no keybinds changed**

Run:

```bash
git diff -- niri/.config/niri/config.kdl
```

Expected: diff contains only `active-color` and `inactive-color`.

- [ ] **Step 4: Validate by inspection**

Run:

```bash
rg -n 'focus-ring|active-color|inactive-color|Mod\\+' niri/.config/niri/config.kdl
```

Expected: new colors appear; keybind lines are unchanged in the diff.

- [ ] **Step 5: Commit**

Run:

```bash
git add niri/.config/niri/config.kdl
git commit -m "Apply brand colors to niri focus ring"
```

Expected: commit succeeds.

---

### Task 3: Update Kitty Theme and Transparency

**Files:**
- Modify: `kitty/.config/kitty/kitty.conf`

- [ ] **Step 1: Inspect the active Kitty theme block**

Run:

```bash
sed -n '2988,3058p' kitty/.config/kitty/kitty.conf
```

Expected: active tab colors, `background_opacity`, foreground/background/cursor, selection, and ANSI colors are visible.

- [ ] **Step 2: Replace active theme values**

Update the active block near the bottom of `kitty.conf` to these values:

```conf
# Tab colors
active_tab_foreground   #2F4156
active_tab_background   #C8D9E6
inactive_tab_foreground #9FB4C1
inactive_tab_background #1E3045
tab_bar_background      #081A2F
```

```conf
# Transparent brand navy terminal
background_opacity 0.86

# Roi Danino brand desktop palette
foreground #F0E7D5
background #1E3045
cursor     #C8D9E6

selection_foreground #2F4156
selection_background #C8D9E6

# Normal
color0  #081A2F
color1  #C9856F
color2  #A8C9B0
color3  #E0B66C
color4  #C8D9E6
color5  #9FB4C1
color6  #567C8D
color7  #F0E7D5

# Bright
color8  #2F4156
color9  #D99A86
color10 #BBD7C1
color11 #E8C987
color12 #FFFFFF
color13 #D8CBB7
color14 #C8D9E6
color15 #FFFFFF
```

- [ ] **Step 3: Verify single active opacity setting**

Run:

```bash
rg -n '^background_opacity|^foreground |^background |^cursor |^selection_|^color[0-9]+|^active_tab_|^inactive_tab_|^tab_bar_background' kitty/.config/kitty/kitty.conf
```

Expected: the active uncommented theme values match Step 2. Commented default examples elsewhere may still exist.

- [ ] **Step 4: Check Kitty config parses**

Run:

```bash
kitty --debug-config --config kitty/.config/kitty/kitty.conf
```

Expected: command exits 0 and does not report invalid config directives.

- [ ] **Step 5: Commit**

Run:

```bash
git add kitty/.config/kitty/kitty.conf
git commit -m "Apply transparent brand theme to kitty"
```

Expected: commit succeeds.

---

### Task 4: Update Waybar Styling

**Files:**
- Modify: `waybar/.config/waybar/style.css`

- [ ] **Step 1: Replace the top palette comment**

Replace the existing COSMIC palette comment at the top of `style.css` with:

```css
/* Waybar Style - Roi Danino Brand Desktop Theme

   brand-sky:    #C8D9E6
   brand-navy:   #2F4156
   brand-teal:   #567C8D
   brand-cream:  #F0E7D5
   brand-white:  #FFFFFF
   navy-deep:    #1E3045
   navy-ink:     #081A2F
   sky-muted:    #9FB4C1
   cream-muted:  #D8CBB7
   success:      #A8C9B0
   warning:      #E0B66C
   danger:       #C9856F
*/
```

- [ ] **Step 2: Apply core Waybar surface colors**

Set these selectors to the following values:

```css
window#waybar {
    background: rgba(47, 65, 86, 0.82);
    border-radius: 8px;
    color: #F0E7D5;
}

tooltip {
    background: rgba(30, 48, 69, 0.96);
    border: 1px solid #567C8D;
    border-radius: 8px;
}

tooltip label {
    color: #F0E7D5;
    padding: 4px;
}
```

- [ ] **Step 3: Apply workspace/window colors**

Set the workspace/window selectors to:

```css
#workspaces button {
    padding: 0 8px;
    margin: 4px 2px;
    border-radius: 6px;
    background: transparent;
    color: #C8D9E6;
    transition: all 0.2s ease;
}

#workspaces button:hover {
    background: rgba(200, 217, 230, 0.18);
    color: #FFFFFF;
}

#workspaces button.active {
    background: #C8D9E6;
    color: #2F4156;
}

#workspaces button.urgent {
    background: rgba(201, 133, 111, 0.22);
    color: #C9856F;
}

#window {
    margin: 0 12px;
    color: #D8CBB7;
}
```

- [ ] **Step 4: Apply module and state colors**

Use these values for visible module colors:

```css
#cpu,
#memory,
#custom-battery {
    background: rgba(30, 48, 69, 0.72);
    color: #F0E7D5;
}

#cpu:hover,
#memory:hover,
#network:hover,
#bluetooth:hover,
#pulseaudio:hover,
#backlight:hover,
#custom-swaync:hover {
    background: rgba(200, 217, 230, 0.16);
}

#cpu { color: #C8D9E6; }
#memory { color: #A8C9B0; }
#network { color: #C8D9E6; }
#network.disconnected { color: #9FB4C1; }
#bluetooth { color: #567C8D; }
#bluetooth.connected { color: #C8D9E6; }
#pulseaudio { color: #F0E7D5; }
#pulseaudio.muted { color: #9FB4C1; }
#backlight { color: #F0E7D5; }

#custom-battery.charging {
    color: #A8C9B0;
    background: rgba(168, 201, 176, 0.14);
}

#custom-battery.good { color: #A8C9B0; }
#custom-battery.warning { color: #E0B66C; }

#custom-battery.critical {
    color: #C9856F;
    animation: blink 1s linear infinite;
}

#custom-battery.health-limit { color: #F0E7D5; }

@keyframes blink {
    to {
        color: #C9856F;
        background: rgba(201, 133, 111, 0.22);
    }
}

#custom-swaync { color: #C8D9E6; }

#clock {
    background: rgba(200, 217, 230, 0.18);
    color: #FFFFFF;
}

#clock:hover {
    background: rgba(200, 217, 230, 0.28);
}
```

Keep existing spacing, padding, margins, and border radii unless the selector is shown above.

- [ ] **Step 5: Verify CSS color replacement**

Run:

```bash
rg -n '#[0-9A-Fa-f]{6}|rgba\\(' waybar/.config/waybar/style.css
```

Expected: visible colors use the brand palette or derived tokens from `docs/theme/brand-desktop-palette.md`.

- [ ] **Step 6: Syntax smoke test**

Run:

```bash
python3 - <<'PY'
from pathlib import Path
p = Path('waybar/.config/waybar/style.css')
text = p.read_text()
assert text.count('{') == text.count('}'), 'Unbalanced CSS braces'
print('Waybar CSS brace check OK')
PY
```

Expected: `Waybar CSS brace check OK`.

- [ ] **Step 7: Commit**

Run:

```bash
git add waybar/.config/waybar/style.css
git commit -m "Apply brand theme to waybar"
```

Expected: commit succeeds.

---

### Task 5: Add SwayNC Brand Stylesheet

**Files:**
- Create: `swaync/.config/swaync/style.css`
- Inspect: `swaync/.config/swaync/config.json`

- [ ] **Step 1: Confirm SwayNC config uses user CSS priority**

Run:

```bash
rg -n '"cssPriority"|style.css|widgets' swaync/.config/swaync/config.json
```

Expected: `"cssPriority": "user"` exists.

- [ ] **Step 2: Create `style.css`**

Create `swaync/.config/swaync/style.css`:

```css
* {
    font-family: "Inter", "Assistant", "JetBrainsMono Nerd Font Mono", sans-serif;
    color: #F0E7D5;
}

.control-center {
    background: rgba(47, 65, 86, 0.88);
    border: 1px solid #567C8D;
    border-radius: 8px;
}

.notification-row {
    outline: none;
}

.notification {
    background: rgba(240, 231, 213, 0.94);
    border: 1px solid #C8D9E6;
    border-radius: 8px;
    color: #2F4156;
}

.notification-content,
.summary,
.body {
    color: #2F4156;
}

.time,
.notification-default-action,
.close-button {
    color: #567C8D;
}

.notification.critical {
    border-color: #C9856F;
}

.notification.critical .summary {
    color: #C9856F;
}

.control-center .notification {
    background: rgba(240, 231, 213, 0.92);
}

.widget-title,
.widget-dnd,
.widget-inhibitors {
    color: #F0E7D5;
    background: transparent;
}

button {
    background: #C8D9E6;
    color: #2F4156;
    border: 0;
    border-radius: 6px;
    padding: 6px 10px;
}

button:hover {
    background: #FFFFFF;
}
```

- [ ] **Step 3: Verify stylesheet braces**

Run:

```bash
python3 - <<'PY'
from pathlib import Path
p = Path('swaync/.config/swaync/style.css')
text = p.read_text()
assert text.count('{') == text.count('}'), 'Unbalanced CSS braces'
print('SwayNC CSS brace check OK')
PY
```

Expected: `SwayNC CSS brace check OK`.

- [ ] **Step 4: Commit**

Run:

```bash
git add swaync/.config/swaync/style.css
git commit -m "Add brand theme for swaync"
```

Expected: commit succeeds.

---

### Task 6: Update Zellij Theme

**Files:**
- Modify: `zellij/.config/zellij/config.kdl`

- [ ] **Step 1: Inspect current theme block**

Run:

```bash
sed -n '287,418p' zellij/.config/zellij/config.kdl
```

Expected: `themes { cosmic { ... } }` block is visible.

- [ ] **Step 2: Replace the `cosmic` theme block**

Replace only the body of `cosmic { ... }` with RGB values matching this mapping:

```kdl
        text_unselected {
            base 240 231 213
            background 47 65 86
            emphasis_0 201 133 111
            emphasis_1 168 201 176
            emphasis_2 224 182 108
            emphasis_3 86 124 141
        }
        text_selected {
            base 47 65 86
            background 200 217 230
            emphasis_0 201 133 111
            emphasis_1 168 201 176
            emphasis_2 224 182 108
            emphasis_3 86 124 141
        }
        ribbon_unselected {
            base 216 203 183
            background 30 48 69
            emphasis_0 201 133 111
            emphasis_1 168 201 176
            emphasis_2 224 182 108
            emphasis_3 86 124 141
        }
        ribbon_selected {
            base 47 65 86
            background 200 217 230
            emphasis_0 201 133 111
            emphasis_1 168 201 176
            emphasis_2 224 182 108
            emphasis_3 86 124 141
        }
        table_title {
            base 200 217 230
            background 47 65 86
            emphasis_0 201 133 111
            emphasis_1 168 201 176
            emphasis_2 224 182 108
            emphasis_3 86 124 141
        }
        table_cell_unselected {
            base 240 231 213
            background 47 65 86
            emphasis_0 201 133 111
            emphasis_1 168 201 176
            emphasis_2 224 182 108
            emphasis_3 86 124 141
        }
        table_cell_selected {
            base 47 65 86
            background 200 217 230
            emphasis_0 201 133 111
            emphasis_1 168 201 176
            emphasis_2 224 182 108
            emphasis_3 86 124 141
        }
        list_unselected {
            base 216 203 183
            background 47 65 86
            emphasis_0 201 133 111
            emphasis_1 168 201 176
            emphasis_2 224 182 108
            emphasis_3 86 124 141
        }
        list_selected {
            base 47 65 86
            background 200 217 230
            emphasis_0 201 133 111
            emphasis_1 168 201 176
            emphasis_2 224 182 108
            emphasis_3 86 124 141
        }
        frame_unselected {
            base 86 124 141
            background 47 65 86
            emphasis_0 201 133 111
            emphasis_1 168 201 176
            emphasis_2 224 182 108
            emphasis_3 86 124 141
        }
        frame_selected {
            base 200 217 230
            background 47 65 86
            emphasis_0 201 133 111
            emphasis_1 168 201 176
            emphasis_2 224 182 108
            emphasis_3 86 124 141
        }
        frame_highlight {
            base 200 217 230
            background 47 65 86
            emphasis_0 201 133 111
            emphasis_1 168 201 176
            emphasis_2 224 182 108
            emphasis_3 86 124 141
        }
        exit_code_success {
            base 168 201 176
            emphasis_0 201 133 111
            emphasis_1 168 201 176
            emphasis_2 224 182 108
            emphasis_3 86 124 141
        }
        exit_code_error {
            base 201 133 111
            emphasis_0 201 133 111
            emphasis_1 168 201 176
            emphasis_2 224 182 108
            emphasis_3 86 124 141
        }
        multiplayer_user_colors {
            player_1 201 133 111
            player_2 168 201 176
            player_3 86 124 141
            player_4 224 182 108
            player_5 200 217 230
            player_6 216 203 183
            player_7 159 180 193
            player_8 240 231 213
            player_9 255 255 255
            player_10 47 65 86
        }
```

- [ ] **Step 3: Confirm active theme remains `cosmic`**

Run:

```bash
rg -n '^theme "cosmic"|themes \\{|cosmic \\{' zellij/.config/zellij/config.kdl
```

Expected: `theme "cosmic"` remains active.

- [ ] **Step 4: Commit**

Run:

```bash
git add zellij/.config/zellij/config.kdl
git commit -m "Apply brand palette to zellij theme"
```

Expected: commit succeeds.

---

### Task 7: Update Overlay Bar Scripts

**Files:**
- Modify: `niri/.config/niri/sysbar`
- Modify: `scripts/.local/bin/wsbar`

- [ ] **Step 1: Update `niri/.config/niri/sysbar` colors**

In `build_markup`, use:

```python
    net_icon, net_color = {
        'wifi': ('📡', '#C8D9E6'),
        'eth':  ('🔌', '#A8C9B0'),
        'none': ('✖ no net', '#C9856F'),
    }[net]
    return (
        f'<span foreground="#C8D9E6" font="monospace 13">{ws}</span>  '
        f'<span foreground="{net_color}" font="monospace 13">{net_icon}</span>  '
        + bat_span
        + f'<span foreground="#F0E7D5" font="monospace 13">{get_ram_gb()}</span>'
        f'  '
        f'<span foreground="#FFFFFF" font="monospace 13">{get_time()}</span>'
    )
```

In `update`, set battery colors:

```python
        color = '#A8C9B0' if charging else '#C9856F'
```

In `blink_tick`, set:

```python
        color = '#C9856F'
```

In `on_draw`, set the translucent background:

```python
        cr.set_source_rgba(47/255, 65/255, 86/255, 0.84)
```

- [ ] **Step 2: Update `scripts/.local/bin/wsbar` colors**

In `make_markup`, set:

```python
    return f'<span foreground="#C8D9E6" font="monospace 13">{text}</span>'
```

In `on_draw`, set:

```python
        cr.set_source_rgba(47/255, 65/255, 86/255, 0.84)
```

- [ ] **Step 3: Python syntax check**

Run:

```bash
python3 -m py_compile niri/.config/niri/sysbar scripts/.local/bin/wsbar
```

Expected: command exits 0.

- [ ] **Step 4: Remove generated pycache if created**

Run:

```bash
find niri scripts -type d -name __pycache__ -print
```

Expected: if any `__pycache__` directories appear, remove only those generated directories after confirming paths.

- [ ] **Step 5: Commit**

Run:

```bash
git add niri/.config/niri/sysbar scripts/.local/bin/wsbar
git commit -m "Apply brand colors to overlay bars"
```

Expected: commit succeeds.

---

### Task 8: Update Powerlevel10k Conservatively

**Files:**
- Modify: `shell/.p10k.zsh`

- [ ] **Step 1: Identify visible 256-color values**

Run:

```bash
rg -n 'POWERLEVEL9K_(MULTILINE|RULER|DIR|VCS|STATUS|COMMAND_EXECUTION_TIME|BACKGROUND_JOBS|DIRENV|RAM|LOAD|TIME|BATTERY|WIFI).*FOREGROUND|%[0-9]{1,3}F' shell/.p10k.zsh
```

Expected: visible prompt segment color lines are listed.

- [ ] **Step 2: Apply conservative 256-color mapping**

Use nearest xterm values:

```text
brand-sky   #C8D9E6 -> 153
brand-navy  #2F4156 -> 24
brand-teal  #567C8D -> 66
brand-cream #F0E7D5 -> 230
sky-muted   #9FB4C1 -> 109
success     #A8C9B0 -> 151
warning     #E0B66C -> 179
danger      #C9856F -> 174
```

Change these active assignments:

```zsh
typeset -g POWERLEVEL9K_MULTILINE_FIRST_PROMPT_PREFIX='%109F╭─'
typeset -g POWERLEVEL9K_MULTILINE_NEWLINE_PROMPT_PREFIX='%109F├─'
typeset -g POWERLEVEL9K_MULTILINE_LAST_PROMPT_PREFIX='%109F╰─'
typeset -g POWERLEVEL9K_RULER_FOREGROUND=109
typeset -g POWERLEVEL9K_MULTILINE_FIRST_PROMPT_GAP_FOREGROUND=109
typeset -g POWERLEVEL9K_DIR_FOREGROUND=153
typeset -g POWERLEVEL9K_DIR_SHORTENED_FOREGROUND=109
typeset -g POWERLEVEL9K_DIR_ANCHOR_FOREGROUND=153
typeset -g POWERLEVEL9K_VCS_VISUAL_IDENTIFIER_COLOR=151
typeset -g POWERLEVEL9K_VCS_LOADING_VISUAL_IDENTIFIER_COLOR=109
typeset -g POWERLEVEL9K_VCS_CLEAN_FOREGROUND=151
typeset -g POWERLEVEL9K_VCS_UNTRACKED_FOREGROUND=153
typeset -g POWERLEVEL9K_VCS_MODIFIED_FOREGROUND=179
typeset -g POWERLEVEL9K_STATUS_OK_FOREGROUND=151
typeset -g POWERLEVEL9K_STATUS_OK_PIPE_FOREGROUND=151
typeset -g POWERLEVEL9K_STATUS_ERROR_FOREGROUND=174
typeset -g POWERLEVEL9K_STATUS_ERROR_SIGNAL_FOREGROUND=174
typeset -g POWERLEVEL9K_STATUS_ERROR_PIPE_FOREGROUND=174
typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_FOREGROUND=230
typeset -g POWERLEVEL9K_BACKGROUND_JOBS_FOREGROUND=153
typeset -g POWERLEVEL9K_DIRENV_FOREGROUND=179
typeset -g POWERLEVEL9K_RAM_FOREGROUND=230
typeset -g POWERLEVEL9K_LOAD_NORMAL_FOREGROUND=151
typeset -g POWERLEVEL9K_LOAD_WARNING_FOREGROUND=179
typeset -g POWERLEVEL9K_LOAD_CRITICAL_FOREGROUND=174
typeset -g POWERLEVEL9K_BATTERY_LOW_FOREGROUND=174
typeset -g POWERLEVEL9K_BATTERY_DISCONNECTED_FOREGROUND=179
typeset -g POWERLEVEL9K_WIFI_FOREGROUND=153
typeset -g POWERLEVEL9K_TIME_FOREGROUND=153
```

If a variable appears twice, update the last active assignment too, because later lines override earlier lines.

- [ ] **Step 3: Syntax check**

Run:

```bash
zsh -n shell/.p10k.zsh
```

Expected: command exits 0.

- [ ] **Step 4: Commit**

Run:

```bash
git add shell/.p10k.zsh
git commit -m "Align prompt colors with brand theme"
```

Expected: commit succeeds.

---

### Task 9: Final Verification and Review

**Files:**
- Verify all touched files.

- [ ] **Step 1: Confirm no excluded files changed**

Run:

```bash
git diff HEAD~8 --name-only
```

Expected files are limited to:

```text
docs/theme/brand-desktop-palette.md
niri/.config/niri/config.kdl
kitty/.config/kitty/kitty.conf
waybar/.config/waybar/style.css
swaync/.config/swaync/style.css
zellij/.config/zellij/config.kdl
shell/.p10k.zsh
niri/.config/niri/sysbar
scripts/.local/bin/wsbar
```

- [ ] **Step 2: Search for old visible theme colors**

Run:

```bash
rg -n '#cabab4|#4a3e38|#58a6ff|#0d1117|#e79cfe|#615449|#1e1814' niri kitty waybar zellij shell scripts swaync
```

Expected: no active visible uses remain in touched theme areas. Commented defaults in Kitty may be left alone only if clearly comments.

- [ ] **Step 3: Run local syntax checks**

Run:

```bash
python3 -m py_compile niri/.config/niri/sysbar scripts/.local/bin/wsbar
zsh -n shell/.p10k.zsh
python3 - <<'PY'
from pathlib import Path
for name in ['waybar/.config/waybar/style.css', 'swaync/.config/swaync/style.css']:
    text = Path(name).read_text()
    assert text.count('{') == text.count('}'), f'Unbalanced CSS braces: {name}'
print('CSS brace checks OK')
PY
```

Expected: all commands exit 0.

- [ ] **Step 4: Review diff before live reload**

Run:

```bash
git log --oneline -9
git diff HEAD~8..HEAD --stat
```

Expected: recent commits show one commit per task and only intended files changed.

- [ ] **Step 5: Ask before live reload**

Do not run reload commands automatically. Present these optional commands to Roi for manual/live application:

```bash
niri msg action reload-config
pkill waybar && waybar
swaync-client -rs
```

Expected: wait for user confirmation before any live reload/restart command.
