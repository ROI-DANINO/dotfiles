#!/usr/bin/env bash
# install.sh — one-command fresh Fedora + Niri dotfiles deploy
# Usage: bash install.sh [--dry-run]
set -euo pipefail

# ── Colours ──────────────────────────────────────────────────────────────────
GRN='\033[0;32m'; YLW='\033[1;33m'; RED='\033[0;31m'; CYN='\033[0;36m'; NC='\033[0m'
ok()   { echo -e "  ${GRN}✓${NC}  $*"; }
info() { echo -e "  ${YLW}→${NC}  $*"; }
err()  { echo -e "  ${RED}✗${NC}  $*"; }
hdr()  { echo -e "\n${CYN}══ $* ══${NC}"; }

# ── Helpers ───────────────────────────────────────────────────────────────────
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DRY=false
[[ "${1:-}" == "--dry-run" ]] && DRY=true && info "Dry-run mode — no changes will be made"

cmd_exists() { command -v "$1" &>/dev/null; }
rpm_installed() { rpm -q "$1" &>/dev/null; }

dnf_install() {
    local pkgs=("$@")
    local to_install=()
    for pkg in "${pkgs[@]}"; do
        rpm_installed "$pkg" && ok "$pkg (already installed)" || to_install+=("$pkg")
    done
    if [[ ${#to_install[@]} -gt 0 ]]; then
        info "Installing: ${to_install[*]}"
        $DRY || sudo dnf install -y "${to_install[@]}"
        for pkg in "${to_install[@]}"; do ok "$pkg"; done
    fi
}

cargo_install() {
    local pkg="$1"; shift
    if cmd_exists "$pkg"; then
        ok "$pkg (already installed)"
    else
        info "cargo install $pkg $*"
        $DRY || cargo install --locked "$pkg" "$@"
        ok "$pkg"
    fi
}

# ── Guard: must be Fedora ─────────────────────────────────────────────────────
if ! grep -qi fedora /etc/os-release 2>/dev/null; then
    err "This script targets Fedora. Detected: $(grep ^ID= /etc/os-release | cut -d= -f2)"
    exit 1
fi

echo ""
echo "  Dotfiles — Fresh Install"
echo "  ════════════════════════"
echo "  Dotfiles: $DOTFILES_DIR"
echo "  Target  : $HOME"
echo ""

# ═════════════════════════════════════════════════════════════════════════════
hdr "1 · Core tools"
# ═════════════════════════════════════════════════════════════════════════════
dnf_install git gh stow

# ═════════════════════════════════════════════════════════════════════════════
hdr "2 · Shell"
# ═════════════════════════════════════════════════════════════════════════════
dnf_install zsh zsh-autosuggestions zsh-syntax-highlighting

if [[ "$SHELL" != "$(which zsh)" ]]; then
    info "Setting zsh as default shell (requires your password)"
    $DRY || chsh -s "$(which zsh)"
    ok "Default shell → zsh"
fi

if [[ ! -d "$HOME/powerlevel10k" ]]; then
    info "Cloning Powerlevel10k"
    $DRY || git clone --depth=1 \
        https://github.com/romkatv/powerlevel10k.git "$HOME/powerlevel10k"
    ok "Powerlevel10k"
else
    ok "Powerlevel10k (already present)"
fi

# ═════════════════════════════════════════════════════════════════════════════
hdr "3 · Terminals"
# ═════════════════════════════════════════════════════════════════════════════
dnf_install kitty

# ═════════════════════════════════════════════════════════════════════════════
hdr "4 · Window Manager / Niri session"
# ═════════════════════════════════════════════════════════════════════════════
dnf_install \
    niri \
    waybar \
    SwayNotificationCenter \
    swaylock \
    swayidle \
    wob \
    walker \
    elephant

# ═════════════════════════════════════════════════════════════════════════════
hdr "5 · Wallpaper (swww — Rust, via cargo)"
# ═════════════════════════════════════════════════════════════════════════════
if cmd_exists swww; then
    ok "swww (already installed)"
else
    if cmd_exists cargo; then
        info "Installing swww via cargo"
        $DRY || cargo install --locked swww
        ok "swww"
    else
        err "cargo not found — install Rust first: https://rustup.rs"
        info "Then run: cargo install --locked swww"
    fi
fi

# ═════════════════════════════════════════════════════════════════════════════
hdr "6 · Multiplexer (zellij — Rust, via cargo)"
# ═════════════════════════════════════════════════════════════════════════════
if cmd_exists zellij; then
    ok "zellij (already installed)"
else
    if cmd_exists cargo; then
        info "Installing zellij via cargo"
        $DRY || cargo install --locked zellij
        ok "zellij"
    else
        err "cargo not found — install Rust first: https://rustup.rs"
        info "Then run: cargo install --locked zellij"
    fi
fi

# ═════════════════════════════════════════════════════════════════════════════
hdr "7 · Battery management (TLP)"
# ═════════════════════════════════════════════════════════════════════════════
dnf_install tlp tlp-rdw

if ! systemctl is-enabled --quiet tlp 2>/dev/null; then
    info "Enabling TLP service"
    $DRY || sudo systemctl enable --now tlp
    ok "TLP enabled"
else
    ok "TLP (already enabled)"
fi

# Check/set 85% charge limit
THRESHOLD_PATH="/sys/class/power_supply/BAT0/charge_control_end_threshold"
if [[ -f "$THRESHOLD_PATH" ]]; then
    CURRENT=$(cat "$THRESHOLD_PATH")
    if [[ "$CURRENT" -ne 85 ]]; then
        info "Setting TLP charge limit to 85% (currently ${CURRENT}%)"
        info "Add to /etc/tlp.conf: STOP_CHARGE_THRESH_BAT0=85"
        info "Or run: sudo tlp setcharge 0 85 BAT0"
    else
        ok "TLP charge limit already at 85%"
    fi
fi

# ═════════════════════════════════════════════════════════════════════════════
hdr "8 · Network & Bluetooth"
# ═════════════════════════════════════════════════════════════════════════════
dnf_install network-manager-applet blueman

# ═════════════════════════════════════════════════════════════════════════════
hdr "9 · Display & input controls"
# ═════════════════════════════════════════════════════════════════════════════
dnf_install brightnessctl playerctl light mpv

# ═════════════════════════════════════════════════════════════════════════════
hdr "10 · File management & CLI tools"
# ═════════════════════════════════════════════════════════════════════════════
dnf_install yazi Thunar fzf wl-clipboard wtype bottom

# ═════════════════════════════════════════════════════════════════════════════
hdr "11 · Fonts"
# ═════════════════════════════════════════════════════════════════════════════
dnf_install jetbrains-mono-fonts

# ═════════════════════════════════════════════════════════════════════════════
hdr "12 · npm global path"
# ═════════════════════════════════════════════════════════════════════════════
if cmd_exists npm; then
    if [[ ! -d "$HOME/.npm-global" ]]; then
        info "Configuring npm global prefix"
        $DRY || mkdir -p "$HOME/.npm-global"
        $DRY || npm config set prefix "$HOME/.npm-global"
        ok "npm global → ~/.npm-global"
    else
        ok "npm global prefix (already configured)"
    fi
else
    info "npm not found — skipping (install Node.js to get npm)"
fi

# ═════════════════════════════════════════════════════════════════════════════
hdr "13 · elephant systemd user service"
# ═════════════════════════════════════════════════════════════════════════════
if cmd_exists elephant; then
    if systemctl --user is-enabled --quiet elephant 2>/dev/null; then
        ok "elephant service (already enabled)"
    else
        info "Enabling elephant systemd user service"
        $DRY || systemctl --user enable --now elephant
        ok "elephant service enabled"
    fi
else
    err "elephant not installed — skipping service setup"
fi

# ═════════════════════════════════════════════════════════════════════════════
hdr "14 · Zen Browser"
# ═════════════════════════════════════════════════════════════════════════════
if [[ -x "/opt/zen/zen" ]]; then
    ok "Zen Browser (already installed)"
else
    info "Installing Zen Browser → /opt/zen"
    ZEN_URL=$(curl -s https://api.github.com/repos/zen-browser/desktop/releases/latest \
        | grep -o '"browser_download_url":"[^"]*"' \
        | grep -v aarch64 | grep 'linux.*\.tar\.bz2' | head -1 | cut -d'"' -f4)
    if [[ -z "$ZEN_URL" ]]; then
        err "Could not fetch Zen Browser release — install manually from https://zen-browser.app"
    else
        $DRY || (curl -L "$ZEN_URL" -o /tmp/zen.tar.bz2 \
            && sudo mkdir -p /opt/zen \
            && sudo tar -xjf /tmp/zen.tar.bz2 -C /opt/zen --strip-components=1 \
            && rm /tmp/zen.tar.bz2)
        mkdir -p "$HOME/.local/share/applications"
        $DRY || cat > "$HOME/.local/share/applications/zen.desktop" << 'DESKTOP'
[Desktop Entry]
Name=Zen Browser
Comment=Experience tranquillity while browsing the web without people telling you what to do
Exec=/opt/zen/zen %u
Icon=/opt/zen/browser/chrome/icons/default/default128.png
Type=Application
Categories=Network;WebBrowser;
MimeType=text/html;text/xml;application/xhtml+xml;x-scheme-handler/http;x-scheme-handler/https;application/x-xpinstall;application/pdf;application/json;
StartupNotify=true
Terminal=false
StartupWMClass=zen
DESKTOP
        ok "Zen Browser"
    fi
fi

# Set Zen as default browser
if [[ -x "/opt/zen/zen" ]]; then
    $DRY || xdg-settings set default-web-browser zen.desktop 2>/dev/null && ok "Zen → default browser" || true
fi

# ═════════════════════════════════════════════════════════════════════════════
hdr "15 · Zed IDE"
# ═════════════════════════════════════════════════════════════════════════════
if cmd_exists zed; then
    ok "Zed (already installed)"
else
    info "Installing Zed IDE"
    $DRY || curl -f https://zed.dev/install.sh | sh
    ok "Zed"
fi

# ═════════════════════════════════════════════════════════════════════════════
hdr "16 · Flatpak apps"
# ═════════════════════════════════════════════════════════════════════════════
flatpak_install() {
    local app="$1"; local label="$2"
    if flatpak list --app 2>/dev/null | grep -q "^$app"; then
        ok "$label (already installed)"
    else
        info "Installing $label"
        $DRY || flatpak install -y flathub "$app"
        ok "$label"
    fi
}

flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo 2>/dev/null || true

flatpak_install org.chromium.Chromium                "Chromium"
flatpak_install md.obsidian.Obsidian                 "Obsidian"
flatpak_install com.spotify.Client                   "Spotify"
flatpak_install com.stremio.Stremio                  "Stremio"
flatpak_install org.localsend.localsend_app          "LocalSend"
flatpak_install me.proton.Pass                       "Proton Pass"
flatpak_install io.podman_desktop.PodmanDesktop      "Podman Desktop"
flatpak_install org.kde.kdenlive                     "Kdenlive"
flatpak_install com.mattjakeman.ExtensionManager     "Extension Manager"

# ═════════════════════════════════════════════════════════════════════════════
hdr "17 · Claude Code"
# ═════════════════════════════════════════════════════════════════════════════
if [[ -x "$HOME/.local/bin/claude" ]]; then
    ok "Claude Code (already installed)"
else
    info "Installing Claude Code native binary"
    $DRY || curl -fsSL https://claude.ai/install.sh | bash
    ok "Claude Code"
fi

# ═════════════════════════════════════════════════════════════════════════════
hdr "18 · Claude Code plugins"
# ═════════════════════════════════════════════════════════════════════════════
claude_plugin_install() {
    local plugin="$1"
    if "$HOME/.local/bin/claude" plugin list 2>/dev/null | grep -q "^  ❯ ${plugin}$"; then
        ok "$plugin (already installed)"
    else
        info "Installing plugin: $plugin"
        $DRY || "$HOME/.local/bin/claude" plugin install "$plugin"
        ok "$plugin"
    fi
}

if [[ -x "$HOME/.local/bin/claude" ]]; then
    claude_plugin_install "remember@claude-plugins-official"
    claude_plugin_install "superpowers@claude-plugins-official"
else
    info "Claude Code not found — skipping plugins"
fi

# ═════════════════════════════════════════════════════════════════════════════
hdr "19 · Stow dotfiles"
# ═════════════════════════════════════════════════════════════════════════════
if $DRY; then
    info "Dry-run: would execute $DOTFILES_DIR/stow.sh"
else
    bash "$DOTFILES_DIR/stow.sh"
fi

# ═════════════════════════════════════════════════════════════════════════════
echo ""
echo -e "  ${GRN}Installation complete.${NC}"
echo ""
echo "  Next steps:"
echo "    1. source ~/.zshrc           — reload shell"
echo "    2. Log out and back in       — apply zsh as default + start niri session"
echo "    3. Run p10k configure        — set up your prompt (first zsh login)"
echo ""
echo "  Optional:"
echo "    • VR stack     : sudo dnf install wivrn wayvr"
echo ""
