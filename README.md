# dotfiles — Roi Danino

Personal dotfiles for Fedora / COSMIC DE / niri.
Symlink-based. Interactive setup.

## Quick start

```bash
git clone https://github.com/ROI-DANINO/dotfiles ~/dotfiles
cd ~/dotfiles
./setup.sh
source ~/.zshrc
```

See `packages.md` for everything to install before running setup.

## What's included

| Component | Config | Status |
|-----------|--------|--------|
| shell env + aliases | `shell/env`, `shell/aliases` | ✓ |
| zshrc | `shell/zshrc` | ✓ |
| p10k prompt | `shell/p10k.zsh` | ✓ lean style |
| kitty | `kitty/kitty.conf` | ✓ |
| alacritty | `alacritty/alacritty.toml` | ✓ |
| zellij | `zellij/config.kdl` | ✓ |
| git | `git/gitconfig` | ✓ |
| niri | `niri/config.kdl` | ✓ |
| waybar | `waybar/` | ✓ |
| sysbar | `~/.local/bin/sysbar` | ✓ custom GTK bar (battery, RAM, network, time) |
| wallpaper | `~/.local/bin/wallpaper-rotate` | ✓ swww, rotates every 10min from `~/Pictures/walpapers` |
| idle | `~/.local/bin/toggle-idle` | ✓ swayidle, blanks screen after 5min |
| system tuning | `system/` | ✓ manual apply |

## System configs

See `system/README.md` — applied manually per machine, not by `setup.sh`.

## In progress

- **walker** — not yet configured/customized

## TODO

- [x] Finalize waybar layout and modules
- [x] Add COSMIC config once configured
- [ ] Customize walker and add config to dotfiles (currently running on defaults, no config file exists yet)

---

Not included: `~/.secrets`, `~/.ssh/`, GPG keys, `.env` files.
