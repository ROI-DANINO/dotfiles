# Daemon Services

## Daemon & Service Architecture

### Niri startup chain

Niri's `spawn-at-startup` section launches eight direct processes and relies on one systemd user service:

```
niri (compositor)
 ├── spawn-at-startup: waybar
 ├── spawn-at-startup: dunst
 ├── spawn-at-startup: walker --gapplication-service
 ├── spawn-at-startup: ~/.local/bin/wob-daemon
 ├── spawn-at-startup: nm-applet --indicator
 ├── spawn-at-startup: blueman-applet
 ├── spawn-at-startup: ~/.local/bin/wallpaper-rotate
 └── spawn-at-startup: swayidle -w
                          timeout 300 "niri msg action power-off-monitors"
                          timeout 600 "~/.local/bin/lock-screen"
                          resume  "niri msg action power-on-monitors"
```

### Elephant (walker backend)

Walker requires a running `elephant` backend for its extended search capabilities. Elephant is managed as a **systemd user service**, not spawned directly by Niri.

Service file: `~/.config/systemd/user/elephant.service`

```ini
[Service]
Type=simple
ExecStart=/usr/bin/elephant
Restart=on-failure
RestartSec=2
StartLimitIntervalSec=60
StartLimitBurst=5        # stops respawn loop after 5 failures in 60s
MemoryHigh=512M
Slice=session.slice
```

**History note**: Prior to 2026-05-30, elephant was spawned directly by Niri `spawn-at-startup`, causing 4-instance process leaks (≈700MB RAM waste) on each session restart. The systemd service migration fixed this. Do not revert to direct spawning.

### wob-daemon

Script: `~/.local/bin/wob-daemon`

Creates a named FIFO at `/tmp/wob.fifo`, then keeps it alive with `tail -f | wob`. Niri keybinds for volume/brightness write integers (0–100) to the FIFO. Using `tail -f` prevents `wob` from exiting on EOF after each write (which was the source of prior orphan process accumulation).

### swayidle

Started directly by Niri at login. Two-phase idle pipeline:

1. **300 s** — `niri msg action power-off-monitors`: OLED pixels fully off. Any mouse/key input fires `resume` and powers monitors back on. No password required.
2. **600 s** — `~/.local/bin/lock-screen`: auto-lock. Picks a random OLED gradient from `~/.config/hypr/backgrounds/`, points `~/.cache/hyprlock/bg.png` at it, then launches `hyprlock` (instant, no live blur) — modern clock/date + gradient-border password field. Config: `~/.config/hypr/hyprlock.conf`. Requires password to unlock.
3. **resume** — `niri msg action power-on-monitors`.

`~/.local/bin/toggle-idle` is a manual toggle — kills swayidle if running; if not, starts swayidle with the same idle pipeline and immediately powers off the monitors. Bound to `Mod+Shift+K`.

Explicit lock is separate: `Mod+Shift+L` runs `~/.local/bin/lock-screen` (random gradient → hyprlock).

### wallpaper-rotate

Script: `~/.local/bin/wallpaper-rotate`. Uses `swww img` to rotate wallpapers from `~/Pictures/walpapers` every 10 minutes. It shuffles the list and shows every wallpaper once before repeating; the folder is rescanned between full passes. Wallpaper images are stored in the `wallpapers/` stow package and tracked with Git LFS. Requires `swww-daemon` to be running (also started by the script).
