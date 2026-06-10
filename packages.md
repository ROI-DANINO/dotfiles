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
Note: the screen locker is **hyprlock** (from a COPR, not in default repos). See the hyprlock section below.

### TTY1 autologin — no display manager (optional)

Skips GDM entirely: a `getty@tty1` override autologs in at boot, and `shell/.zprofile`
(stowed) execs `niri-session` on TTY1. The install wizard offers this opt-in; it is
**never** enabled by `--all` or non-interactive runs, because it removes the boot
password prompt (physical access = full session) and disables GDM. hyprlock still
guards lock/idle; other TTYs and SSH are unaffected.

```bash
# install.sh wizard handles this:
sudo mkdir -p /etc/systemd/system/getty@tty1.service.d
printf '%s\n' '[Service]' 'ExecStart=' \
    'ExecStart=-/sbin/agetty --autologin <user> --noclear %I $TERM' \
    | sudo tee /etc/systemd/system/getty@tty1.service.d/autologin.conf
sudo systemctl daemon-reload
sudo systemctl disable gdm
```

To revert: `sudo rm /etc/systemd/system/getty@tty1.service.d/autologin.conf && sudo systemctl daemon-reload && sudo systemctl enable gdm`.

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
2. **600 s** → `~/.local/bin/lock-screen` — auto-lock (instant; random OLED gradient → hyprlock). Password required to unlock.
3. **resume** → `niri msg action power-on-monitors`

`Mod+Shift+K` toggles swayidle on/off. If swayidle is running, it kills it; if not, it starts the idle pipeline and immediately runs `niri msg action power-off-monitors`. `Mod+Shift+L` locks immediately via hyprlock.

### hyprlock (screen locker — modern, rotating OLED gradients)

hyprlock replaced swaylock-effects on 2026-06-04. It shows a **gradient image
as-is** (no live blur), so the lock appears **instantly**, with a large clock, a
small date, and a gradient-border password field. It is not in Fedora's repos —
it comes from the maintained **`sdegler/hyprland`** COPR. `install.sh` section
"4b" automates this; the manual steps are:

```bash
sudo dnf copr enable sdegler/hyprland
sudo dnf install hyprlock
```

This pulls a few small Hyprland support libs (`hyprlang`, `hyprutils`,
`hyprgraphics`). Lightweight at runtime; GPU-rendered.

> ⚠️ **Critical PAM step — skip this and you lock yourself out.**
> With no `/etc/pam.d/hyprlock`, PAM falls back to `/etc/pam.d/other` (`pam_deny`)
> and **every password is silently rejected** — the lock screen appears, your
> correct password "doesn't work," and you must switch to a TTY to recover. Fix it
> once:
>
> ```bash
> printf '%s\n' '# hyprlock PAM config' 'auth include login' \
>     | sudo tee /etc/pam.d/hyprlock
> ```
>
> Verify with `ls -l /etc/pam.d/hyprlock` before relying on the lock screen.

Config at `~/.config/hypr/hyprlock.conf` (managed by the `hyprlock/` stow module).

**Rotating background:** `~/.local/bin/lock-screen` (the wrapper all lock triggers
call) picks a random gradient from `~/.config/hypr/backgrounds/` on each lock and
symlinks `~/.cache/hyprlock/bg.png` to it; `hyprlock.conf` points its `background`
at that symlink. Add/remove gradients in the `hyprlock/.config/hypr/backgrounds/`
stow dir to change the rotation. Three ship by default (radial / aurora / horizon),
generated with ImageMagick and tuned for OLED (true-black regions = pixels off).
hyprlock can't animate the background natively, so rotation is per-lock.

Brand palette: cream clock/date with shadow; password field with a steel→teal
gradient border, navy fill, gold (verifying) / terracotta (fail) states.

Previous locker (swaylock-effects, built from source) is archived at
`archived/swaylock/`; its leftover binary at `/usr/local/bin/swaylock` is harmless
and removable (`sudo rm /usr/local/bin/swaylock /etc/pam.d/swaylock`).

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
sudo dnf install yazi Thunar fzf wl-clipboard wtype bottom wf-recorder
```

- `yazi` — Rust TUI file manager (primary, alias: `y`)
- `thunar` — GUI file manager (`Mod+F`)
- `bottom` — system monitor (`Alt+M`)
- `wl-clipboard` — Wayland clipboard (`wl-copy`/`wl-paste`)
- `wtype` — Wayland virtual keyboard input for text-replacement hotkeys
- `wf-recorder` — Wayland screen recorder (alias: `record`)

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
