# Niri Keybinds

Read this before changing any Niri bind. Preserve both arrow and hjkl bindings.

## Philosophy

- **Lean setup** — fewer tools that do one thing well; avoid feature-heavy alternatives
- **Rust-based tools preferred** where available and stable (yazi, zellij, swww, bottom)
- **Consistent keybinds** across tools (hjkl movement in zellij, niri, future editor)
- **Vim motions as a learning goal** — not enforced everywhere, preferred where natural
- **Portable** — configs should work on any fresh Fedora machine after `bash install.sh`

---

## Niri Keybind Map

> Changes to binds require updating this table. Check it before adding new binds.

**Mod = Super key**

| Bind | Action | Status |
|------|--------|--------|
| `Mod+T` | spawn kitty | locked |
| `Mod+W` | spawn default browser (Zen) | ✓ |
| `Mod+F` | spawn thunar | ✓ |
| `Mod+Slash` | spawn walker (launcher) | locked |
| `Mod+Q` | close window | ✓ |
| `Mod+Shift+L` | hyprlock (modern lock screen) | locked |
| `Mod+H/L` | focus column left/right | ✓ |
| `Mod+J/K` | focus window down/up | ✓ |
| `Mod+Left/Right/Up/Down` | focus (arrow aliases) | ✓ |
| `Mod+Shift+H` | move column left | ✓ |
| `Mod+Shift+J` | move window down | ✓ |
| `Mod+Shift+K` | spawn toggle-idle (screen blank toggle) | ✓ |
| `Mod+Shift+Right` | move column right | ✓ (Shift+L reserved for lock) |
| `Mod+Shift+B` | spawn toggle-bar (waybar ↔ sysbar) | ✓ |
| `Mod+Shift+C` | spawn claude-desktop | ✓ |
| `Mod+G` | fix selected Hebrew/English wrong-layout text | ✓ |
| `Mod+U/I` | focus workspace up/down | ✓ |
| `Mod+Ctrl+U/I` | move column to workspace up/down | ✓ |
| `Mod+R` | cycle column width | ✓ |
| `Mod+M` | maximize column | ✓ |
| `Mod+Shift+F` | fullscreen | ✓ |
| `Mod+C` | center column | ✓ |
| `Mod+Comma/Period` | consume/expel window from column | ✓ |
| `Mod+Minus/Equal` | resize column width | ✓ |
| `Mod+1-9` | focus workspace N | ✓ |
| `Mod+Shift+1-9` | move column to workspace N | ✓ |
| `Mod+Tab` | previous workspace | ✓ |
| `Mod+Shift+E` | quit niri | ✓ |
| `Mod+Shift+P` | power off monitors | ✓ |
| `Ctrl+Space` / `Print` | screenshot | ✓ |
| `Alt+M` | spawn bottom (system monitor) | ✓ |

### Free / available Mod binds
`Mod+A`, `Mod+B`, `Mod+E`, `Mod+N`, `Mod+O`, `Mod+P`, `Mod+S`, `Mod+V`, `Mod+X`, `Mod+Y`, `Mod+Z`

---

## Startup Apps (niri spawn-at-startup)

| App | Purpose | Managed by |
|-----|---------|------------|
| waybar | status bar | niri direct spawn |
| dunst | notification daemon | niri direct spawn |
| walker | app launcher (`--gapplication-service` mode) | niri direct spawn |
| wob-daemon | volume/brightness OSD via FIFO | niri direct spawn |
| nm-applet | network tray applet (`--indicator`) | niri direct spawn |
| blueman-applet | bluetooth tray applet | niri direct spawn |
| wallpaper-rotate | swww wallpaper rotation (10 min cycle) | niri direct spawn |
| swayidle | idle: blank at 300s, auto-lock at 600s | niri direct spawn |
| elephant | walker data-provider backend | systemd user service (not in spawn-at-startup) |

---

## Locked / Do Not Change

- `shell/zshrc` plugins: only `zsh-autosuggestions` + `zsh-syntax-highlighting` (autocomplete intentionally removed)
- `Mod+Slash` → walker
- `Mod+T` → kitty (default terminal)
- `Mod+Space` → keyboard language toggle (us/Hebrew via xkb — **do NOT bind in niri**)
- zellij `copy_command "wl-copy"` — Wayland clipboard, required for copy-on-select
- `system/` configs are manual-only — never add to install.sh or stow.sh
- `alias claude='claude --dangerously-skip-permissions'` — intentional; this is a personal machine with no multi-user exposure. Do not remove or suggest removing.
