# Operational Protocols

## Critical Rules

- **Never change a keybind without checking the map below first** — conflicts are easy to introduce
- **Never remove a bind without confirming it's truly unused** — some are intentionally kept
- **Never automate system/ configs** — they are manual-only reference, not touched by install.sh or stow.sh
- **Ask before adding new components to stow.sh** — owner decides what gets symlinked
- **Preserve both arrows AND hjkl** in niri — both are used, not vim-only
- **All configs are symlinked** from ~/dotfiles via GNU Stow — editing the repo file = editing the live config

---

## **Operational Protocols & Constraints**

> These constraints are non-negotiable. They exist because of prior incidents or hard environmental limits. Follow them exactly — do not work around them.

---

### **PROTOCOL 1 — Sudo Handoff (MANDATORY)**

**AI agents MUST NOT run interactive `sudo` commands in this environment.**

The correct procedure when elevated privileges are required:

1. **Output the exact command(s)** as a ready-to-copy code block:
   ```
   sudo systemctl enable --now tlp
   sudo tlp setcharge 0 85 BAT0
   ```
2. **Stop and wait.** Do not proceed until the user replies **"Done"** (or equivalent confirmation).
3. **Never** attempt to run `sudo` directly, chain it with `expect`, pipe it a password, or bypass it with `--no-verify` or similar flags.

**Scope:** Any command requiring root — `sudo dnf`, `sudo systemctl`, `sudo tlp`, edits to `/etc/`, writes to `/sys/`, `chsh`, `visudo`, and any other elevated operation.

**Why this exists:** The AI shell environment cannot authenticate interactively. Silent failures or partial-privileged state are worse than a clean pause.

---

### **PROTOCOL 2 — Live Symlink Awareness**

All configs in `~/dotfiles` are **symlinked into the live system** via GNU Stow. Editing a file in this repo edits the running config immediately.

- **Do not edit config files as experiments.** If you are unsure about a change, describe it first and ask for confirmation before applying it.
- Changes to niri config take effect on next `niri msg action reload-config` or session restart.
- Changes to shell files (`.zshrc`, `.shell_env`, `.shell_aliases`) take effect on next `source ~/.zshrc`.

---

### **PROTOCOL 3 — Stow Conflict Check**

Before running `stow.sh` or `install.sh`, check for existing non-stow-managed files at symlink targets. Conflicting real files cause stow to abort mid-deploy.

```bash
./stow.sh --dry-run   # inspect before applying
```

---

### **PROTOCOL 4 — Secrets Architecture**

The following pattern is in use. Do not suggest alternatives that put secrets in tracked files.

| Location | Purpose | Tracked? |
|----------|---------|----------|
| `~/.secrets` | Global API keys, tokens (chmod 600) | No — gitignored |
| `~/.gitconfig.local` | Git identity (name, email, signingkey) | No — gitignored |
| `.env` (per-project) | Project-specific secrets | No — gitignored |
| `.env.template` | Template showing required env var names | Yes |

**`~/.shell_env`** sources `~/.secrets` automatically if the file exists. No secrets belong in any file under `~/dotfiles/`.

If you find a hardcoded secret, token, or personally identifying value in any tracked file:
1. Note it explicitly before making any other change.
2. Propose moving it to the appropriate untracked location above.
3. Do not commit the file until the secret is removed.

---

### **PROTOCOL 5 — Package Removal Safety (MANDATORY)**

**Never give `sudo dnf remove` commands without dry-running first.**

DNF silently pulls dependent packages that may be in active use. This has already caused real breakage (Thunar removed as a dep of xfce4-panel, zenity removed by autoremove — both actively used in this setup).

The correct procedure for any package removal:

1. **Dry-run first.** Output this command and wait for the user to report what DNF says it will remove:
   ```bash
   sudo dnf remove --assumeno <packages>
   ```
2. **Read the full "Removing:" list.** Cross-check every package against `install.sh`, the keybind map, and the startup chain before proceeding.
3. **Only then** output the real `sudo dnf remove -y` command.
4. **Treat `autoremove` the same way** — always `--assumeno` first, read the list, confirm nothing used is in it.

**Known gotchas on this system:**
- `Thunar` (capital T) — GUI file manager, `Mod+F` keybind, in `install.sh`. Shares XFCE libs but is NOT an XFCE-only tool.
- `zenity` — used by scripts; pulled out by autoremove.
- `swayidle`, `swaybg` — Sway utilities actively used by the niri session. Do NOT remove with Sway WM.
- `swaync` — archived/replaced by `dunst`; do not re-add without removing `dunst` first because notification daemons conflict on `org.freedesktop.Notifications`.
- `hyprlock` — screen locker, from the `sdegler/hyprland` COPR (not in default Fedora repos). Requires `/etc/pam.d/hyprlock` to exist or all unlocks are denied. Config: `hyprlock/` stow module → `~/.config/hypr/hyprlock.conf`. See packages.md and install.sh §4b. Pulls `hypr*` support libs (hyprlang/hyprutils/hyprgraphics) — do not autoremove them.
- `swaylock` — DECOMMISSIONED 2026-06-04 (replaced by hyprlock). The source-built binary may still linger at `/usr/local/bin/swaylock`; harmless, removable. Module archived at `archived/swaylock/`.
- `gnome-keyring`, `gnome-keyring-pam` — used system-wide, not GNOME-specific.

**Why this exists:** 2026-05-30 incident — removing XFCE packages silently took Thunar; autoremove took zenity. Both required manual reinstall.
