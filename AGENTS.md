# AGENTS.md — LLM Context for dotfiles

This file is for AI assistants editing this repo. Read it before making any changes.
Owner: Roi Danino. Primary machine: Fedora 43, niri compositor, COSMIC DE.

---

## Rules

- **Never change a keybind without checking the map below first** — conflicts are easy to introduce
- **Never remove a bind without confirming it's truly unused** — some are intentionally kept
- **Never automate system/ configs** — they are manual-only reference, not touched by setup.sh
- **Ask before adding new components to setup.sh** — the owner decides what gets symlinked
- **Preserve both arrows AND hjkl** in niri — the owner uses both, not vim-only
- **All configs are symlinked** from ~/dotfiles — editing the repo file = editing the live config

---

## Philosophy

- **Lean setup** — prefer fewer tools that do one thing well over feature-heavy alternatives
- **Rust-based tools preferred** where available and stable
- **Consistent keybinds** across tools (hjkl in zellij, niri, future editor)
- **Vim motions as a learning goal** — not enforced everywhere, but preferred where natural
- **Portable** — configs should work on any fresh Fedora machine after running setup.sh

---

## Niri keybind map

> 🚧 Niri config is IN PROGRESS. Binds below are current state, not final.

### Mod = Super key

| Bind | Action | Status |
|------|--------|--------|
| `Mod+T` | spawn kitty | ✓ locked |
| `Mod+A` | spawn alacritty | ✓ locked |
| `Mod+W` | spawn default browser (currently zen) | ✓ |
| `Mod+F` | spawn cosmic-files | ✓ |
| `Mod+Slash` | spawn walker (launcher) | ✓ locked |
| `Mod+Q` | close window | ✓ |
| `Mod+Shift+L` | hyprlock (lock screen) | 🚧 hyprlock not yet installed |
| `Mod+Shift+S` | suspend | 🚧 in progress |
| `Mod+Shift+X` | lock + suspend | 🚧 in progress |
| `Mod+H/L` | focus column left/right | ✓ |
| `Mod+J/K` | focus window down/up | ✓ |
| `Mod+Left/Right/Up/Down` | focus (arrow aliases) | ✓ |
| `Mod+Shift+H` | move column left | ✓ |
| `Mod+Shift+J` | move window down | ✓ |
| `Mod+Shift+K` | move window up | ✓ |
| `Mod+Shift+Right` | move column right | ✓ (Mod+Shift+L removed — reserved for lock) |
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
| `Alt+M` | spawn btm (system monitor) | ✓ |

### Free / available Mod binds
`Mod+B`, `Mod+E`, `Mod+G`, `Mod+N`, `Mod+O`, `Mod+P`, `Mod+S`, `Mod+V`, `Mod+X`, `Mod+Y`, `Mod+Z`

---

## Startup apps (niri spawn-at-startup)

| App | Purpose | Status |
|-----|---------|--------|
| waybar | status bar | 🚧 layout undecided |
| swaync | notifications | ✓ using defaults |
| walker | app launcher (powered by elephant) | ✓ |
| elephant | powers walker launcher | ✓ |

---

## In progress / undecided

| Area | What's undecided | Notes |
|------|-----------------|-------|
| hyprlock + hypridle | not yet installed | replaces swaylock; Mod+Shift+L=lock, Mod+Shift+S=sleep, Mod+Shift+X=both |
| waybar | layout, modules, style | currently functional but not finalized |
| COSMIC DE | no config yet | will add when owner starts using it |
| walker | no custom config yet | using defaults |
| swaync | no custom config yet | using defaults |

---

## Locked / do not change

- `shell/zshrc` plugins: only `zsh-autosuggestions` + `zsh-syntax-highlighting` (autocomplete was intentionally removed)
- `Mod+Slash` → walker (launcher)
- `Mod+T` → kitty (default terminal)
- `Mod+Space` → keyboard language toggle (us/Hebrew, handled by xkb — do NOT bind this in niri)
- zellij `copy_command "wl-copy"` — Wayland clipboard, required for copy-on-select to work
- system/ configs are manual-only — never add them to setup.sh automation

---

## Machine-specific notes

- Display: `eDP-1`, `2880x1800@90`, scale `2.0` (laptop HiDPI)
- Keyboard layout: `us,il` with `grp:win_space_toggle` to switch
- Java path: `/usr/lib/jvm/java-25-openjdk` (hardcoded in shell/env)
- NTP: enabled, timezone: `Asia/Jerusalem (IST, +0200)`
- npm global: `~/.npm-global/bin` (in PATH via shell/env)

---

## Repo structure

```
~/dotfiles/
├── setup.sh          # interactive symlink installer
├── packages.md       # full dnf install list for fresh machine
├── README.md         # human-facing overview
├── AGENTS.md         # this file
├── shell/            # env, aliases, zshrc, p10k.zsh
├── kitty/
├── alacritty/
├── zellij/           # config + themes/ + layouts/
├── waybar/           # config.jsonc, style.css, battery.sh
├── git/
├── niri/
└── system/           # manual-only: sysctl, zram, journald, earlyoom
```
