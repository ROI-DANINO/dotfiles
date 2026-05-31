# Packages — Fresh Machine Setup

Reference list for what `install.sh` installs. Run `install.sh` instead of doing this manually — it's idempotent and handles everything below.

```bash
git clone https://github.com/ROI-DANINO/dotfiles ~/dotfiles
bash ~/dotfiles/install.sh
```

## Stow Modules

Dotfiles are managed with GNU Stow. Each directory in `~/dotfiles/` is a stow package that symlinks its contents into `$HOME`. New modules added recently:

- `wob`     — `~/.config/wob/wob.ini`                          (brand palette OSD bar)
- `walker`  — `~/.config/walker/{config.yaml,style.css}`       (brand palette GTK4 launcher)
- `zed`     — `~/.config/zed/{settings.json,themes/}`          (Brand Navy editor theme)

---

## Core Tools

```bash
sudo dnf install git gh stow
```

## Shell

```bash
sudo dnf install zsh zsh-autosuggestions zsh-syntax-highlighting
chsh -s $(which zsh)

# Powerlevel10k prompt
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/powerlevel10k
```

## Terminals

```bash
sudo dnf install kitty
```

## Multiplexer (Rust)

```bash
# via cargo (install.sh handles this):
cargo install --locked zellij
```

## Window Manager — Niri session

```bash
sudo dnf install niri waybar SwayNotificationCenter swaylock swayidle wob walker elephant
```

### elephant (walker data-provider backend)
Provides search index / application data to walker. Managed as a **systemd user service** — do not spawn it directly from niri `spawn-at-startup`.

```bash
# install.sh handles this:
systemctl --user enable --now elephant
```

Service file: `~/.config/systemd/user/elephant.service`
Key guards: `Restart=on-failure`, `StartLimitBurst=5`, `StartLimitIntervalSec=60`, `MemoryHigh=512M`

### swww (wallpaper daemon — Rust, GPU-accelerated)

```bash
# via cargo (install.sh handles this):
cargo install --locked swww

# or check Fedora repos:
sudo dnf install swww
```

Launched at startup via `scripts/.local/bin/wallpaper-rotate`. Rotates from `~/Pictures/walpapers` every 10 minutes in a random no-repeat cycle, then rescans the folder before the next pass. Wallpaper images live in the `wallpapers/` stow package and are tracked with Git LFS.

### wob (on-screen volume/brightness bar)

Started via `scripts/.local/bin/wob-daemon` (not raw `wob`). The daemon creates `/tmp/wob.fifo` and keeps the pipe alive with `tail -f` to prevent orphan processes. Write a 0–100 integer to the FIFO to trigger the OSD.

### swayidle (screen idle / lock)

Managed via `scripts/.local/bin/toggle-idle`. Blanks screen after 5 minutes of inactivity. Uses `swaylock -c 000000` for locking.

## Battery Management

```bash
sudo dnf install tlp tlp-rdw
sudo systemctl enable --now tlp
```

Charge threshold is capped at **85%** for battery longevity (Zenbook / ASUS hardware).

```ini
# /etc/tlp.conf
STOP_CHARGE_THRESH_BAT0=85
```

The Waybar `battery.sh` reads `/sys/class/power_supply/BAT0/charge_control_end_threshold` dynamically and shows a `health-limit` CSS class when sitting at the cap.

## Network & Bluetooth

```bash
sudo dnf install network-manager-applet blueman
```

## GTK Theme Override

No packages required. The `gtk` stow module deploys `~/.config/gtk-3.0/gtk.css`
and `~/.config/gtk-4.0/gtk.css` which layer brand navy/cream/teal colors on top
of the active Orchis-Dark GTK theme. Applies to: blueman, thunar, nm-applet, walker.

## Display & Input Controls

```bash
sudo dnf install brightnessctl playerctl light
```

## File Management & CLI Tools

```bash
sudo dnf install yazi Thunar fzf wl-clipboard bottom
```

- `yazi` — Rust TUI file manager (primary, alias: `y`)
- `thunar` — GUI file manager (`Mod+F`)
- `bottom` — system monitor (`Alt+M`)
- `wl-clipboard` — Wayland clipboard (`wl-copy`/`wl-paste`)

## Fonts

```bash
sudo dnf install jetbrains-mono-fonts
# For Nerd Font variant: download from https://www.nerdfonts.com/font-downloads
# Unzip to ~/.local/share/fonts/ and run: fc-cache -fv
```

Used by: kitty, zellij, waybar.

## Browsers

### Zen Browser
Download latest tarball from GitHub releases and extract to `/opt/zen`. `install.sh` handles this automatically.

Manual install:
```bash
# install.sh does this — or download from https://zen-browser.app
ZEN_URL=$(curl -s https://api.github.com/repos/zen-browser/desktop/releases/latest \
  | grep -o '"browser_download_url":"[^"]*"' \
  | grep -v aarch64 | grep 'linux.*\.tar\.bz2' | head -1 | cut -d'"' -f4)
curl -L "$ZEN_URL" -o /tmp/zen.tar.bz2
sudo mkdir -p /opt/zen && sudo tar -xjf /tmp/zen.tar.bz2 -C /opt/zen --strip-components=1
```

Set as default browser: `xdg-settings set default-web-browser zen.desktop`

## IDEs

### Zed
```bash
curl -f https://zed.dev/install.sh | sh
# installs to ~/.local/zed.app/, symlink at ~/.local/bin/zed
```

## Flatpak Apps

```bash
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

flatpak install flathub org.chromium.Chromium
flatpak install flathub md.obsidian.Obsidian
flatpak install flathub com.spotify.Client
flatpak install flathub com.stremio.Stremio
flatpak install flathub org.localsend.localsend_app
flatpak install flathub me.proton.Pass
flatpak install flathub io.podman_desktop.PodmanDesktop
flatpak install flathub org.kde.kdenlive
flatpak install flathub com.mattjakeman.ExtensionManager
```

`install.sh` handles all of the above automatically.

## AI CLI Tools

```bash
# Claude Code — native binary (do NOT install via npm)
# Download from https://claude.ai/code or use the native installer
# Installed at ~/.local/bin/claude

# Gemini CLI
npm install -g @google/gemini-cli

# OpenAI Codex
npm install -g @openai/codex

# Hermes (multi-agent framework)
# See https://github.com/hermesagent/hermes for install instructions
```

## npm Global Path

```bash
mkdir -p ~/.npm-global
npm config set prefix ~/.npm-global
# PATH is already set in shell/.zshrc
```

## VR (optional)

```bash
sudo dnf install wivrn wayvr
```

`wayvr` provides a virtual desktop layer for VR inside the Niri/Wayland session. Launch via `scripts/.local/bin/vr-desktop`.

---

## After installing everything

```bash
source ~/.zshrc
# then log out and back in to start the Niri session
```
