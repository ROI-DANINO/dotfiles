# dotfiles

Personal dotfiles for Fedora / COSMIC DE / niri. Symlink-based. Interactive setup. Vim-native keybindings.

## Quick start

```bash
git clone https://github.com/ROI-DANINO/dotfiles ~/dotfiles
cd ~/dotfiles
./setup.sh
source ~/.zshrc
```

## What's included

| Component | Config file | Installed to |
|-----------|-------------|--------------|
| shell env | `shell/env` | `~/.shell_env` |
| shell aliases | `shell/aliases` | `~/.shell_aliases` |
| p10k prompt | `shell/p10k.zsh` | `~/.p10k.zsh` |
| kitty | `kitty/kitty.conf` | `~/.config/kitty/kitty.conf` |
| alacritty | `alacritty/alacritty.toml` | `~/.config/alacritty/alacritty.toml` |
| zellij | `zellij/config.kdl` | `~/.config/zellij/config.kdl` |
| waybar | `waybar/` | `~/.config/waybar/` |
| git | `git/gitconfig` | `~/.gitconfig` |
| niri | `niri/config.kdl` | `~/.config/niri/config.kdl` |

## System configs

See **[system/README.md](system/README.md)** — these configs (sysctl, zram, journald, earlyoom) are applied manually per machine and not installed by `setup.sh`.

## Keybinding philosophy

Vim motions (hjkl) are consistently mapped across:
- **kitty splits** — split navigation and management
- **niri window focus** — switch between windows
- **future editor integration** — planned for Neovim/Helix setup

Stick to application defaults for keybindings that don't naturally map to vim-style (e.g., app-specific hotkeys). No machine-specific custom bindings — keep configs portable.

## Setup script

`./setup.sh` is interactive and will:
- Prompt for each component (shell, kitty, git, niri)
- Detect your shell (`zsh` or `bash`)
- Create symlinks from repo files to your home directory
- Back up existing configs to `~/.dotfiles-backup-TIMESTAMP/` before overwriting

Run `./setup.sh --help` for more options (if implemented).

## TODO

- [x] Edit `shell/p10k.zsh` to your liking — keeping lean style as-is
- [ ] Add COSMIC config once configured
- [ ] See `packages.md` for full install list on a fresh machine

---

**Note:** This repo does NOT include `~/.secrets`, `~/.ssh/`, GPG keys, or `.env` files. Back those up separately.
