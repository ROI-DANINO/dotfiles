# Theming Expansion Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add brand palette theming (navy/cream/teal/sky) to Wob, Walker, and Zed via new stow modules in `~/dotfiles/`.

**Architecture:** Three independent stow modules, each creating config files that are symlinked into `~/.config/` by stow. Wob and Walker have no existing tracked config. Zed's live `settings.json` is copied into the module first, then the theme block is modified. Walker CSS selectors must be verified with GTK Inspector before writing the stylesheet.

**Tech Stack:** stow, wob 0.15.1 (INI config), Walker (GTK4 YAML + CSS), Zed (JSON theme schema v0.2.0)

---

## File Map

| Action | Path |
|---|---|
| Create | `dotfiles/wob/.config/wob/wob.ini` |
| Create | `dotfiles/walker/.config/walker/config.yaml` |
| Create | `dotfiles/walker/.config/walker/style.css` |
| Create | `dotfiles/zed/.config/zed/themes/brand.json` |
| Create (seed from live) | `dotfiles/zed/.config/zed/settings.json` |
| Modify | `dotfiles/packages.md` |

---

## Task 1: Wob stow module

**Files:**
- Create: `dotfiles/wob/.config/wob/wob.ini`

- [ ] **Step 1: Create the module directory**

```bash
mkdir -p ~/dotfiles/wob/.config/wob
```

- [ ] **Step 2: Write wob.ini**

```ini
[default]
background_color=1E3045E0
bar_color=F0E7D5FF
border_color=567C8DFF
border_size=1
bar_padding=4
height=24
width=400
anchor=bottom center
margin=0 0 48 0
```

Save to `~/dotfiles/wob/.config/wob/wob.ini`.

- [ ] **Step 3: Stow the module**

```bash
cd ~/dotfiles && stow wob
```

Expected: no output, no conflicts. If you get a conflict it means `~/.config/wob/wob.ini` already exists — remove it first with `rm ~/.config/wob/wob.ini`, then re-run stow.

- [ ] **Step 4: Restart wob daemon and verify**

```bash
pkill wob
~/.local/bin/wob-daemon &
```

Then press a volume key (`XF86AudioRaiseVolume`). The OSD should appear: navy-translucent background, cream fill bar, teal border. If the bar does not appear, check that `~/.config/wob/wob.ini` is a symlink:

```bash
ls -la ~/.config/wob/wob.ini
```

- [ ] **Step 5: Commit**

```bash
cd ~/dotfiles
git add wob/
git commit -m "Add wob stow module with brand palette theme"
```

---

## Task 2: Walker stow module

Walker is a GTK4 app — CSS selector names depend on Walker's widget tree and must be verified before writing `style.css`. This task includes an inspection step.

**Files:**
- Create: `dotfiles/walker/.config/walker/config.yaml`
- Create: `dotfiles/walker/.config/walker/style.css`

- [ ] **Step 1: Create the module directories**

```bash
mkdir -p ~/dotfiles/walker/.config/walker
```

- [ ] **Step 2: Write a minimal config.yaml**

Walker does not auto-generate a config — it runs fine with no config file at all. Write a minimal one to track the providers we want:

```bash
cat > ~/dotfiles/walker/.config/walker/config.yaml << 'EOF'
# Walker launcher config
# Docs: https://benz.gitbook.io/walker/
builtins:
  applications: {}
  calc: {}
EOF
```

If Walker fails to launch after stowing (Step 6), check the Walker docs at https://benz.gitbook.io/walker/ under "Configuration" for the correct YAML schema — the key names above are based on the documented format but may have changed in newer versions. A valid empty config (`{}`) also works since Walker defaults to enabling applications.

- [ ] **Step 3: Confirm Walker is not broken by the new config**

Walker is currently running as a gapplication-service. Do NOT kill it at this stage — we'll restart it after stowing in Step 7. The config.yaml is only read at startup, so the live service is unaffected until then.

- [ ] **Step 4: Inspect Walker's GTK4 widget tree to get real selector names**

```bash
GTK_DEBUG=interactive walker &
```

This opens Walker with the GTK Inspector attached. In the Inspector's "Objects" tab, expand the widget tree to find:
- The root window widget name/ID
- The search entry widget name/class
- The result row widget name/class

