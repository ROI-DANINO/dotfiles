# Stow Architecture

## Repository Architecture (GNU Stow)

`~/dotfiles` is a GNU Stow repository. Each top-level directory is a **stow package**. `stow.sh` mirrors each package's subtree into `$HOME`.

Example: `dotfiles/niri/.config/niri/config.kdl` → `~/.config/niri/config.kdl`

Active stow packages (managed by `stow.sh`):

| Package | Stow target |
|---------|-------------|
| `niri/` | `~/.config/niri/` |
| `waybar/` | `~/.config/waybar/` |
| `dunst/` | `~/.config/dunst/` |
| `hyprlock/` | `~/.config/hypr/` |
| `kitty/` | `~/.config/kitty/` |
| `shell/` | `~/.zshrc`, `~/.shell_env`, etc. |
| `git/` | `~/.gitconfig` |
| `gtk/` | `~/.config/gtk-3.0/gtk.css`, `~/.config/gtk-4.0/gtk.css` |
| `wob/` | `~/.config/wob/wob.ini` |
| `walker/` | `~/.config/walker/config.toml`, `~/.config/walker/themes/brand/` |
| `zed/` | `~/.config/zed/settings.json`, `~/.config/zed/themes/brand.json` |
| `scripts/` | `~/.local/bin/` scripts |
| `wallpapers/` | `~/Pictures/walpapers/` image assets, tracked with Git LFS |

**`system/`** is NOT a stow package — manual reference only.
