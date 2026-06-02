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
| Dunst | `dunst/` | Notification daemon (brand palette) |
| Walker | managed by niri startup | App launcher, powered by elephant |
| Elephant | systemd user service | Walker data-provider backend |
| swww | `scripts/.local/bin/wallpaper-rotate` | Wallpaper daemon, rotates every 10 min from `~/Pictures/walpapers` in a random no-repeat cycle |
| swayidle | `scripts/.local/bin/toggle-idle` | Idle: blank 5 min -> auto-lock 10 min; toggle can blank immediately |
| swaylock | `swaylock/` | Brand palette lock screen |
| wob | `scripts/.local/bin/wob-daemon` | Volume/brightness OSD via FIFO pipe |
| zsh | `shell/` | env, aliases, zshrc, p10k prompt |
| Kitty | `kitty/` | Primary terminal (brand Navy palette) |
| Git | `git/` | Global gitconfig |
| GTK | `gtk/` | Brand palette override for GTK apps (navy/cream/teal on Orchis-Dark) |
| wob | `wob/` | OSD bar config with brand palette colors |
| Walker | `walker/` | App launcher config + brand palette theme CSS |
| Zed | `zed/` | Editor settings + Brand Navy color theme |
| TLP | configured via `/etc/tlp.conf` | Battery charge capped at 85% |
| Wallpapers | `wallpapers/` | Stowed into `~/Pictures/walpapers`; image assets are tracked with Git LFS |

## Power management

TLP manages battery health with a strict 85% charge ceiling (`STOP_CHARGE_THRESH_BAT0=85`). The Waybar battery module reads `/sys/class/power_supply/BAT0/charge_control_end_threshold` and displays a `health-limit` state when sitting at the cap.

## Daemon architecture

Niri starts eight daemons at login via `spawn-at-startup`, plus one systemd user service:

| Daemon | How it runs | Purpose |
|--------|-------------|---------|
| waybar | niri direct spawn | status bar |
| dunst | niri direct spawn | notification daemon |
| walker | niri direct spawn (`--gapplication-service`) | app launcher backend |
| wob-daemon | niri direct spawn | volume/brightness OSD (FIFO pipe) |
| nm-applet | niri direct spawn (`--indicator`) | network tray applet |
| blueman-applet | niri direct spawn | bluetooth tray applet |
| wallpaper-rotate | niri direct spawn | swww wallpaper rotation (10 min, random no-repeat cycle) |
| swayidle | niri direct spawn | blank monitors at 300s, auto-lock (swaylock) at 600s |
| elephant | systemd user service | walker data-provider backend |

`Mod+Shift+K` toggles idle on/off: off kills `swayidle`; on starts it and immediately powers off the monitors while preserving the 300s blank / 600s auto-lock timers. `Mod+Shift+L` locks immediately. Elephant is protected against restart loops via `StartLimitBurst=5` / `StartLimitIntervalSec=60`.

## Text utilities

`scripts/.local/bin/layout-fix` fixes selected Hebrew/English text typed with the wrong keyboard layout. Select text, press `Mod+G`, and the selection is replaced with the exact key-position conversion. It uses `wl-clipboard` to read/write the selection and `wtype` to paste the converted text.

This is layout conversion, not Hebrew spell correction. The script intentionally leaves the converted text on the clipboard after paste; restoring the old clipboard too quickly can make some apps paste the old value instead.

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
├── dunst/              # notification daemon (brand palette)
├── swaylock/           # lock screen (brand palette)
├── kitty/              # terminal (brand Navy palette)
├── shell/              # env, aliases, zshrc, p10k.zsh
├── git/
├── gtk/                # brand palette gtk.css for GTK3 + GTK4 apps
├── wob/                # brand palette wob OSD config
├── walker/             # brand palette launcher (config.toml + themes/brand/)
├── zed/                # Brand Navy editor theme
├── scripts/            # .local/bin scripts (wallpaper, wob-daemon, toggle-idle, etc.)
├── wallpapers/         # Pictures/walpapers via GNU Stow; Git LFS image assets
├── archived/           # alacritty, swaync, zellij — preserved, not stowed
└── system/             # manual-only: earlyoom, journald, sysctl, zram
```

---

Not included: `~/.secrets`, `~/.ssh/`, GPG keys, `.env` files.
