# Packages — Fresh Machine Setup

Install these before running `./setup.sh`.

## Terminals

```bash
sudo dnf install kitty alacritty
```

## Shell

```bash
# zsh + p10k
sudo dnf install zsh
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
sudo dnf install niri waybar swaync swaylock walker fuzzel
# elephant (powers walker — install from https://github.com/nickvdyck/elephant or your source)
```

## File Managers

```bash
# broot (Rust TUI navigator — manual use)
sudo dnf install broot

# cosmic-files (GUI, Mod+F) — installed with COSMIC DE
# or: flatpak install flathub com.system76.CosmicFiles
```

## CLI Tools

```bash
sudo dnf install fzf yazi btm wl-clipboard git gh
```

## Fonts

```bash
# JetBrainsMono Nerd Font (used by kitty, alacritty, zellij)
sudo dnf install jetbrains-mono-fonts
# or download from https://www.nerdfonts.com/font-downloads
```

## AI Tools

```bash
# Claude Code
npm install -g @anthropic-ai/claude-code

# opencode
# https://opencode.ai
```

## Media / Misc

```bash
sudo dnf install oculante   # image viewer (alias: img)
```

## npm global path

```bash
mkdir -p ~/.npm-global
npm config set prefix ~/.npm-global
# PATH is set in shell/env already
```

## After installing everything

```bash
cd ~/dotfiles
./setup.sh
source ~/.zshrc
```
