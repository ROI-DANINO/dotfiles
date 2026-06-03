#!/usr/bin/env bash
# stow.sh — deploy all dotfile packages via GNU Stow
# Usage: ./stow.sh [--dry-run] [--unstow]
set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET="$HOME"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

ok()   { echo -e "  ${GREEN}✓${NC} $1"; }
info() { echo -e "  ${YELLOW}→${NC} $1"; }
err()  { echo -e "  ${RED}✗${NC} $1"; }

STOW_FLAGS=("--dir=$DOTFILES_DIR" "--target=$TARGET" "--verbose=1")
ACTION="stow"

for arg in "$@"; do
  case "$arg" in
    --dry-run) STOW_FLAGS+=("--simulate") ; info "Dry-run mode — no changes will be made" ;;
    --unstow)  ACTION="unstow" ;;
  esac
done

PACKAGES=(
  niri
  kitty
  waybar
  dunst
  hyprlock
  shell
  git
  gtk
  wob
  walker
  zed
  scripts
  wallpapers
)

echo ""
echo "Dotfiles — GNU Stow deploy"
echo "=========================="
echo "  Source : $DOTFILES_DIR"
echo "  Target : $TARGET"
echo "  Action : $ACTION"
echo ""

for pkg in "${PACKAGES[@]}"; do
  if [ -d "$DOTFILES_DIR/$pkg" ]; then
    if stow "${STOW_FLAGS[@]}" "--$ACTION" "$pkg" 2>&1; then
      ok "$pkg"
    else
      err "$pkg — stow reported a conflict (run with --dry-run to inspect)"
    fi
  else
    info "$pkg — directory not found, skipping"
  fi
done

echo ""
echo "Done. Reload your shell: source ~/.zshrc"
echo ""
