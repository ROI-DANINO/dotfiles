# Design Spec — SDDM Chili Brand Migration

**Date:** 2026-06-10
**Status:** Approved
**Topic:** Replace Ly/greetd with SDDM + Chili theme for a modern, brand-themed graphical login experience.

## Goal
Migrate the system's display manager from `ly` to `SDDM` with the `Chili` minimalist theme. The login screen must use the official brand palette (Navy, Cream, Teal) and require a password (no autologin).

## Context
- **Current Setup:** `ly@tty1.service` (TUI login manager).
- **Target Setup:** `sddm.service` + `chili` theme.
- **Brand Palette:**
  - Background: `brand-navy` (#2F4156)
  - Text/Foreground: `brand-cream` (#F0E7D5)
  - Accent/Selection: `brand-teal` (#567C8D)
- **Environment:** Fedora 43, Niri compositor (Wayland).

## Proposed Changes

### 1. Installation & Service Management
- Install the `sddm` package: `sudo dnf install sddm`.
- Install the `sddm-chili` theme from GitHub (since it's not in Fedora repos):
  - Clone to `/usr/share/sddm/themes/chili`.
- Disable `ly@tty1.service` and `greetd.service`.
- Enable `sddm.service`.

### 2. Configuration

#### SDDM Global Config (`/etc/sddm.conf.d/branding.conf`)
```ini
[Theme]
Current=chili
```

#### Chili Theme Config (`/usr/share/sddm/themes/chili/theme.conf`)
Modify settings to match the brand palette:
- `background = #2F4156` (Brand Navy)
- `color = #F0E7D5` (Brand Cream)
- `selectionColor = #567C8D` (Brand Teal)
- `font = "JetBrains Mono"` (Matches the rest of the desktop)

### 3. Repository Updates
- **`install.sh`**:
    - Section §4c: Replace `ly` logic with `sddm` + `chili` setup.
    - Set `WANT_AUTOLOGIN=false` behavior by default.
- **`packages.md`**:
    - Replace the `Ly` section with `SDDM`.
- **`docs/agent-reference/package-safety-history.md`**:
    - Record the move from `ly` to `SDDM` and the rationale (preference for graphical "face" and branding).

## Success Criteria
1. **Boot flow:** The system boots into the graphical SDDM Chili login screen.
2. **Visuals:** The screen uses Navy background and Cream text.
3. **Authentication:** The user must enter a password to log in.
4. **Session:** Successful login launches the Niri Wayland session.

## Reversion Plan
To return to Ly:
1. `sudo systemctl disable sddm`
2. `sudo systemctl enable ly@tty1`
3. Restore `install.sh` to the previous version.
