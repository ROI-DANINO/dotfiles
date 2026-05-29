# dotfiles — Roi Danino

Fedora 43 · Niri compositor · GNU Stow

## Quick start

```bash
git clone https://github.com/ROI-DANINO/dotfiles ~/dotfiles
bash ~/dotfiles/install.sh
```

`install.sh` is idempotent — safe to re-run. It installs all packages, enables services, and calls `stow.sh` at the end. After it finishes:

```bash
source ~/.zshrc          # reload shell immediately
# then log out and back in to start your Niri session
```

See `packages.md` for a manual reference of everything that gets installed.

## What's included

| Component | Path | Notes |
|-----------|------|-------|
| Niri | `niri/` | Scrolling tiling WM, primary compositor |
| Waybar | `waybar/` | Status bar with custom battery.sh (TLP-aware) |
| Mako | `mako/` | Notification daemon |
| SwayNC | `swaync/` | Notification center |
| Walker | managed by niri startup | App launcher, powered by elephant |
| Elephant | systemd user service | Walker data-provider backend |
| swww | `scripts/.local/bin/wallpaper-rotate` | Wallpaper daemon, rotates every 10 min from `~/Pictures/walpapers` |
| swayidle | `scripts/.local/bin/toggle-idle` | Screen blank after 5 min |
| wob | `scripts/.local/bin/wob-daemon` | Volume/brightness OSD via FIFO pipe |
| zsh | `shell/` | env, aliases, zshrc, p10k prompt |
| Kitty | `kitty/` | Primary terminal |
| Alacritty | `alacritty/` | Secondary terminal |
| Zellij | `zellij/` | Terminal multiplexer |
| Git | `git/` | Global gitconfig |
| TLP | configured via `/etc/tlp.conf` | Battery charge capped at 85% |

## Power management

TLP manages battery health with a strict 85% charge ceiling (`STOP_CHARGE_THRESH_BAT0=85`). The Waybar battery module reads `/sys/class/power_supply/BAT0/charge_control_end_threshold` and displays a `health-limit` state when sitting at the cap.

## Daemon architecture

Niri starts four daemons at login via `spawn-at-startup`:

| Daemon | How it runs | Managed by |
|--------|-------------|------------|
| waybar | direct spawn | niri |
| swaync | direct spawn | niri |
| wob-daemon | direct spawn | niri |
| elephant | systemd user service | systemd (`elephant.service`) |

Walker is launched on-demand (`Mod+Slash`) and contacts the elephant backend over a socket. Elephant is protected against restart loops via `StartLimitBurst=5` / `StartLimitIntervalSec=60`.

## System configs

`system/` (earlyoom, journald, sysctl, zram) — applied manually per machine. `install.sh` does **not** touch these.

## Repo structure

```
~/dotfiles/
├── install.sh          # full one-shot installer (packages + stow)
├── stow.sh             # GNU Stow deploy only
├── packages.md         # manual package reference
├── README.md
├── AGENTS.md           # AI agent context — read before editing
├── keybinds.md         # quick keybind reference
├── niri/               # Niri compositor config
├── waybar/             # config.jsonc, style.css, battery.sh
├── mako/               # notification daemon config
├── swaync/             # notification center config
├── kitty/
├── alacritty/
├── zellij/             # config + themes + layouts
├── shell/              # env, aliases, zshrc, p10k.zsh
├── git/
├── scripts/            # .local/bin scripts (wallpaper, wob-daemon, etc.)
└── system/             # manual-only: earlyoom, journald, sysctl, zram
```

---

Not included: `~/.secrets`, `~/.ssh/`, GPG keys, `.env` files.
