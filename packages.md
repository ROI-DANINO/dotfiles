# Packages — Fresh Machine Setup

Install these before running `./stow.sh`.

## Core Tools

```bash
sudo dnf install git gh stow
```

## Terminals

```bash
sudo dnf install kitty alacritty
```

## Shell

```bash
# zsh + p10k
sudo dnf install zsh zsh-autosuggestions zsh-syntax-highlighting
chsh -s $(which zsh)

# Powerlevel10k
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/powerlevel10k
```

## Multiplexer

```bash
sudo dnf install zellij
```

## Window Manager (niri session)

```bash
sudo dnf install niri waybar swaync swaylock swayidle wob mako walker
```

### elephant (walker data provider)
Powers walker's extended search capabilities. Install from:
https://github.com/nickvdyck/elephant/releases

After installing, enable as a systemd user service:
```bash
systemctl --user enable --now elephant
```

### swww (wallpaper daemon — Rust, GPU-accelerated transitions)
```bash
# Check Fedora repos first:
sudo dnf install swww
# or build from source: https://github.com/LGFae/swww
```

## Notifications

```bash
sudo dnf install mako  # already included above via waybar deps; confirm it's present
```

## Battery Management

```bash
sudo dnf install tlp tlp-rdw
sudo systemctl enable --now tlp

# Set charge limit (85% recommended for longevity):
sudo tlp setcharge 0 85 BAT0
# Or edit /etc/tlp.conf:
# STOP_CHARGE_THRESH_BAT0=85
```

## Network & Bluetooth

```bash
sudo dnf install network-manager-applet blueman
```

## Display & Input

```bash
sudo dnf install brightnessctl playerctl
# light (alternative for backlight — used by waybar config):
sudo dnf install light
```

## File Managers

```bash
# yazi (Rust TUI — primary)
sudo dnf install yazi

# thunar (GUI, Mod+F)
sudo dnf install thunar
```

## CLI Tools

```bash
sudo dnf install fzf btm wl-clipboard
# bottom (btm) may be in a different package name:
# sudo dnf install bottom
```

## Fonts

```bash
# JetBrainsMono Nerd Font (used by kitty, alacritty, zellij, waybar)
sudo dnf install jetbrains-mono-fonts
# or install Nerd Font patched version from: https://www.nerdfonts.com/font-downloads
# Unzip to ~/.local/share/fonts/ and run: fc-cache -fv
```

## Image Viewer

```bash
# oculante (alias: img)
sudo dnf install oculante
# or: https://github.com/woelper/oculante/releases
```

## AI Tools

```bash
# Claude Code
npm install -g @anthropic-ai/claude-code

# opencode
# https://opencode.ai
```

## npm global path

```bash
mkdir -p ~/.npm-global
npm config set prefix ~/.npm-global
# PATH is already set in shell/.shell_env
```

## VR (optional)

```bash
sudo dnf install wivrn wayvr
```

## After installing everything

```bash
cd ~/dotfiles
./stow.sh
source ~/.zshrc
```
