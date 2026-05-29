# AGENTS.md — AI Context for dotfiles

Read this file **before making any changes** to this repo.

Owner: Roi Danino
Machine: Fedora 43, Niri compositor
Last major overhaul: 2026-05-30

---

## Critical Rules

- **Never change a keybind without checking the map below first** — conflicts are easy to introduce
- **Never remove a bind without confirming it's truly unused** — some are intentionally kept
- **Never automate system/ configs** — they are manual-only reference, not touched by install.sh or stow.sh
- **Ask before adding new components to stow.sh** — owner decides what gets symlinked
- **Preserve both arrows AND hjkl** in niri — both are used, not vim-only
- **All configs are symlinked** from ~/dotfiles via GNU Stow — editing the repo file = editing the live config

---

## **Operational Protocols & Constraints**

> These constraints are non-negotiable. They exist because of prior incidents or hard environmental limits. Follow them exactly — do not work around them.

---

### **PROTOCOL 1 — Sudo Handoff (MANDATORY)**

**AI agents MUST NOT run interactive `sudo` commands in this environment.**

The correct procedure when elevated privileges are required:

1. **Output the exact command(s)** as a ready-to-copy code block:
   ```
   sudo systemctl enable --now tlp
   sudo tlp setcharge 0 85 BAT0
   ```
2. **Stop and wait.** Do not proceed until the user replies **"Done"** (or equivalent confirmation).
3. **Never** attempt to run `sudo` directly, chain it with `expect`, pipe it a password, or bypass it with `--no-verify` or similar flags.

**Scope:** Any command requiring root — `sudo dnf`, `sudo systemctl`, `sudo tlp`, edits to `/etc/`, writes to `/sys/`, `chsh`, `visudo`, and any other elevated operation.

**Why this exists:** The AI shell environment cannot authenticate interactively. Silent failures or partial-privileged state are worse than a clean pause.

---

### **PROTOCOL 2 — Live Symlink Awareness**

All configs in `~/dotfiles` are **symlinked into the live system** via GNU Stow. Editing a file in this repo edits the running config immediately.

- **Do not edit config files as experiments.** If you are unsure about a change, describe it first and ask for confirmation before applying it.
- Changes to niri config take effect on next `niri msg action reload-config` or session restart.
- Changes to shell files (`.zshrc`, `.shell_env`, `.shell_aliases`) take effect on next `source ~/.zshrc`.

---

### **PROTOCOL 3 — Stow Conflict Check**

Before running `stow.sh` or `install.sh`, check for existing non-stow-managed files at symlink targets. Conflicting real files cause stow to abort mid-deploy.

```bash
./stow.sh --dry-run   # inspect before applying
```

---

### **PROTOCOL 4 — Secrets Architecture**

The following pattern is in use. Do not suggest alternatives that put secrets in tracked files.

| Location | Purpose | Tracked? |
|----------|---------|----------|
| `~/.secrets` | Global API keys, tokens (chmod 600) | No — gitignored |
| `~/.gitconfig.local` | Git identity (name, email, signingkey) | No — gitignored |
| `.env` (per-project) | Project-specific secrets | No — gitignored |
| `.env.template` | Template showing required env var names | Yes |

**`~/.shell_env`** sources `~/.secrets` automatically if the file exists. No secrets belong in any file under `~/dotfiles/`.

If you find a hardcoded secret, token, or personally identifying value in any tracked file:
1. Note it explicitly before making any other change.
2. Propose moving it to the appropriate untracked location above.
3. Do not commit the file until the secret is removed.

---

## Repository Architecture (GNU Stow)

`~/dotfiles` is a GNU Stow repository. Each top-level directory is a **stow package**. `stow.sh` mirrors each package's subtree into `$HOME`.

Example: `dotfiles/niri/.config/niri/config.kdl` → `~/.config/niri/config.kdl`

Active stow packages (managed by `stow.sh`):

| Package | Stow target |
|---------|-------------|
| `niri/` | `~/.config/niri/` |
| `waybar/` | `~/.config/waybar/` |
| `mako/` | `~/.config/mako/` |
| `swaync/` | `~/.config/swaync/` |
| `kitty/` | `~/.config/kitty/` |
| `alacritty/` | `~/.config/alacritty/` |
| `zellij/` | `~/.config/zellij/` |
| `shell/` | `~/.zshrc`, `~/.shell_env`, etc. |
| `git/` | `~/.gitconfig` |
| `scripts/` | `~/.local/bin/` scripts |

**`system/`** is NOT a stow package — manual reference only.

---

## Daemon & Service Architecture

### Niri startup chain

