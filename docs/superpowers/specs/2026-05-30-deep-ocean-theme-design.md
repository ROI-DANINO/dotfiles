# Deep Ocean Desktop Theme Design

Date: 2026-05-30
Status: Approved for planning

## Goal

Create a coherent dark desktop color system for Roi's Fedora/Niri dotfiles based on the wallpaper collection in `wallpapers/Pictures/walpapers`.

The selected direction is a cool, dark teal/ocean palette:

- Dominant mood: deep ocean, foggy forest, dark teal-black
- Interaction color: bright seafoam/cyan
- Text color: cool mist, high contrast
- Warm colors: muted gold and rust, used sparingly for semantic states

This pass must define one semantic palette and map it into active color-bearing configs. It must not mechanically replace random hex values without considering each app's role.

## Wallpaper Analysis

The wallpaper set contains 50 JPEG files. The dominant color families are:

- Very dark teal-black and shadow colors
- Ocean, lake, and seafoam teal
- Muted sandstone, ochre, and dry grass gold
- Rust, clay, and copper accents
- Moss, meadow green, and neutral stone

The broad direction selected during review was `Deep Forest + Sea`. Within that direction, the final selected branch is the teal/ocean-heavy version with softer natural warmth.

## Semantic Palette

| Token | Hex | Purpose |
|---|---:|---|
| `bg` | `#061216` | Main dark desktop and terminal background |
| `surface` | `#0a1b20` | Primary panels, module backgrounds, terminal tab bar |
| `surface-2` | `#0d252b` | Raised or selected surfaces |
| `surface-3` | `#12333a` | Stronger raised surface or inactive structural color |
| `border` | `#15576a` | Borders, inactive rings, separators |
| `text` | `#d8edf0` | Primary readable foreground |
| `text-muted` | `#a9c5c9` | Secondary text |
| `text-dim` | `#6f8f95` | Disabled or low-priority text |
| `accent` | `#46b7c8` | Main interactive accent |
| `focus` | `#7fd6df` | Focus rings, active selection, cursor emphasis |
| `selection` | `#123f4b` | Text selection and selected row background |
| `success` | `#8fbf9a` | Good/charging/healthy state |
| `warm` | `#c1a46d` | Active warmth, health-limit, neutral highlight |
| `warning` | `#d6b35f` | Warning state |
| `danger` | `#dc805f` | Error, urgent, low battery, critical state |

Contrast checks against `bg` and `surface` are acceptable for terminal and bar usage. Primary text and all semantic colors remain readable on the dark base.

## Included Config Surfaces

Apply the palette to these active color-bearing configs:

- `niri/.config/niri/config.kdl`
- `kitty/.config/kitty/kitty.conf`
- `waybar/.config/waybar/style.css`
- `swaync/.config/swaync/config.json`, plus a new `style.css` if needed
- `zellij/.config/zellij/config.kdl`
- `shell/.p10k.zsh`
- `niri/.config/niri/sysbar`
- `scripts/.local/bin/wsbar`

`alacritty/` is explicitly excluded from this pass. It is installed but not referenced as an active/default terminal and may be deleted in a later cleanup.

## App Mapping

### Niri

Only update visual color values. Do not change keybinds.

- Active focus ring: `focus`
- Inactive focus ring: `border` or `surface-3`
- Keep `border off` unchanged unless a separate design decision is made later.

### Kitty

Kitty is the locked/default terminal and should receive the complete terminal palette.

- `background`: `bg`
- `foreground`: `text`
- `cursor`: `focus`
- `selection_background`: `selection`
- `selection_foreground`: `text`
- Tab bar: `bg`, `surface`, `surface-2`, `focus`, `text-muted`
- ANSI normal/bright colors should be adapted from the semantic palette:
  - black: `surface` / `surface-3`
  - red: `danger`
  - green: `success`
  - yellow: `warning` or `warm`
  - blue: `accent`
  - magenta: restrained muted violet only if needed for compatibility
  - cyan: `focus`
  - white: `text-muted` / `text`

### Waybar

Waybar should become the main visible expression of the palette.

- Bar background: translucent `bg` or `surface`
- Module backgrounds: `surface`
- Hover/active surfaces: `surface-2`
- Active workspace: `accent` or `focus`
- Clock: `accent`/`focus`, with subtle translucent background
- Battery states: `success`, `warning`, `danger`
- Health-limit battery state: `warm`
- Disconnected/muted/disabled states: `text-dim` or `border`

### SwayNC

Add a stylesheet if SwayNC is currently using default GTK styling.

- Notification surfaces: `surface`
- Control center background: `bg` or `surface`
- Borders: `border`
- Text: `text` and `text-muted`
- Buttons and focused controls: `accent`/`focus`
- Critical notifications: `danger`
- Clear/action buttons may use `warm` sparingly.

### Zellij

Replace or rename the current `cosmic` theme so it reflects the new palette.

- Selected ribbons/tabs: `surface-2` with `focus`
- Unselected ribbons/tabs: `surface` with `text-muted`
- Frames: `border`
- Highlight frames: `focus`
- Success/error colors: `success` and `danger`
- Tables/lists should preserve readability, not maximize color.

### Powerlevel10k

Keep the prompt background transparent. Make changes conservatively because this file is large and contains many 256-color values.

- Directory and current-context emphasis: `accent`/`focus`
- Git clean/success: `success`
- Git modified/warning: `warning` or `warm`
- Git conflict/error/status error: `danger`
- Neutral line/ruler/filler: `text-dim`
- Tool/runtime colors may be normalized only where they visibly clash.

### Sysbar Scripts

Update hardcoded GTK/Pango colors in:

- `niri/.config/niri/sysbar`
- `scripts/.local/bin/wsbar`

Use the same token mapping as Waybar:

- Background paint: translucent `bg` or `surface`
- Workspace/current text: `focus`
- Network/info: `accent`
- RAM/warm info: `warning` or `warm`
- Charging/good: `success`
- Low battery/no network: `danger`

## Non-Goals

- Do not change any keybinds.
- Do not alter startup processes, services, or stow package membership.
- Do not touch `system/`.
- Do not add a theme generator in this pass.
- Do not modify `alacritty/`.
- Do not introduce tracked secrets or machine-specific credentials.

## Implementation Strategy

Use a hand-applied, token-driven update rather than a generator.

Add a small tracked palette reference document during implementation, likely `docs/theme/deep-ocean-palette.md`, then update each config manually against it. This is simpler than maintaining a generator and fits the current dotfiles scale.

Before editing live configs, create an implementation plan that lists exact files and verification steps. Because the repo is stowed into the live system, edits should be deliberate and reviewed before reload commands.

## Verification

After implementation, verify:

- `git diff` only touches intended files.
- Niri config syntax is valid if a local validation command exists.
- Kitty loads with the new palette.
- Waybar CSS parses and Waybar can reload or restart cleanly.
- Zellij config remains parseable.
- SwayNC config/style loads without breaking notifications.
- Shell prompt still renders after sourcing or opening a new shell.
- No keybind table changes are required because no binds are being changed.

Reloading live services or configs should be done deliberately after reviewing diffs.