Record these — you need them for Step 5. Common GTK4 names are `window`, `entry`, `row`, `label`. Close Walker when done.

- [ ] **Step 5: Write style.css using the real selector names**

Using the actual selector names from Step 4, write `~/dotfiles/walker/.config/walker/style.css`. The template below uses likely names — replace any that differ from what GTK Inspector showed:

```css
window {
  background: rgba(47, 65, 86, 0.92);
  border: 1px solid #567C8D;
  border-radius: 12px;
}

entry {
  color: #F0E7D5;
  caret-color: #C8D9E6;
  background: transparent;
  border: none;
  box-shadow: none;
  padding: 10px 14px;
}

entry placeholder {
  color: #9FB4C1;
}

row {
  color: #9FB4C1;
  padding: 6px 14px;
  border-radius: 0;
}

row:selected,
row:focus {
  background: rgba(200, 217, 230, 0.12);
  color: #F0E7D5;
  border-left: 2px solid #C8D9E6;
}
```

**If the styles don't apply** after stowing and restarting Walker, re-open with `GTK_DEBUG=interactive walker`, right-click the unstyled element in the Inspector, choose "Copy CSS selector", and update `style.css` with the correct selector.

- [ ] **Step 6: Stow the module**

```bash
cd ~/dotfiles && stow walker
```

Expected: no output. Verify symlinks exist:

```bash
ls -la ~/.config/walker/
```

Both `config.yaml` and `style.css` should be symlinks pointing into `~/dotfiles/walker/`.

- [ ] **Step 7: Restart Walker service and verify**

Walker runs as a gapplication-service started by niri. Kill it and let niri respawn it:

```bash
pkill walker
sleep 1
# niri will respawn it automatically via spawn-at-startup
```

Wait 2 seconds then press `Mod+Slash`. The launcher should appear with navy-translucent background, teal border, cream search text, and sky-blue left-bar on the selected row.

If Walker does not respawn automatically, start it manually:

```bash
walker --gapplication-service &
```

- [ ] **Step 8: Commit**

```bash
cd ~/dotfiles
git add walker/
git commit -m "Add walker stow module with brand palette theme"
```

---

## Task 3: Zed stow module

Zed built-in themes are compiled into the binary — there is no theme JSON file to copy as a template. The plan includes the complete `brand.json` content below. `settings.json` must be seeded from the live file to preserve all existing settings.

**Files:**
- Create: `dotfiles/zed/.config/zed/themes/brand.json`
- Create (seed from live): `dotfiles/zed/.config/zed/settings.json`

- [ ] **Step 1: Create the module directories**

```bash
mkdir -p ~/dotfiles/zed/.config/zed/themes
```

- [ ] **Step 2: Seed settings.json from the live file**

```bash
cp ~/.config/zed/settings.json ~/dotfiles/zed/.config/zed/settings.json
```

- [ ] **Step 3: Update the theme block in settings.json**

Open `~/dotfiles/zed/.config/zed/settings.json`. Replace the existing `theme` block:

```json
  "theme": {
    "mode": "system",
    "light": "Gruvbox Light",
    "dark": "Gruvbox Dark",
  },
```

with:

```json
  "theme": {
    "mode": "dark",
    "dark": "Brand Navy"
  },
```

All other settings (agent panel, font sizes, panels, keymaps) stay exactly as they are.

- [ ] **Step 4: Write themes/brand.json**

Save the following as `~/dotfiles/zed/.config/zed/themes/brand.json`:

```json
{
  "$schema": "https://zed.dev/schema/themes/v0.2.0.json",
  "name": "Brand Navy",
  "author": "Roi Danino",
  "themes": [
    {
      "name": "Brand Navy",
      "appearance": "dark",
      "style": {
        "background": "#1E3045",
        "foreground": "#F0E7D5",
        "border": "#567C8D",
        "border.variant": "#2F4156",
        "border.focused": "#C8D9E6",
        "border.selected": "#C8D9E6",
        "border.transparent": "#00000000",
        "border.disabled": "#081A2F",
        "elevated_surface.background": "#2F4156",
        "surface.background": "#2F4156",
        "element.background": "#2F4156",
        "element.hover": "#567C8D33",
        "element.active": "#567C8D55",
        "element.selected": "#C8D9E620",
        "element.disabled": "#081A2F",
        "drop_target.background": "#C8D9E620",
        "ghost_element.background": "#00000000",
        "ghost_element.hover": "#567C8D22",
        "ghost_element.active": "#567C8D44",
        "ghost_element.selected": "#C8D9E615",
        "ghost_element.disabled": "#9FB4C133",
        "text": "#F0E7D5",
        "text.muted": "#9FB4C1",
        "text.placeholder": "#9FB4C1",
        "text.disabled": "#567C8D",
        "text.accent": "#C8D9E6",
        "icon": "#9FB4C1",
        "icon.muted": "#567C8D",
        "icon.disabled": "#2F4156",
        "icon.placeholder": "#567C8D",
        "icon.accent": "#C8D9E6",
        "status_bar.background": "#081A2F",
        "title_bar.background": "#081A2F",
        "title_bar.inactive_background": "#0F1F30",
        "title_bar.foreground": "#9FB4C1",
        "title_bar.inactive_foreground": "#567C8D",
        "toolbar.background": "#2F4156",
        "tab_bar.background": "#081A2F",
        "tab.inactive_background": "#081A2F",
        "tab.active_background": "#2F4156",
        "search.match_background": "#C8D9E630",
        "panel.background": "#2F4156",
        "panel.focused_border": "#C8D9E6",
        "pane.focused_border": "#C8D9E6",
        "scrollbar_thumb.background": "#567C8D55",
        "scrollbar.thumb.hover_background": "#567C8D99",
        "scrollbar.thumb.border": "#567C8D33",
        "scrollbar.track.background": "#00000000",
        "scrollbar.track.border": "#2F415633",
        "editor.foreground": "#F0E7D5",
        "editor.background": "#1E3045",
        "editor.gutter.background": "#1E3045",
        "editor.subheader.background": "#2F4156",
        "editor.active_line.background": "#2F415680",
        "editor.highlighted_line.background": "#2F415660",
        "editor.line_number": "#567C8D",
        "editor.active_line_number": "#C8D9E6",
        "editor.invisible": "#567C8D55",
        "editor.wrap_guide": "#2F415666",
        "editor.active_wrap_guide": "#567C8D66",
        "editor.indent_guide": "#2F415666",
        "editor.indent_guide_active": "#567C8D66",
        "editor.document_highlight.read_background": "#C8D9E615",
        "editor.document_highlight.write_background": "#C8D9E625",
        "terminal.background": "#1E3045",
        "terminal.foreground": "#F0E7D5",
        "terminal.bright_foreground": "#FFFFFF",
        "terminal.dim_foreground": "#9FB4C1",
        "terminal.ansi.black": "#081A2F",
        "terminal.ansi.bright_black": "#1E3045",
        "terminal.ansi.red": "#C9856F",
        "terminal.ansi.bright_red": "#D9957F",
        "terminal.ansi.green": "#A8C9B0",
        "terminal.ansi.bright_green": "#B8D9C0",
        "terminal.ansi.yellow": "#E0B66C",
        "terminal.ansi.bright_yellow": "#F0C67C",
        "terminal.ansi.blue": "#567C8D",
        "terminal.ansi.bright_blue": "#C8D9E6",
        "terminal.ansi.magenta": "#8B9FC0",
        "terminal.ansi.bright_magenta": "#9BAFD0",
        "terminal.ansi.cyan": "#567C8D",
        "terminal.ansi.bright_cyan": "#9FB4C1",
        "terminal.ansi.white": "#D8CBB7",
        "terminal.ansi.bright_white": "#F0E7D5",
        "link_text.hover": "#C8D9E6",
        "conflict": "#E0B66C",
        "conflict.background": "#E0B66C15",
        "conflict.border": "#E0B66C55",
        "created": "#A8C9B0",
        "created.background": "#A8C9B015",
        "created.border": "#A8C9B055",
        "deleted": "#C9856F",
        "deleted.background": "#C9856F15",
        "deleted.border": "#C9856F55",
        "error": "#C9856F",
        "error.background": "#C9856F15",
        "error.border": "#C9856F55",
        "hidden": "#567C8D",
        "hidden.background": "#081A2F",
        "hidden.border": "#567C8D55",
        "hint": "#9FB4C1",
        "hint.background": "#9FB4C115",
        "hint.border": "#9FB4C133",
        "ignored": "#567C8D",
        "ignored.background": "#081A2F",
        "ignored.border": "#567C8D33",
        "info": "#C8D9E6",
        "info.background": "#C8D9E615",
        "info.border": "#C8D9E655",
        "modified": "#C8D9E6",
        "modified.background": "#C8D9E615",
        "modified.border": "#C8D9E655",
        "predictive": "#9FB4C1",
        "predictive.background": "#9FB4C115",
        "predictive.border": "#9FB4C133",
        "renamed": "#C8D9E6",
        "renamed.background": "#C8D9E615",
        "renamed.border": "#C8D9E655",
        "success": "#A8C9B0",
        "success.background": "#A8C9B015",
        "success.border": "#A8C9B055",
        "unreachable": "#567C8D",
        "unreachable.background": "#081A2F",
        "unreachable.border": "#567C8D33",
        "warning": "#E0B66C",
        "warning.background": "#E0B66C15",
        "warning.border": "#E0B66C55",
        "players": [
          { "cursor": "#C8D9E6", "background": "#C8D9E630", "selection": "#C8D9E625" },
          { "cursor": "#A8C9B0", "background": "#A8C9B030", "selection": "#A8C9B025" },
          { "cursor": "#E0B66C", "background": "#E0B66C30", "selection": "#E0B66C25" },
          { "cursor": "#C9856F", "background": "#C9856F30", "selection": "#C9856F25" }
        ],
        "accents": ["#C8D9E6", "#8BB8C8", "#A8C9B0", "#E0B66C", "#C9856F", "#567C8D"],
        "syntax": {
          "attribute": { "color": "#9FB4C1", "font_style": null, "font_weight": null },
          "boolean": { "color": "#C8D9E6", "font_style": null, "font_weight": null },
          "comment": { "color": "#9FB4C1", "font_style": "italic", "font_weight": null },
          "comment.doc": { "color": "#9FB4C1", "font_style": "italic", "font_weight": null },
          "constant": { "color": "#C8D9E6", "font_style": null, "font_weight": null },
          "constructor": { "color": "#8BB8C8", "font_style": null, "font_weight": null },
          "embedded": { "color": "#F0E7D5", "font_style": null, "font_weight": null },
          "emphasis": { "color": "#F0E7D5", "font_style": "italic", "font_weight": null },
          "emphasis.strong": { "color": "#F0E7D5", "font_style": null, "font_weight": 700 },
          "enum": { "color": "#A8C4D4", "font_style": null, "font_weight": null },
          "function": { "color": "#8BB8C8", "font_style": null, "font_weight": null },
          "function.builtin": { "color": "#8BB8C8", "font_style": null, "font_weight": null },
          "function.special.definition": { "color": "#8BB8C8", "font_style": null, "font_weight": null },
          "hint": { "color": "#9FB4C1", "font_style": "italic", "font_weight": null },
          "keyword": { "color": "#C8D9E6", "font_style": null, "font_weight": null },
          "label": { "color": "#9FB4C1", "font_style": null, "font_weight": null },
          "link_text": { "color": "#C8D9E6", "font_style": "italic", "font_weight": null },
          "link_uri": { "color": "#8BB8C8", "font_style": null, "font_weight": null },
          "number": { "color": "#E0B66C", "font_style": null, "font_weight": null },
          "operator": { "color": "#567C8D", "font_style": null, "font_weight": null },
          "predictive": { "color": "#9FB4C1", "font_style": "italic", "font_weight": null },
          "preproc": { "color": "#C8D9E6", "font_style": null, "font_weight": null },
          "property": { "color": "#D8CBB7", "font_style": null, "font_weight": null },
          "punctuation": { "color": "#9FB4C1", "font_style": null, "font_weight": null },
          "punctuation.bracket": { "color": "#9FB4C1", "font_style": null, "font_weight": null },
          "punctuation.delimiter": { "color": "#9FB4C1", "font_style": null, "font_weight": null },
          "punctuation.list_marker": { "color": "#C8D9E6", "font_style": null, "font_weight": null },
          "punctuation.special": { "color": "#567C8D", "font_style": null, "font_weight": null },
          "string": { "color": "#F0E7D5", "font_style": null, "font_weight": null },
          "string.doc": { "color": "#D8CBB7", "font_style": "italic", "font_weight": null },
          "string.escape": { "color": "#C8D9E6", "font_style": null, "font_weight": null },
          "string.regex": { "color": "#E0B66C", "font_style": null, "font_weight": null },
          "string.special": { "color": "#D8CBB7", "font_style": null, "font_weight": null },
          "string.special.symbol": { "color": "#D8CBB7", "font_style": null, "font_weight": null },
          "tag": { "color": "#C8D9E6", "font_style": null, "font_weight": null },
          "text.literal": { "color": "#F0E7D5", "font_style": null, "font_weight": null },
          "title": { "color": "#F0E7D5", "font_style": null, "font_weight": 700 },
          "type": { "color": "#A8C4D4", "font_style": null, "font_weight": null },
          "type.builtin": { "color": "#A8C4D4", "font_style": null, "font_weight": null },
          "variable": { "color": "#D8CBB7", "font_style": null, "font_weight": null },
          "variable.special": { "color": "#C8D9E6", "font_style": null, "font_weight": null },
          "variant": { "color": "#A8C4D4", "font_style": null, "font_weight": null }
        }
      }
    }
  ]
}
```

