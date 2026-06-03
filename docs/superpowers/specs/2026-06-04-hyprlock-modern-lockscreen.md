# Modern lock screen — hyprlock

**Date:** 2026-06-04
**Status:** Implemented

## Goal

A fast, clean, modern lock screen: a single wallpaper shown **as-is**, with a
polished clock, date, and password field.

## Journey (why we ended up here)

1. Started by enhancing swaylock-effects: blurred rotating wallpaper + clock +
   small ring.
2. **Problem found:** swaylock blurs the full 4–6 MP wallpaper *live on every
   lock* → multi-second delay. The lock got slow.
3. **Problem found:** swaylock's clock is locked to the indicator ring at one
   font size — cramped, not modern. Its "password fill" is only the ring.
4. **Decision:** one image shown as-is (no live blur → instant) and switch to
   **hyprlock**, which supports a large clock, a separate small date, and a
   styled password input field — the modern look swaylock can't produce.

## Design

- **Tool:** hyprlock (from `sdegler/hyprland` COPR; needs `/etc/pam.d/hyprlock`).
- **Background:** single wallpaper, shown as-is, no blur — instant lock.
  Default `~/Pictures/walpapers/pexels-whale-blue-ocean-22670211.jpg`. Swap via
  one `path =` line.
- **Clock:** large cream time (`%H:%M`, 128px), small uppercase date
  (`%a, %d %b`, 22px) below, both with drop shadow for legibility over any photo.
- **Password field:** rounded, steel outline, navy fill, cream text; gold while
  verifying, terracotta on failure, gold on caps-lock.
- **Config:** `hyprlock/` stow package → `~/.config/hypr/hyprlock.conf`.

## Wiring (niri)

- swayidle idle-lock (`timeout 600`) → `hyprlock`.
- `Mod+Shift+L` → `hyprlock`.
- `toggle-idle` (`Mod+Shift+K`) respawn → `hyprlock`.

## Decommissioned

- swaylock-effects: module archived at `archived/swaylock/`; removed from
  `stow.sh` and `install.sh` (replaced §4b with hyprlock install). Leftover
  binary at `/usr/local/bin/swaylock` is harmless/removable.
- The abandoned cycling experiment (`lock-screen` wrapper + `lock-wallpapers.txt`)
  was removed.
