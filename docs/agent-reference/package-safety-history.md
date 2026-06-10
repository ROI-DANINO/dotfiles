# Package Safety History

## Package Removal Gotchas

- `Thunar` (capital T) — GUI file manager, `Mod+F` keybind, in `install.sh`. Shares XFCE libs but is NOT an XFCE-only tool.
- `zenity` — used by scripts; pulled out by autoremove.
- `swayidle`, `swaybg` — Sway utilities actively used by the niri session. Do NOT remove with Sway WM.
- `swaync` — archived/replaced by `dunst`; do not re-add without removing `dunst` first because notification daemons conflict on `org.freedesktop.Notifications`.
- `hyprlock` — screen locker, from the `sdegler/hyprland` COPR (not in default Fedora repos). Requires `/etc/pam.d/hyprlock` to exist or all unlocks are denied. Config: `hyprlock/` stow module → `~/.config/hypr/hyprlock.conf`. See packages.md and install.sh §4b. Pulls `hypr*` support libs (hyprlang/hyprutils/hyprgraphics) — do not autoremove them.
- `swaylock` — DECOMMISSIONED 2026-06-04 (replaced by hyprlock). The source-built binary may still linger at `/usr/local/bin/swaylock`; harmless, removable. Module archived at `archived/swaylock/`.
- `gnome-keyring`, `gnome-keyring-pam` — used system-wide, not GNOME-specific.

---

## What Was Removed

### 2026-05-30 hygiene pass

| Component | Why removed | If re-requested |
|-----------|------------|-----------------|
| **COSMIC DE**, KDE, Sway, XFCE4 | Legacy DE clutter purged from `~/.config` and `~/.local/share` (~134MB) | Only reintroduce if user wants to run that DE alongside Niri |
| **auto-cpufreq** (git-based daemon) | Conflicted with TLP; fully replaced | TLP already handles CPU power policy — flag the overlap before installing |
| `tuned`, `tuned-ppd` | Orphaned after DE purge; conflicted with TLP | Same overlap concern as auto-cpufreq |
| `cosmic-settings`, `granite`, `woff2`, `python3-jsonschema` stack | Orphaned COSMIC dependencies with no active consumer | Only relevant if COSMIC DE is reinstalled |
| `auto-rename-copies.service` | Was crash-looping every 5 seconds; no active use case | Investigate the crash root cause before re-enabling |
| `anyrun`, `epiphany` | Replaced by walker + Zen browser respectively | Walker is locked as the launcher; confirm user wants to change that first |

### 2026-05-31 hygiene pass

| Component | Why removed | If re-requested |
|-----------|------------|-----------------|
| `mako` | Replaced by `swaync` (notification daemon + center); dbus conflict on `org.freedesktop.Notifications` | `dunst` is now the active notification daemon — do not add a second provider for `org.freedesktop.Notifications` |
| `fuzzel`, `wofi` | Replaced by walker; orphaned launchers with no active use | Walker is locked as launcher — confirm user wants to change that first |
| **IBus** + all input engine deps (anthy, hangul, pinyin, etc.) | Hebrew/English switching is handled natively by Niri xkb (`us,il` + `grp:win_space_toggle`) — IBus was unused and spamming Wayland portal warnings | XKB handles layout switching; only reinstall if a complex input method (CJK, etc.) is needed |

### 2026-06-01 hygiene pass

| Component | Why archived (`archived/`) | If re-requested |
|-----------|------------|-----------------|
| `alacritty/` | Kitty is primary terminal; alacritty config was also hard-wired to launch Zellij (incompatible with AI agent workflows) | `git mv archived/alacritty .` then `stow alacritty` — but reconsider Kitty first |
| `swaync/` | Replaced by dunst (focus-steal bug fix); dunst is now the active notification daemon | Do NOT re-add without removing dunst first — DBus conflict on `org.freedesktop.Notifications` |
| `zellij/` | Stopped using: breaks CLI rendering of AI agents (Claude Code, Gemini, Codex) | `git mv archived/zellij .` then add to stow.sh if re-evaluating; check AI agent compat first |
| **mpv/swayidle OLED screensaver** | mpv captures Wayland input, preventing swayidle from receiving resume events — screen would not dismiss on mouse/key | `oled-screensaver` script kept at `~/.local/bin/oled-screensaver` for manual launch; do not re-add to swayidle chain |

### 2026-06-04 lock screen migration

| Component | Why changed | If re-requested |
|-----------|------------|-----------------|
| `swaylock-effects` → **hyprlock** | Wanted a fast, modern lock: swaylock blurred a 4–6 MP wallpaper live on every lock (~2s+ delay) and ties the clock to a cramped indicator ring. hyprlock shows one image as-is (instant) with a big clock, small date, and a styled password field. | swaylock module archived at `archived/swaylock/`; `git mv` it back + re-add to stow.sh/install.sh to revert. hyprlock is from the `sdegler/hyprland` COPR. |
| swaylock binary `/usr/local/bin/swaylock` | Source build no longer used | Harmless leftover. Optional removal: `sudo rm /usr/local/bin/swaylock /etc/pam.d/swaylock && rm -rf ~/.local/src/swaylock-effects` |

### 2026-06-10 login manager migration

| Component | Why changed | If re-requested |
|-----------|------------|-----------------|
| `greetd` + `tuigreet` → **Ly** | User preference for a polished TUI aesthetic with robust username memory on logout. Greetd/tuigreet felt too minimal or inconsistent for the owner's taste. | Revert in `install.sh` (§4c), `packages.md`, and `README.md`. Greetd configuration: `/etc/greetd/config.toml`. |
