# Modern lock screen — hyprlock

**Date:** 2026-06-04
**Status:** Implemented

## Goal

A fast, clean, modern lock screen: an OLED-friendly gradient shown **as-is**
(rotating through a few per lock), with a polished clock, date, and password
field.

## Journey (why we ended up here)

1. Started by enhancing swaylock-effects: blurred rotating wallpaper + clock +
   small ring.
2. **Problem found:** swaylock blurs the full 4–6 MP wallpaper *live on every
   lock* → multi-second delay. The lock got slow.
3. **Problem found:** swaylock's clock is locked to the indicator ring at one
   font size — cramped, not modern. Its "password fill" is only the ring.
4. **Decision:** image shown as-is (no live blur → instant) and switch to
   **hyprlock**, which supports a large clock, a separate small date, and a
   styled password input field — the modern look swaylock can't produce.
5. **Refinement:** dropped the photo for OLED gradients (true-black = pixels off).
   hyprlock can't animate the background natively (open feature request), so a
   seamless morph isn't possible; instead we rotate a random gradient per lock —
   instant and weightless since gradients are simple PNGs.

## Design

- **Tool:** hyprlock (from `sdegler/hyprland` COPR; needs `/etc/pam.d/hyprlock`).
- **Background:** rotating OLED gradient, shown as-is, no blur — instant lock.
  Three gradients in `hyprlock/.config/hypr/backgrounds/` (radial / aurora /
  horizon), ImageMagick-generated at 1920×1200, tuned for true black.
  `~/.local/bin/lock-screen` picks one at random per lock and symlinks
  `~/.cache/hyprlock/bg.png` to it; `hyprlock.conf` `background.path` points there.
- **Clock:** large cream time (`%H:%M`, 128px), small uppercase date
  (`%a, %d %b`, 22px) below, both with drop shadow.
- **Password field:** pill (`rounding=-1`, 360×66), steel→teal gradient border,
  navy fill, cream text; gold while verifying, terracotta on failure/caps-lock.
- **Config:** `hyprlock/` stow package → `~/.config/hypr/hyprlock.conf`;
  wrapper `scripts/.local/bin/lock-screen`.

## Wiring (niri)

- swayidle idle-lock (`timeout 600`) → `~/.local/bin/lock-screen`.
- `Mod+Shift+L` → `~/.local/bin/lock-screen`.
- `toggle-idle` (`Mod+Shift+K`) respawn → `~/.local/bin/lock-screen`.

## Decommissioned

- swaylock-effects: module archived at `archived/swaylock/`; removed from
  `stow.sh` and `install.sh` (replaced §4b with hyprlock install). Leftover
  binary at `/usr/local/bin/swaylock` is harmless/removable.
- The original swaylock cycling experiment (`lock-wallpapers.txt` + a swaylock
  `lock-screen` wrapper) was removed. A new, simpler `lock-screen` wrapper was
  later reintroduced for gradient rotation (symlink + `exec hyprlock`).
