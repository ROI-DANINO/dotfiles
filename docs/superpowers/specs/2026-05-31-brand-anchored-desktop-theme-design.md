# Brand-Anchored Desktop Theme Design

Date: 2026-05-31
Status: Approved for planning

## Goal

Create a coherent desktop color system for Roi's Fedora/Niri dotfiles that uses the official Roi Danino brand palette as the primary identity and the wallpaper collection as environmental support.

The final direction is warm, brand-anchored navy:

- Dominant identity: Roi Danino = Sky Blue + Navy
- System base: Navy, not near-black teal
- Focus and selection: Sky Blue
- Structure and secondary accents: Teal
- Warmth: Vanilla Cream, not gold
- Wallpaper complement: ocean/teal and natural earth tones support the brand quietly

This pass must define one semantic palette and map it into active color-bearing configs. It must not mechanically replace random hex values without considering each app's role.

## Brand Source

The canonical brand palette comes from:

- `/home/roking/Desktop/Projects/Roi_Danino/wiki/content/brand-identity.md`
- `/home/roking/Desktop/Projects/Roi_Danino/context/one-gem/01-identity-visual.md`
- `/home/roking/Desktop/Projects/Roi_Danino/raw/noise/BRAND.md`
- `/home/roking/Desktop/Projects/Roi_Danino/raw/noise/CAROUSEL_STYLE.md`

Those docs are explicit: the palette is strict and should not be substituted with generic tech tones. They also warn against cold dark-mode aesthetics, electric blue, neon, tech-bro styling, and gold. Warmth should come from Vanilla Cream.

## Wallpaper Analysis

The wallpaper set contains 50 JPEG files. The dominant color families are:

- Very dark teal-black and shadow colors
- Ocean, lake, and seafoam teal
- Muted sandstone, ochre, and dry grass gold
- Rust, clay, and copper accents
- Moss, meadow green, and neutral stone

The wallpapers originally suggested a deep ocean/forest palette, but previewing that direction made the desktop feel too cold and dark. The corrected design uses the official brand colors first and lets the wallpapers support them:

- Wallpaper blues and teals support Navy, Sky Blue, and Teal.
- Wallpaper sand/earth warmth supports Vanilla Cream.
- Wallpaper rust/clay appears only as semantic danger/error when needed.

## Semantic Palette

| Token | Hex | Purpose |
|---|---:|---|
| `brand-sky` | `#C8D9E6` | Primary brand accent, focus, selected states, soft highlights |
| `brand-navy` | `#2F4156` | Main dark brand base, headlines, strong surfaces |
| `brand-teal` | `#567C8D` | Borders, secondary accents, icons, structural lines |
| `brand-cream` | `#F0E7D5` | Warm text, cards, section breaks, soft surfaces |
| `brand-white` | `#FFFFFF` | Highest-contrast text and selected-on-dark foreground |
| `navy-deep` | `#1E3045` | Terminal background and deeper surfaces derived from brand Navy |
| `navy-ink` | `#081A2F` | Sparing deepest shadow for terminal black and overlays |
| `sky-muted` | `#9FB4C1` | Muted text on dark surfaces |
| `cream-muted` | `#D8CBB7` | Muted warm text when Vanilla Cream is too bright |
| `success` | `#A8C9B0` | Good/charging/healthy state, softened to fit the brand |
| `warning` | `#E0B66C` | Warning state, used sparingly |
| `danger` | `#C9856F` | Error, urgent, low battery, critical state |
| `selection` | `#C8D9E6` | Text selection and selected row background on dark surfaces |

Exact official brand colors must remain exact when used as brand tokens. Derived tokens are only for terminal/dark-system ergonomics and must stay visually close to Navy/Sky Blue/Vanilla Cream.

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

- Active focus ring: `brand-sky`
- Inactive focus ring: `brand-teal`
- Keep `border off` unchanged unless a separate design decision is made later.

### Kitty

Kitty is the locked/default terminal and should receive the complete terminal palette.

- `background`: `navy-deep`
- `foreground`: `brand-cream`
- `cursor`: `brand-sky`
- `selection_background`: `selection`
- `selection_foreground`: `brand-navy`
- Tab bar: `navy-ink`, `brand-navy`, `navy-deep`, `brand-sky`, `sky-muted`
- ANSI normal/bright colors should be adapted from the semantic palette:
  - black: `navy-ink` / `navy-deep`
  - red: `danger`
  - green: `success`
  - yellow: `warning` only when terminal compatibility needs yellow
  - blue: `brand-sky`
  - magenta: avoid brand-breaking purple unless terminal compatibility requires a muted value
  - cyan: `brand-teal`
  - white: `brand-cream` / `brand-white`

### Waybar

Waybar should become the main visible expression of the palette.

- Bar background: translucent `brand-navy`
- Module backgrounds: `navy-deep` or transparent on the bar
- Hover/active surfaces: `brand-sky` with `brand-navy` text
- Active workspace: `brand-sky`
- Clock: `brand-white` or `brand-cream`, with subtle Sky Blue or Navy background
- Battery states: `success`, `warning`, `danger`
- Health-limit battery state: `brand-cream`
- Disconnected/muted/disabled states: `sky-muted` or `brand-teal`

### SwayNC

Add a stylesheet if SwayNC is currently using default GTK styling.

- Notification surfaces: `brand-cream` for warm card-style notifications, or `brand-navy` for dark notifications
- Control center background: `brand-navy`
- Borders: `brand-teal` or `brand-sky`
- Text: `brand-navy` on cream surfaces, `brand-cream` or `brand-white` on dark surfaces
- Buttons and focused controls: `brand-sky`
- Critical notifications: `danger`
- Clear/action buttons may use `brand-sky` or `brand-cream`; do not introduce gold.

### Zellij

Replace or rename the current `cosmic` theme so it reflects the brand palette.

- Selected ribbons/tabs: `brand-sky` with `brand-navy` text
- Unselected ribbons/tabs: `brand-navy` with `brand-cream` or `sky-muted`
- Frames: `brand-teal`
- Highlight frames: `brand-sky`
- Success/error colors: `success` and `danger`
- Tables/lists should preserve readability, not maximize color.

### Powerlevel10k

Keep the prompt background transparent. Make changes conservatively because this file is large and contains many 256-color values.

- Directory and current-context emphasis: `brand-sky`/`brand-teal`
- Git clean/success: `success`
- Git modified/warning: `warning`
- Git conflict/error/status error: `danger`
- Neutral line/ruler/filler: `sky-muted`
- Tool/runtime colors may be normalized only where they visibly clash.

### Sysbar Scripts

Update hardcoded GTK/Pango colors in:

- `niri/.config/niri/sysbar`
- `scripts/.local/bin/wsbar`

Use the same token mapping as Waybar:

- Background paint: translucent `brand-navy`
- Workspace/current text: `brand-sky`
- Network/info: `brand-sky` or `brand-teal`
- RAM/warm info: `brand-cream`
- Charging/good: `success`
- Low battery/no network: `danger`

## Non-Goals

- Do not change any keybinds.
- Do not alter startup processes, services, or stow package membership.
- Do not touch `system/`.
- Do not add a theme generator in this pass.
- Do not modify `alacritty/`.
- Do not use gold as a brand/system accent.
- Do not introduce neon/electric blue or generic AI/tech aesthetics.
- Do not introduce tracked secrets or machine-specific credentials.

## Implementation Strategy

Use a hand-applied, token-driven update rather than a generator.

Add a small tracked palette reference document during implementation, likely `docs/theme/brand-desktop-palette.md`, then update each config manually against it. This is simpler than maintaining a generator and fits the current dotfiles scale.

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
