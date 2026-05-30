# GTK Brand Theme — Design Spec

**Date:** 2026-05-31
**Scope:** Apply brand palette to GTK3/GTK4 apps: blueman, thunar, nm-applet

## Problem

The desktop's brand theme (navy/cream/teal) is applied to niri, kitty, waybar, swaync, zellij, and the shell prompt. GTK apps (blueman, thunar, nm-applet) still render with Orchis-Dark's default grey palette, breaking visual cohesion.

## Approach

Global GTK CSS override — a single `gtk.css` file per GTK version that redefines named color variables. Orchis-Dark is kept as the base theme (window chrome, widget shapes, spacing) but its grey background colors are replaced with brand navy values. No theme fork required.

## Files Created

```
gtk/
  .config/
    gtk-3.0/
      gtk.css    ← overrides for GTK3 apps (blueman, thunar, nm-applet)
    gtk-4.0/
      gtk.css    ← same overrides for GTK4 apps (future-proofing)
```

Stow module: `gtk`. Symlinks land at `~/.config/gtk-3.0/gtk.css` and `~/.config/gtk-4.0/gtk.css`.

## Color Mapping

| GTK variable | Brand token | Hex | Notes |
|---|---|---|---|
| `theme_bg_color` | `brand-navy` | `#2F4156` | Window/panel backgrounds |
| `theme_base_color` | `navy-deep` | `#1E3045` | List rows, text entry backgrounds |
| `theme_fg_color` | `brand-cream` | `#F0E7D5` | Primary text |
| `theme_selected_bg_color` | `brand-sky` | `#C8D9E6` | Selected rows, focused elements |
| `theme_selected_fg_color` | `navy-deep` | `#1E3045` | Text on selected rows |
| `borders` | `brand-teal` | `#567C8D` | Borders and separators |
| `unfocused_borders` | (teal dimmed) | `#3a556a` | Unfocused window borders |
| `insensitive_bg_color` | (navy muted) | `#263749` | Disabled widget backgrounds |
| `insensitive_fg_color` | `sky-muted` | `#9FB4C1` | Disabled text |
| `theme_tooltip_bg_color` | `navy-deep` | `#1E3045` | Tooltip backgrounds |
| `theme_tooltip_fg_color` | `brand-cream` | `#F0E7D5` | Tooltip text |

## CSS Implementation

Both `gtk-3.0/gtk.css` and `gtk-4.0/gtk.css` use `@define-color` to set the variables above, then apply targeted widget overrides for any elements GTK doesn't pick up through named variables (e.g., header bars, popovers, sidebars).

## Dotfiles Integration

- Add `gtk` stow module to `install.sh` step 9 (after existing stow calls)
- Add entry to `packages.md` noting no new packages needed (GTK CSS is built-in)
- Add entry to `README.md` autostart/config table noting `gtk.css` brand override

## Out of Scope

- Icon themes — stay on current `breeze-dark` / `Adwaita`
- Cursor theme — unchanged
- GTK app-specific settings beyond color (fonts, spacing, etc.)
- Any app using Qt (e.g., KDE apps) — separate effort
