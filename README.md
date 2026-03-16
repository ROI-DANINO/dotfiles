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
| niri | `niri/config.kdl` | 🚧 in progress |
| waybar | `waybar/` | 🚧 in progress |
| system tuning | `system/` | ✓ manual apply |

## System configs

See `system/README.md` — applied manually per machine, not by `setup.sh`.

## In progress

- **niri** — keybinds, startup apps, and layout still being refined
- **waybar** — layout and modules undecided
- **hyprlock + hypridle** — replacing swaylock, not yet installed/configured
- **COSMIC DE** — not yet configured

## TODO

- [ ] Install and configure hyprlock + hypridle
- [ ] Finalize waybar layout and modules
- [ ] Add COSMIC config once configured
- [ ] Add walker config once customized

---

Not included: `~/.secrets`, `~/.ssh/`, GPG keys, `.env` files.