- [ ] **Step 5: Stow the module**

The existing `~/.config/zed/settings.json` is not a symlink, and `~/.config/zed/themes/` may not exist yet — stow needs to create it. Remove the live file first (already copied in Step 2), then stow:

```bash
rm ~/.config/zed/settings.json
mkdir -p ~/.config/zed/themes
cd ~/dotfiles && stow zed
```

Verify:

```bash
ls -la ~/.config/zed/settings.json
ls -la ~/.config/zed/themes/brand.json
```

Both should be symlinks into `~/dotfiles/zed/`.

- [ ] **Step 6: Open Zed and verify the theme loads**

```bash
zed .
```

Expected: editor opens with navy background, cream text, teal line numbers, sky-blue keywords. Open the command palette (`Ctrl+Shift+P`) and run `theme selector: toggle` — "Brand Navy" should appear in the list and be selected.

If the theme does not load (Zed shows a default theme), check:
1. `~/.config/zed/themes/brand.json` is valid JSON: `python3 -m json.tool ~/.config/zed/themes/brand.json`
2. The name in `settings.json` matches `"name"` in `brand.json` exactly: both must be `"Brand Navy"`

- [ ] **Step 7: Commit**

```bash
cd ~/dotfiles
git add zed/
git commit -m "Add zed stow module with Brand Navy theme"
```

---

## Task 4: Update packages.md and final commit

**Files:**
- Modify: `dotfiles/packages.md`

- [ ] **Step 1: Open packages.md and add entries for the three new modules**

Find the section in `packages.md` that lists dotfiles modules (or add one if it doesn't exist). Add:

```
- wob         — ~/.config/wob/wob.ini            (brand palette OSD bar)
- walker      — ~/.config/walker/{config,style}   (brand palette GTK4 launcher)
- zed         — ~/.config/zed/{settings,themes}   (Brand Navy editor theme)
```

- [ ] **Step 2: Commit**

```bash
cd ~/dotfiles
git add packages.md
git commit -m "Document wob, walker, zed stow modules in packages.md"
```

---

## Verification Checklist

After all tasks:

- [ ] `stow wob walker zed` runs clean from `~/dotfiles/` with no conflicts
- [ ] Volume key press shows navy+cream wob OSD at bottom-center
- [ ] `Mod+Slash` opens Walker with translucent navy, teal border, sky-left selected row
- [ ] Zed opens with navy background, cream text, sky-blue keywords — no fallback theme
- [ ] `git diff origin/master` touches only the three new modules and `packages.md`
- [ ] Walker service restarts cleanly (not stuck, no zombie processes)
