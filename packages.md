# Packages — Fresh Machine Setup

Reference list for what `install.sh` installs. Run `install.sh` instead of doing this manually — it's idempotent and handles everything below.

```bash
git clone https://github.com/ROI-DANINO/dotfiles ~/dotfiles
bash ~/dotfiles/install.sh
```

## Stow Modules

Dotfiles are managed with GNU Stow. Each directory in `~/dotfiles/` is a stow package that symlinks its contents into `$HOME`. New modules added recently:

- `wob`     — `~/.config/wob/wob.ini`                               (brand palette OSD bar)
- `walker`  — `~/.config/walker/{config.toml,themes/brand/}`       (brand palette GTK4 launcher)
- `zed`     — `~/.config/zed/{settings.json,themes/brand.json}`    (Brand Navy editor theme)

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

Kitty config at `~/.config/kitty/kitty.conf` (managed by `kitty/` stow module).
- Brand Navy palette (`#1E3045` background, brand-cream foreground, `background_opacity 0.86`)
- `shell_integration enabled` — enables close-confirmation for windows with running processes
- `confirm_os_window_close -1` — prompts before closing a window that has a running process

## Multiplexer

Zellij is archived (`archived/zellij/`) — it breaks CLI rendering of AI agents (Claude Code,
Gemini CLI, Codex). For background tasks use systemd user services or `disown` from the shell.

## Window Manager — Niri session

```bash
sudo dnf install niri waybar dunst swayidle wob walker elephant
```

Note: `SwayNotificationCenter` (swaync) is archived — `dunst` is the active notification daemon.
Note: `swaylock` is **not** a dnf package here — it is built from source as the
swaylock-effects fork (blur/fade/vignette). See the swaylock section below.

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

### swayidle (screen idle / power-off / auto-lock)

Managed via `scripts/.local/bin/toggle-idle`. Two-phase idle pipeline:
1. **300 s** → `niri msg action power-off-monitors` — OLED pixels fully off. Any mouse or key input fires `resume` and brings the display back. **No password required.**
2. **600 s** → `swaylock` — auto-lock with brand palette. Password required to unlock.
3. **resume** → `niri msg action power-on-monitors`

`Mod+Shift+K` toggles swayidle on/off. If swayidle is running, it kills it; if not, it starts the idle pipeline and immediately runs `niri msg action power-off-monitors`. `Mod+Shift+L` locks immediately via swaylock.

### swaylock (screen locker — swaylock-effects fork)

We use the **swaylock-effects** fork (not Fedora's plain `swaylock`) for blur,
fade-in, and vignette. It is built from source — `install.sh` section "4b"
automates all of this, but the manual steps are:

```bash
# Build dependencies
sudo dnf install meson ninja-build scdoc git \
    wayland-devel wayland-protocols-devel libxkbcommon-devel \
    cairo-devel gdk-pixbuf2-devel pango-devel pam-devel

# Clone, build, install (binary → /usr/local/bin/swaylock)
git clone https://github.com/jirutka/swaylock-effects.git ~/.local/src/swaylock-effects
cd ~/.local/src/swaylock-effects
meson setup build && ninja -C build
sudo ninja -C build install
```

> ⚠️ **Critical PAM step — skip this and you lock yourself out.**
> The fork's `meson install` writes its PAM file to `/usr/local/etc/pam.d/swaylock`,
> a directory PAM **never reads**. With no `/etc/pam.d/swaylock`, PAM falls back to
> `/etc/pam.d/other` (`pam_deny`) and **every password is silently rejected** — the
> lock screen appears, your correct password "doesn't work," and you must switch to
> a TTY to recover. Fix it once:
>
> ```bash
> printf '%s\n' '# swaylock PAM config' 'auth include login' \
>     | sudo tee /etc/pam.d/swaylock
> ```
>
> Verify with `ls -l /etc/pam.d/swaylock` before relying on the lock screen.

Brand palette config at `~/.config/swaylock/config` (managed by `swaylock/` stow module).
Colors: navy-ink background, brand-teal ring, brand-sky key-highlight, brand-cream text.
Effects: `effect-blur=7x5`, `effect-vignette=0.5:0.5`, `fade-in=0.2`.

### mpv (OLED screensaver — manual launch only)

```bash
sudo dnf install mpv
```

`scripts/.local/bin/oled-screensaver` renders a moving brand clock via mpv + FFmpeg lavfi.
**Not part of the idle chain** (mpv captures Wayland input, preventing swayidle resume).
Launch manually from a terminal when you want the visual. Exit with Ctrl+C.

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
sudo dnf install yazi Thunar fzf wl-clipboard wtype bottom
```

- `yazi` — Rust TUI file manager (primary, alias: `y`)
- `thunar` — GUI file manager (`Mod+F`)
- `bottom` — system monitor (`Alt+M`)
- `wl-clipboard` — Wayland clipboard (`wl-copy`/`wl-paste`)
- `wtype` — Wayland virtual keyboard input for text-replacement hotkeys

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
# install.sh handles this automatically via:
curl -fsSL https://claude.ai/install.sh | bash
# Installs to ~/.local/share/claude/versions/<ver>, symlinked at ~/.local/bin/claude
#
# Plugins (installed automatically by install.sh after Claude Code):
#   claude plugin install remember@claude-plugins-official
#   claude plugin install superpowers@claude-plugins-official

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