Niri's `spawn-at-startup` section launches eight direct processes and relies on one systemd user service:

```
niri (compositor)
 ├── spawn-at-startup: waybar
 ├── spawn-at-startup: swaync
 ├── spawn-at-startup: walker --gapplication-service
 ├── spawn-at-startup: ~/.local/bin/wob-daemon
 ├── spawn-at-startup: nm-applet --indicator
 ├── spawn-at-startup: blueman-applet
 ├── spawn-at-startup: ~/.local/bin/wallpaper-rotate
 └── spawn-at-startup: swayidle -w timeout 300 "niri msg action power-off-monitors"
                                              resume "niri msg action power-on-monitors"
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

Started directly by Niri at login. On a 300-second idle timeout it runs `niri msg action power-off-monitors` (display blank only — **not a lock**). On resume it runs `power-on-monitors`.

Explicit lock is separate: `Mod+Shift+L` runs `swaylock -c 000000`.

`~/.local/bin/toggle-idle` is a manual toggle — if swayidle is running it kills it; if not, it starts it with the same power-off behavior and immediately blanks the display.

### wallpaper-rotate

Script: `~/.local/bin/wallpaper-rotate`. Uses `swww img` to rotate wallpapers from `~/Pictures/walpapers` every 10 minutes. Requires `swww-daemon` to be running (also started by the script).

---

## Power Management

TLP manages battery charge threshold. Configuration lives in `/etc/tlp.conf` (system file, not in this repo).

```ini
STOP_CHARGE_THRESH_BAT0=85
```

The 85% cap is intentional for Zenbook/ASUS battery longevity. Do not suggest raising it.

Waybar `battery.sh` reads the threshold dynamically from:
```
/sys/class/power_supply/BAT0/charge_control_end_threshold
```

It applies CSS class `health-limit` when the battery is sitting at the TLP cap (not a fault state).

**Removed**: `auto-cpufreq` git-based daemon (fully replaced by TLP as of 2026-05-30). Do not suggest reinstalling it.

---

## Philosophy

- **Lean setup** — fewer tools that do one thing well; avoid feature-heavy alternatives
- **Rust-based tools preferred** where available and stable (yazi, zellij, swww, bottom)
- **Consistent keybinds** across tools (hjkl movement in zellij, niri, future editor)
- **Vim motions as a learning goal** — not enforced everywhere, preferred where natural
- **Portable** — configs should work on any fresh Fedora machine after `bash install.sh`

---

## Niri Keybind Map

> Changes to binds require updating this table. Check it before adding new binds.

**Mod = Super key**

| Bind | Action | Status |
|------|--------|--------|
| `Mod+T` | spawn kitty | locked |
| `Mod+A` | spawn alacritty | locked |
| `Mod+W` | spawn default browser (Zen) | ✓ |
| `Mod+F` | spawn thunar | ✓ |
| `Mod+Slash` | spawn walker (launcher) | locked |
| `Mod+Q` | close window | ✓ |
| `Mod+Shift+L` | swaylock -c 000000 | locked |
| `Mod+H/L` | focus column left/right | ✓ |
| `Mod+J/K` | focus window down/up | ✓ |
| `Mod+Left/Right/Up/Down` | focus (arrow aliases) | ✓ |
| `Mod+Shift+H` | move column left | ✓ |
| `Mod+Shift+J` | move window down | ✓ |
| `Mod+Shift+K` | spawn toggle-idle (screen blank toggle) | ✓ |
| `Mod+Shift+Right` | move column right | ✓ (Shift+L reserved for lock) |
| `Mod+Shift+B` | spawn toggle-bar (waybar ↔ sysbar) | ✓ |
| `Mod+Shift+C` | spawn claude-desktop | ✓ |
| `Mod+U/I` | focus workspace up/down | ✓ |
| `Mod+Ctrl+U/I` | move column to workspace up/down | ✓ |
| `Mod+R` | cycle column width | ✓ |
| `Mod+M` | maximize column | ✓ |
| `Mod+Shift+F` | fullscreen | ✓ |
| `Mod+C` | center column | ✓ |
| `Mod+Comma/Period` | consume/expel window from column | ✓ |
| `Mod+Minus/Equal` | resize column width | ✓ |
| `Mod+1-9` | focus workspace N | ✓ |
| `Mod+Shift+1-9` | move column to workspace N | ✓ |
| `Mod+Tab` | previous workspace | ✓ |
| `Mod+Shift+E` | quit niri | ✓ |
| `Mod+Shift+P` | power off monitors | ✓ |
| `Ctrl+Space` / `Print` | screenshot | ✓ |
| `Alt+M` | spawn bottom (system monitor) | ✓ |

### Free / available Mod binds
`Mod+B`, `Mod+E`, `Mod+G`, `Mod+N`, `Mod+O`, `Mod+P`, `Mod+S`, `Mod+V`, `Mod+X`, `Mod+Y`, `Mod+Z`

---

## Startup Apps (niri spawn-at-startup)

| App | Purpose | Managed by |
|-----|---------|------------|
| waybar | status bar | niri direct spawn |
| swaync | notification daemon + center | niri direct spawn |
| walker | app launcher (`--gapplication-service` mode) | niri direct spawn |
| wob-daemon | volume/brightness OSD via FIFO | niri direct spawn |
| nm-applet | network tray applet (`--indicator`) | niri direct spawn |
| blueman-applet | bluetooth tray applet | niri direct spawn |
| wallpaper-rotate | swww wallpaper rotation (10 min cycle) | niri direct spawn |
| swayidle | idle monitor power-off (300s timeout) | niri direct spawn |
| elephant | walker data-provider backend | systemd user service (not in spawn-at-startup) |

---

## Locked / Do Not Change

- `shell/zshrc` plugins: only `zsh-autosuggestions` + `zsh-syntax-highlighting` (autocomplete intentionally removed)
- `Mod+Slash` → walker
- `Mod+T` → kitty (default terminal)
- `Mod+Space` → keyboard language toggle (us/Hebrew via xkb — **do NOT bind in niri**)
- zellij `copy_command "wl-copy"` — Wayland clipboard, required for copy-on-select
- `system/` configs are manual-only — never add to install.sh or stow.sh
- `alias claude='claude --dangerously-skip-permissions'` — intentional; this is a personal machine with no multi-user exposure. Do not remove or suggest removing.

---

## Machine-Specific Notes

- Display: `eDP-1`, `2880x1800@90`, scale `2.0` (HiDPI laptop)
- Keyboard: `us,il` with `grp:win_space_toggle`
- Java: `/usr/lib/jvm/java-25-openjdk` (hardcoded in `shell/env`)
- NTP: enabled, timezone: `Asia/Jerusalem (IST, +0200)`
- npm global: `~/.npm-global/bin` (in PATH via `shell/env`)

---

## What Was Removed (2026-05-30 hygiene pass)

The following components were purposefully removed due to conflicts, instability, or bloat. **Do not suggest reinstalling them as part of standard optimization or troubleshooting.** If the user explicitly requests a feature or workflow that genuinely requires one of these, surface the context below first so they can make an informed decision.

| Component | Why removed | If re-requested |
|-----------|------------|-----------------|
| **COSMIC DE**, KDE, Sway, XFCE4 | Legacy DE clutter purged from `~/.config` and `~/.local/share` (~134MB) | Only reintroduce if user wants to run that DE alongside Niri |
| **auto-cpufreq** (git-based daemon) | Conflicted with TLP; fully replaced | TLP already handles CPU power policy — flag the overlap before installing |
| `tuned`, `tuned-ppd` | Orphaned after DE purge; conflicted with TLP | Same overlap concern as auto-cpufreq |
| `cosmic-settings`, `granite`, `woff2`, `python3-jsonschema` stack | Orphaned COSMIC dependencies with no active consumer | Only relevant if COSMIC DE is reinstalled |
| `auto-rename-copies.service` | Was crash-looping every 5 seconds; no active use case | Investigate the crash root cause before re-enabling |
| `anyrun`, `epiphany` | Replaced by walker + Zen browser respectively | Walker is locked as the launcher; confirm user wants to change that first |

---

## Repo Structure

```
~/dotfiles/
├── install.sh          # idempotent one-shot: packages + services + stow
├── stow.sh             # GNU Stow deploy only
├── packages.md         # manual package reference
├── README.md           # human-facing overview
├── AGENTS.md           # this file
├── keybinds.md         # quick keybind reference card
├── niri/               # .config/niri/config.kdl
├── waybar/             # .config/waybar/ — config.jsonc, style.css, battery.sh
├── mako/               # .config/mako/
├── swaync/             # .config/swaync/
├── kitty/              # .config/kitty/
├── alacritty/          # .config/alacritty/
├── zellij/             # .config/zellij/ — config + themes + layouts
├── shell/              # .zshrc, .shell_env, .shell_aliases, p10k.zsh
├── git/                # .gitconfig
├── scripts/            # .local/bin/ — wallpaper-rotate, wob-daemon, toggle-idle, vr-desktop
├── system/             # manual-only: earlyoom, journald, sysctl, zram
└── docs/               # internal docs (superpowers skills, etc.)
```
