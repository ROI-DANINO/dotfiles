# Design Spec — SDDM Sugar Candy Brand Migration

**Date:** 2026-06-10
**Status:** Approved
**Topic:** Replace Ly with SDDM + Sugar Candy theme for a modern graphical login mirroring the user's `hyprlock` screen, with Niri set as the default session.

## Goal
Migrate to `SDDM` with the `Sugar Candy` theme. The login screen must mimic the `hyprlock` "fire" aesthetic using OLED gradients, JetBrains Mono clock, and the official brand palette (Navy, Cream, Teal). Niri must be pre-selected as the default Wayland session. No autologin (password required).

## Context
- **Current Setup:** `ly@tty1.service` is disabled, `sddm.service` enabled but currently configured for `chili` which the user disliked.
- **Target Setup:** `sddm.service` + `sddm-sugar-candy` theme.
- **Brand Palette & Lockscreen aesthetic:**
  - Background: An OLED gradient from `~/.config/hypr/backgrounds/`.
  - Clock/Text: `brand-cream` (#F0E7D5), JetBrains Mono.
  - Accents/Borders: `brand-teal` (#567C8D).
  - Base Panel: Translucent `brand-navy` (#2F4156).
- **Environment:** Fedora 43, Niri compositor (Wayland).

## Proposed Changes

### 1. Theme Installation
- Remove the `chili` theme to clean up.
- Install the `sddm-sugar-candy` theme from its repository to `/usr/share/sddm/themes/sugar-candy`.

### 2. Configuration (`/etc/sddm.conf.d/`)
- **`branding.conf`**: Set `Current=sugar-candy`.
- **`default-session.conf`**: Set Niri as the default session so the user doesn't have to select it.
  ```ini
  [Autologin]
  Session=niri.desktop
  ```

### 3. Theme Customization (`theme.conf`)
Modify `sugar-candy/theme.conf` to mirror the lockscreen:
- `Background`: Set to an OLED gradient from `~/.config/hypr/backgrounds/` (e.g., `radial.png` or `aurora.png`).
- `Font`: `"JetBrainsMono Nerd Font"` or `"JetBrains Mono"`.
- `MainColor`: `#F0E7D5` (Cream for text).
- `AccentColor`: `#567C8D` (Teal for borders/focus).
- `BackgroundColor`: `#2F4156` (Navy for the translucent overlay).

### 4. Repository Updates
- **`install.sh`**:
    - Update the SDDM section (§4c) to clone `sugar-candy` instead of `chili`.
    - Apply the QML/`theme.conf` patches for Sugar Candy.
    - Write `/etc/sddm.conf.d/default-session.conf`.
- **`packages.md`**:
    - Update references from Chili to Sugar Candy.
- **`docs/agent-reference/package-safety-history.md`**:
    - Record the pivot from Chili to Sugar Candy to achieve the lockscreen aesthetic.

## Success Criteria
1. **Boot flow:** The system boots into the SDDM Sugar Candy login screen.
2. **Visuals:** Looks like the `hyprlock` screen (OLED gradient background, large JetBrains Mono clock, Teal accents).
3. **Session:** Niri is pre-selected by default.
4. **Authentication:** Password is required (no autologin).

## Reversion Plan
To return to Ly:
1. `sudo systemctl disable sddm`
2. `sudo systemctl enable ly@tty1`
3. Restore `install.sh` to the Ly version.