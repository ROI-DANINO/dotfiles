# Theming Expansion Design

Date: 2026-05-31
Status: Approved for planning

## Goal

Extend the existing brand desktop palette (navy/cream/teal/sky) to three unthemed but active surfaces: the Wob OSD bar, the Walker app launcher, and the Zed editor. Each gets a new stow module added to the dotfiles. Zen Browser, Swaylock, Kdenlive, Ironbar, Mako, and Fuzzel are explicitly out of scope.

Brand palette reference: `docs/theme/brand-desktop-palette.md`

## Scope

**In:**
- `wob` — volume/brightness OSD overlay (running at startup via `wob-daemon`)
- `walker` — GTK4 app launcher (running at startup, bound to `Mod+Slash`)
- `zed` — code editor (dark brand theme only; `mode: dark` in settings.json)

**Out:**
- Zen Browser — dropped (profile path has machine-specific hash, low priority)
- Swaylock — user preference, not changing
- Kdenlive — Flatpak Qt/KDE, not part of the core setup
- Ironbar — inactive (waybar is the running bar)
- Mako — swaync handles notifications; mako minimal config left as-is
- Fuzzel — inactive (walker is the active launcher)
- Alacritty — explicitly excluded per prior spec

## Stow Structure

Three new modules added to `~/dotfiles/`:

```
wob/
  .config/wob/wob.ini

walker/
  .config/walker/config.yaml
  .config/walker/style.css

zed/
  .config/zed/settings.json
  .config/zed/themes/brand.json
```

All three are stowed normally. No install script changes required (Zen Browser is out of scope).

## Per-Surface Design

### Wob

Wob is the rectangular OSD overlay for volume and brightness (piped via `/tmp/wob.fifo`). It has no border-radius support.

Config path: `~/.config/wob/wob.ini`

| Property | Value | Token |
|---|---|---|
| `background_color` | `1E3045E0` | `navy-deep` at 88% opacity |
| `bar_color` | `F0E7D5FF` | `brand-cream` solid |
| `border_color` | `567C8DFF` | `brand-teal` solid |
| `border_size` | `1` | — |
| `bar_padding` | `4` | — |
| `height` | `24` | — |
| `width` | `400` | — |
| `anchor` | `bottom center` | — |
| `margin` | `0 0 48 0` | — |

### Walker

Walker is a GTK4 launcher. Config goes in `~/.config/walker/config.yaml` (providers, behavior) and `~/.config/walker/style.css` (appearance). Style direction: translucent navy window, teal border, sky-blue left-bar on selected row.

**config.yaml** — minimal config enabling the `applications` and `calc` providers. No clipboard, websearch, or other providers needed for basic usage.

**Implementation note:** Walker's actual GTK4 widget selector names must be verified during implementation — either via GTK Inspector or Walker's source. If selectors are wrong, styles apply silently to nothing. Use `GTK_DEBUG=interactive walker` to inspect the widget tree.

**style.css token mapping:**

| Element | Property | Value | Token |
|---|---|---|---|
| `#window` | `background` | `rgba(47,65,86,0.92)` | `brand-navy` 92% |
| `#window` | `border` | `1px solid #567C8D` | `brand-teal` |
| `#window` | `border-radius` | `12px` | — |
| `#search entry` | `color` | `#F0E7D5` | `brand-cream` |
| `#search entry` | `caret-color` | `#C8D9E6` | `brand-sky` |
| placeholder text | `color` | `#9FB4C1` | `sky-muted` |
| `.item` (unselected) | `color` | `#9FB4C1` | `sky-muted` |
| `.item:selected` | `background` | `rgba(200,217,230,0.12)` | `brand-sky` 12% |
| `.item:selected` | `color` | `#F0E7D5` | `brand-cream` |
| `.item:selected` | `border-left` | `2px solid #C8D9E6` | `brand-sky` |

### Zed

Zed supports custom JSON themes under `~/.config/zed/themes/`. `settings.json` is updated to point to the brand theme with `"mode": "dark"`, removing the system-switching behavior.

**settings.json change** — replaces the existing `theme` block (removes the `"light": "Gruvbox Light"` and `"mode": "system"` keys):
```json
"theme": {
  "mode": "dark",
  "dark": "Brand Navy"
}
```

**themes/brand.json** — a complete Zed theme object named `"Brand Navy"`. Must be built from an existing valid Zed theme as a template (not from scratch) since the format has many required fields and silently falls back on missing keys.

**Implementation note:** The existing `~/.config/zed/settings.json` contains agent panel config, font sizes, keymaps, and other settings that must be preserved. The stow module must be seeded from the current live file — only the `theme` block is changed.

Token mapping:

| Role | Hex | Token |
|---|---|---|
| Editor background | `#1E3045` | `navy-deep` |
| Editor foreground | `#F0E7D5` | `brand-cream` |
| UI panels / sidebar bg | `#2F4156` | `brand-navy` |
| Active tab bg | `#2F4156` | `brand-navy` |
| Active tab fg | `#F0E7D5` | `brand-cream` |
| Inactive tab bg | `#081A2F` | `navy-ink` |
| Inactive tab fg | `#9FB4C1` | `sky-muted` |
| Status bar bg | `#081A2F` | `navy-ink` |
| Status bar fg | `#9FB4C1` | `sky-muted` |
| Cursor | `#C8D9E6` | `brand-sky` |
| Selection bg | `rgba(200,217,230,0.25)` | `brand-sky` 25% |
| Line numbers | `#567C8D` | `brand-teal` |
| Active line highlight | `rgba(47,65,86,0.5)` | `brand-navy` 50% |
| **Syntax — keywords** | `#C8D9E6` | `brand-sky` |
| **Syntax — strings** | `#F0E7D5` | `brand-cream` |
| **Syntax — comments** | `#9FB4C1` | `sky-muted` (italic) |
| **Syntax — functions** | `#8BB8C8` | sky-derived |
| **Syntax — types** | `#A8C4D4` | sky-derived muted |
| **Syntax — numbers** | `#E0B66C` | `warning` |
| **Syntax — operators** | `#567C8D` | `brand-teal` |
| **Syntax — variables** | `#D8CBB7` | `cream-muted` |
| Error underline | `#C9856F` | `danger` |
| Warning underline | `#E0B66C` | `warning` |
| Git added | `#A8C9B0` | `success` |
| Git modified | `#C8D9E6` | `brand-sky` |
| Git deleted | `#C9856F` | `danger` |

## Non-Goals

- No changes to keybinds, startup processes, or stow package membership.
- No light theme variant for Zed.
- No changes to `system/`, `alacritty/`, or any already-themed module.
- No Zen Browser, Swaylock, or Kdenlive theming.
- No theme generator or automation — hand-applied token mapping as in prior passes.

## Verification

After implementation:

- `git diff` touches only the three new modules plus `packages.md` and `docs/`.
- `wob` OSD shows cream bar on navy background when volume keys are pressed.
- `walker` opens with navy translucent background and teal border on `Mod+Slash`.
- Zed loads without errors; syntax highlighting uses brand colors; no crash on open.
- `stow wob walker zed` runs cleanly from `~/dotfiles/`.
- Walker service restarted after stow (`pkill walker` then niri respawns it, or `walker --close && walker --gapplication-service &`); styled UI confirmed on next `Mod+Slash`.
