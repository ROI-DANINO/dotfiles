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
if ask "[shell]   Install shell env, aliases + p10k?"; then
  link "$DOTFILES_DIR/shell/env"     "$HOME/.shell_env"
  link "$DOTFILES_DIR/shell/aliases" "$HOME/.shell_aliases"

  for line in \
    "[ -f ~/.shell_env ] && source ~/.shell_env" \
    "[ -f ~/.shell_aliases ] && source ~/.shell_aliases"; do
    grep -qF "$line" "$SHELL_RC" || echo "$line" >> "$SHELL_RC"
  done
  ok "Shell source lines added to $SHELL_RC"

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
