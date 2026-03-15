#!/usr/bin/env bash
set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/.dotfiles-backup-$(date +%Y%m%d%H%M%S)"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

ok()   { echo -e "  ${GREEN}✓${NC} $1"; }
info() { echo -e "  ${YELLOW}→${NC} $1"; }

ask() {
  read -r -p "$1 (y/n): " answer
  [[ "$answer" == "y" ]]
}

link() {
  local src="$1" dst="$2"
  mkdir -p "$(dirname "$dst")"
  if [ -e "$dst" ] && [ ! -L "$dst" ]; then
    mkdir -p "$BACKUP_DIR"
    info "Backed up $(basename "$dst") to $BACKUP_DIR/"
    mv "$dst" "$BACKUP_DIR/"
  fi
  ln -sf "$src" "$dst"
  ok "Linked $(basename "$src") → $dst"
}

cmd_exists() { command -v "$1" &>/dev/null; }

# Detect shell rc file
if [ -n "$ZSH_VERSION" ] || [ -f "$HOME/.zshrc" ]; then
  SHELL_RC="$HOME/.zshrc"
else
  SHELL_RC="$HOME/.bashrc"
fi

echo ""
echo "Dotfiles Setup"
echo "=============="
echo "Detected shell rc: $SHELL_RC"
echo ""

# --- shell ---
if ask "[shell]   Install shell env, aliases, zshrc + p10k?"; then
  link "$DOTFILES_DIR/shell/env"     "$HOME/.shell_env"
  link "$DOTFILES_DIR/shell/aliases" "$HOME/.shell_aliases"
  link "$DOTFILES_DIR/shell/zshrc"   "$HOME/.zshrc"

  if [ -f "$DOTFILES_DIR/shell/p10k.zsh" ]; then
    link "$DOTFILES_DIR/shell/p10k.zsh" "$HOME/.p10k.zsh"
  else
    info "No p10k.zsh found in repo — skipping"
  fi
else
  info "Skipped shell"
fi
echo ""

# --- kitty ---
if cmd_exists kitty; then
  if ask "[kitty]   Install kitty config?"; then
    link "$DOTFILES_DIR/kitty/kitty.conf" "$HOME/.config/kitty/kitty.conf"
  else
    info "Skipped kitty"
  fi
else
  info "[kitty]   kitty not installed — skipping"
fi
echo ""

# --- alacritty ---
if cmd_exists alacritty; then
  if ask "[alacritty] Install alacritty config?"; then
    link "$DOTFILES_DIR/alacritty/alacritty.toml" "$HOME/.config/alacritty/alacritty.toml"
  else
    info "Skipped alacritty"
  fi
else
  info "[alacritty] alacritty not installed — skipping"
fi
echo ""

# --- zellij ---
if cmd_exists zellij; then
  if ask "[zellij]  Install zellij config?"; then
    link "$DOTFILES_DIR/zellij/config.kdl" "$HOME/.config/zellij/config.kdl"
    for f in "$DOTFILES_DIR/zellij/themes"/*; do
      [ -f "$f" ] && link "$f" "$HOME/.config/zellij/themes/$(basename "$f")"
    done
    for f in "$DOTFILES_DIR/zellij/layouts"/*; do
      [ -f "$f" ] && link "$f" "$HOME/.config/zellij/layouts/$(basename "$f")"
    done
  else
    info "Skipped zellij"
  fi
else
  info "[zellij]  zellij not installed — skipping"
fi
echo ""

# --- waybar ---
if cmd_exists waybar; then
  if ask "[waybar]  Install waybar config?"; then
    link "$DOTFILES_DIR/waybar/config.jsonc" "$HOME/.config/waybar/config.jsonc"
    link "$DOTFILES_DIR/waybar/style.css"    "$HOME/.config/waybar/style.css"
    link "$DOTFILES_DIR/waybar/battery.sh"   "$HOME/.config/waybar/battery.sh"
  else
    info "Skipped waybar"
  fi
else
  info "[waybar]  waybar not installed — skipping"
fi
echo ""

# --- git ---
if cmd_exists git; then
  if ask "[git]     Install git config?"; then
    link "$DOTFILES_DIR/git/gitconfig" "$HOME/.gitconfig"
  else
    info "Skipped git"
  fi
else
  info "[git]     git not installed — skipping"
fi
echo ""

# --- niri ---
if cmd_exists niri; then
  if [ -f "$DOTFILES_DIR/niri/config.kdl" ]; then
    if ask "[niri]    Install niri config?"; then
      link "$DOTFILES_DIR/niri/config.kdl" "$HOME/.config/niri/config.kdl"
    else
      info "Skipped niri"
    fi
  else
    info "[niri]    No niri config in repo yet — add niri/config.kdl when ready"
  fi
else
  info "[niri]    niri not installed — skipping"
fi
echo ""

echo "Setup complete."
echo "Reload your shell: source $SHELL_RC"
echo ""
echo "NOTE: system/ configs (sysctl, zram, etc.) are NOT applied automatically."
echo "See system/README.md for instructions."
