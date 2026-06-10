# Design Spec — Ly Login Manager Migration

**Date:** 2026-06-10
**Status:** Approved
**Topic:** Replace greetd/tuigreet with Ly for a lightweight, username-remembering TUI login experience.

## Goal

Migrate the system's display manager from `greetd` to `Ly`. The user wants a fast, lightweight login screen that remembers the username upon logout, but maintains an autologin-to-desktop flow on initial boot.

## Context

- **Current Setup:** `greetd` + `tuigreet` (configured for autologin via `initial_session`).
- **Target Setup:** `ly` (configured for autologin and username/session saving).
- **Environment:** Fedora 43, Niri compositor.

## Proposed Changes

### 1. Installation & Service Management
- Install the `ly` package: `sudo dnf install ly`.
- Disable the current display manager: `sudo systemctl disable greetd`.
- Enable Ly: `sudo systemctl enable ly`.
- Ensure `gdm` remains disabled (emergency fallback only).

### 2. Configuration (`/etc/ly/config.ini`)
The following key settings will be applied:
- `auto_login_user = roking`: Enable initial boot autologin.
- `auto_login_session = niri`: Boot straight into the Niri Wayland session.
- `save = true`: Remember the username and last session after a manual logout.
- `animate = true`: Enable the classic TUI fire animation for visual polish.

### 3. Repository Updates
- **`install.sh`**:
    - Remove the `greetd` + `tuigreet` logic from section §4c.
    - Add logic to install `ly`, write `/etc/ly/config.ini`, and enable the service.
- **`packages.md`**:
    - Replace the `greetd` section with `ly`.
- **`README.md`**:
    - Update the "Login" section to describe the Ly behavior and config.
- **`docs/agent-reference/package-safety-history.md`**:
    - Record the switch from `greetd` to `ly` and the rationale (user preference for UI/memory).

## Success Criteria

1.  **Boot flow:** The system boots directly into the Niri session without a password prompt.
2.  **Logout flow:** Logging out of Niri drops the user into the Ly TUI, with the username `roking` pre-filled.
3.  **Visuals:** The Ly fire animation is visible on the login screen.
4.  **Idempotency:** Running `install.sh` correctly sets up or restores the Ly configuration.

## Reversion Plan

To return to `greetd`:
1. `sudo systemctl disable ly`
2. `sudo systemctl enable greetd`
3. Re-run `install.sh` (once reverted in the repo).
