# Ly Login Manager Migration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Migrate the system's display manager from `greetd` to `Ly`, supporting autologin to Niri on boot and username/session memory on logout.

**Architecture:** Replace the `greetd` systemd service with `ly`, configuring `/etc/ly/config.ini` for the desired autologin and TUI behavior.

**Tech Stack:** Fedora (dnf), systemd, Ly (TUI display manager).

---

### Task 1: Install Ly and Initial Configuration

**Files:**
- Create: `/etc/ly/config.ini` (managed via `write_file` or `run_shell_command` with `sudo tee`)
- Modify: N/A

- [ ] **Step 1: Install the `ly` package**

Run: `sudo dnf install -y ly`

- [ ] **Step 2: Verify `ly` configuration directory exists**

Run: `ls -d /etc/ly/`
Expected: Directory exists.

- [ ] **Step 3: Write the specialized `ly` configuration**

```ini
# /etc/ly/config.ini
[config]
# The username to log in automatically
auto_login_user = roking

# The session to launch (check /usr/share/wayland-sessions/ for names)
auto_login_session = niri

# Save the current desktop and login as defaults
save = true

# Use the PSX Doom fire animation
animate = true

# Big clock
bigclock = true

# Use standard TTY PAM service
service = ly
```

Command:
```bash
sudo tee /etc/ly/config.ini << 'EOF'
[config]
auto_login_user = roking
auto_login_session = niri
save = true
animate = true
bigclock = true
service = ly
EOF
```

- [ ] **Step 4: Commit the configuration intent (note: /etc files are not in repo)**

```bash
git commit --allow-empty -m "chore(login): prepare Ly configuration"
```

### Task 2: Update install.sh

**Files:**
- Modify: `install.sh`

- [ ] **Step 1: Replace greetd logic with Ly logic in §4c**

Old Code (Approx line 189):
```bash
hdr "4c · Login — greetd autologin into niri, tuigreet fallback"
... (greetd logic) ...
```

New Code:
```bash
hdr "4c · Login — Ly TUI login manager (autologin into niri)"
# Ly boots straight into niri (auto_login_user — no password prompt).
# If niri ever exits, Ly appears with username memory and fire animation.
LY_CONF="/etc/ly/config.ini"
if ! $WANT_AUTOLOGIN; then
    info "Ly login — skipped (opt-in, wizard only)"
else
    dnf_install ly
    info "Writing $LY_CONF (sudo)"
    $DRY || sudo tee "$LY_CONF" >/dev/null <<EOF
[config]
auto_login_user = $USER
auto_login_session = niri
save = true
animate = true
bigclock = true
service = ly
EOF
    ok "Ly config"

    if systemctl is-enabled --quiet ly 2>/dev/null; then
        ok "Ly (already enabled)"
    else
        info "Enabling Ly (takes effect next boot)"
        $DRY || sudo systemctl enable ly
        ok "Ly enabled"
    fi
    if systemctl is-enabled --quiet greetd 2>/dev/null; then
        info "Disabling greetd (Ly is the display manager now)"
        $DRY || sudo systemctl disable greetd
        ok "greetd disabled"
    fi
    if systemctl is-enabled --quiet gdm 2>/dev/null; then
        info "Ensuring GDM is disabled"
        $DRY || sudo systemctl disable gdm
        ok "GDM disabled"
    fi
fi
```

- [ ] **Step 2: Commit changes**

```bash
git add install.sh
git commit -m "feat(install): migrate login manager from greetd to ly"
```

### Task 3: Update Documentation

**Files:**
- Modify: `packages.md`
- Modify: `README.md`
- Modify: `docs/agent-reference/package-safety-history.md`

- [ ] **Step 1: Update `packages.md`**

Replace `greetd + tuigreet` section with:
```markdown
### Ly TUI login manager (optional, replaces greetd/GDM)

Ly boots straight into niri via `auto_login_user` (no password prompt). When niri exits, Ly appears — a polished TUI with username memory and a fire animation.

```bash
# install.sh wizard handles this:
sudo dnf install ly
sudo tee /etc/ly/config.ini << 'EOF'
[config]
auto_login_user = <user>
auto_login_session = niri
save = true
animate = true
service = ly
EOF
sudo systemctl enable ly
sudo systemctl disable greetd
```
```

- [ ] **Step 2: Update `README.md`**

Update §4c description and the "Login" section.

- [ ] **Step 3: Update `docs/agent-reference/package-safety-history.md`**

Add entry:
```markdown
| 2026-06-10 | greetd / tuigreet | Replaced with Ly | User preference for TUI aesthetics and robust username memory on logout. |
```

- [ ] **Step 4: Commit documentation updates**

```bash
git add packages.md README.md docs/agent-reference/package-safety-history.md
git commit -m "docs: update login manager references to Ly"
```

### Task 4: Final Switch (Live System)

**Files:**
- N/A

- [ ] **Step 1: Disable greetd and enable Ly**

Run: `sudo systemctl disable greetd && sudo systemctl enable ly`

- [ ] **Step 2: Verify services**

Run: `systemctl is-enabled ly && systemctl is-enabled greetd`
Expected: `enabled` for ly, `disabled` for greetd.

- [ ] **Step 3: Final instruction to user**

"Ready to reboot. Please confirm if you'd like to reboot now to verify the change."
