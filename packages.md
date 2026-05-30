# Packages — Fresh Machine Setup

Reference list for what `install.sh` installs. Run `install.sh` instead of doing this manually — it's idempotent and handles everything below.

```bash
git clone https://github.com/ROI-DANINO/dotfiles ~/dotfiles
bash ~/dotfiles/install.sh
```

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
sudo dnf install kitty alacritty
```

## Multiplexer (Rust)

```bash
# via cargo (install.sh handles this):
cargo install --locked zellij
```

## Window Manager — Niri session

```bash
sudo dnf install niri waybar SwayNotificationCenter swaylock swayidle wob mako walker elephant
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

## Notifications

```bash
sudo dnf install mako  # lightweight — used alongside swaync
```

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

## Display & Input Controls

```bash
sudo dnf install brightnessctl playerctl light
```

## File Management & CLI Tools

```bash
sudo dnf install yazi thunar fzf wl-clipboard bottom
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

Used by: kitty, alacritty, zellij, waybar.

## AI Tools

```bash
# Claude Code
npm install -g @anthropic-ai/claude-code

# opencode: https://opencode.ai
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
